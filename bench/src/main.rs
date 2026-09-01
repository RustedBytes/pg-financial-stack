use std::{
    collections::{BTreeMap, BTreeSet},
    path::PathBuf,
    process::Command,
    sync::Arc,
    time::{Duration, Instant},
};

use anyhow::{Context, Result, bail};
use clap::Parser;
use hdrhistogram::Histogram;
use serde::{Deserialize, Serialize};
use tokio::sync::Barrier;
use tokio_postgres::NoTls;

const WORKLOADS: &[&str] = &[
    "ledger_transfer",
    "ledger_multi_posting",
    "ledger_idempotent_replay",
    "fx_rate_insert",
    "fx_quote_create",
    "fx_quote_execute",
    "reconcile_external_ingest",
    "reconcile_balance",
    "reconcile_exact_match",
    "risk_amount_check",
    "risk_rolling_volume",
    "risk_exposure_check",
    "full_exchange",
];

#[derive(Parser, Debug)]
struct Args {
    #[arg(
        long,
        env = "DATABASE_URL",
        default_value = "postgresql://postgres:postgres@localhost:5432/financial_stack"
    )]
    database_url: String,
    #[arg(long, default_value = "full_exchange")]
    workload: String,
    #[arg(long, default_value_t = 16)]
    clients: usize,
    #[arg(long, default_value_t = 100)]
    iterations: u64,
    #[arg(long, default_value = "bench/workloads")]
    workload_dir: PathBuf,
    #[arg(long, default_value = "stack/versions.lock")]
    lock_file: PathBuf,
}

#[derive(Deserialize)]
struct LockedStack {
    version: String,
    generated_at: String,
}

#[derive(Deserialize)]
struct LockedExtension {
    commit: String,
    pgrx: String,
}

#[derive(Deserialize)]
struct VersionLock {
    stack: LockedStack,
    #[serde(flatten)]
    extensions: BTreeMap<String, LockedExtension>,
}

#[derive(Default, Serialize)]
struct WorkerResult {
    latencies_us: Vec<u64>,
    errors: u64,
}

#[derive(Serialize)]
struct Report {
    stack_version: String,
    lock_generated_at: String,
    workload: String,
    clients: usize,
    operations: u64,
    errors: u64,
    elapsed_seconds: f64,
    throughput_per_second: f64,
    mean_us: f64,
    p50_us: u64,
    p95_us: u64,
    p99_us: u64,
    p999_us: u64,
    postgres_version: String,
    extension_versions: Vec<(String, String)>,
    extension_commits: Vec<(String, String)>,
    rust_version: String,
    pgrx_version: String,
    test_seed: String,
    cpu_threads: usize,
    memory_bytes: Option<u64>,
    database_settings: Vec<(String, String)>,
    os: String,
}

fn memory_bytes() -> Option<u64> {
    let text = std::fs::read_to_string("/proc/meminfo").ok()?;
    let kib = text
        .lines()
        .find_map(|line| line.strip_prefix("MemTotal:"))?
        .split_whitespace()
        .next()?
        .parse::<u64>()
        .ok()?;
    Some(kib * 1024)
}

async fn connect(url: &str) -> Result<tokio_postgres::Client> {
    let (client, connection) = tokio_postgres::connect(url, NoTls).await?;
    tokio::spawn(async move {
        if let Err(error) = connection.await {
            eprintln!("postgres connection: {error}");
        }
    });
    Ok(client)
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();
    if !WORKLOADS.contains(&args.workload.as_str()) {
        bail!(
            "unknown workload {}; expected one of {}",
            args.workload,
            WORKLOADS.join(", ")
        );
    }
    if args.clients == 0 || args.iterations == 0 {
        bail!("clients and iterations must be positive");
    }
    let setup = std::fs::read_to_string(args.workload_dir.join("setup.sql"))?;
    let query = std::fs::read_to_string(args.workload_dir.join(format!("{}.sql", args.workload)))
        .with_context(|| format!("unknown workload {}", args.workload))?;
    let lock: VersionLock = toml::from_str(
        &std::fs::read_to_string(&args.lock_file)
            .with_context(|| format!("cannot read {}", args.lock_file.display()))?,
    )
    .with_context(|| format!("cannot parse {}", args.lock_file.display()))?;

    let admin = connect(&args.database_url).await?;
    admin
        .batch_execute(&setup)
        .await
        .context("benchmark setup failed")?;
    let postgres_version: String = admin.query_one("SHOW server_version", &[]).await?.get(0);
    let extension_versions = admin
        .query(
            "SELECT extname, extversion FROM pg_extension WHERE extname IN \
         ('pg_money','pg_cryptocurrency','pg_fx','pg_ledger','pg_reconcile','pg_risk') ORDER BY 1",
            &[],
        )
        .await?
        .into_iter()
        .map(|row| (row.get(0), row.get(1)))
        .collect::<Vec<(String, String)>>();
    let extension_commits = extension_versions
        .iter()
        .map(|(name, _)| {
            lock.extensions
                .get(name)
                .map(|extension| (name.clone(), extension.commit.clone()))
                .with_context(|| {
                    format!("installed extension {name} is absent from the version lock")
                })
        })
        .collect::<Result<Vec<_>>>()?;
    let pgrx_versions = extension_versions
        .iter()
        .map(|(name, _)| {
            lock.extensions
                .get(name)
                .map(|extension| extension.pgrx.trim_start_matches('=').to_owned())
                .with_context(|| {
                    format!("installed extension {name} is absent from the version lock")
                })
        })
        .collect::<Result<BTreeSet<_>>>()?;
    if pgrx_versions.len() != 1 {
        bail!("version lock contains inconsistent pgrx versions: {pgrx_versions:?}");
    }
    let pgrx_version = pgrx_versions
        .into_iter()
        .next()
        .context("no pgrx version found")?;
    let database_settings = admin
        .query(
            "SELECT name, setting FROM pg_settings WHERE name IN \
             ('max_connections','shared_buffers','work_mem','synchronous_commit','jit') ORDER BY 1",
            &[],
        )
        .await?
        .into_iter()
        .map(|row| (row.get(0), row.get(1)))
        .collect();

    let barrier = Arc::new(Barrier::new(args.clients + 1));
    let mut tasks = Vec::with_capacity(args.clients);
    for _ in 0..args.clients {
        let client = connect(&args.database_url).await?;
        let barrier = barrier.clone();
        let query = query.clone();
        let iterations = args.iterations;
        tasks.push(tokio::spawn(async move {
            let mut result = WorkerResult::default();
            barrier.wait().await;
            for _ in 0..iterations {
                let started = Instant::now();
                if client.batch_execute(&query).await.is_err() {
                    result.errors += 1;
                } else {
                    result
                        .latencies_us
                        .push(started.elapsed().as_micros().max(1) as u64);
                }
            }
            result
        }));
    }
    barrier.wait().await;
    let started = Instant::now();
    let mut histogram = Histogram::<u64>::new(3)?;
    let mut errors = 0;
    for task in tasks {
        let worker = task.await?;
        errors += worker.errors;
        for latency in worker.latencies_us {
            histogram.record(latency)?;
        }
    }
    let elapsed = started.elapsed();

    // Throughput is discarded when any extension invariant reports a failure.
    for validation in [
        "ledger_validate()",
        "reconcile_validate()",
        "risk_validate()",
    ] {
        let query = format!("SELECT count(*) FROM {validation} WHERE status <> 'OK'");
        let violations: i64 = admin.query_one(&query, &[]).await?.get(0);
        if violations != 0 {
            bail!("benchmark state is invalid: {validation} has {violations} failing checks");
        }
    }
    let operations = histogram.len();
    let elapsed_seconds = elapsed
        .as_secs_f64()
        .max(Duration::from_nanos(1).as_secs_f64());
    let report = Report {
        stack_version: lock.stack.version,
        lock_generated_at: lock.stack.generated_at,
        workload: args.workload,
        clients: args.clients,
        operations,
        errors,
        elapsed_seconds,
        throughput_per_second: operations as f64 / elapsed_seconds,
        mean_us: histogram.mean(),
        p50_us: histogram.value_at_quantile(0.50),
        p95_us: histogram.value_at_quantile(0.95),
        p99_us: histogram.value_at_quantile(0.99),
        p999_us: histogram.value_at_quantile(0.999),
        postgres_version,
        extension_versions,
        extension_commits,
        rust_version: Command::new("rustc")
            .arg("--version")
            .output()
            .ok()
            .filter(|output| output.status.success())
            .map(|output| String::from_utf8_lossy(&output.stdout).trim().to_owned())
            .unwrap_or_else(|| "rust >=1.96".to_owned()),
        pgrx_version,
        test_seed: std::env::var("PG_STACK_SEED").unwrap_or_else(|_| "20260901".to_owned()),
        cpu_threads: std::thread::available_parallelism()
            .map(usize::from)
            .unwrap_or(1),
        memory_bytes: memory_bytes(),
        database_settings,
        os: std::env::consts::OS.to_owned(),
    };
    println!("{}", serde_json::to_string_pretty(&report)?);
    if errors > 0 {
        bail!("{errors} benchmark operations failed");
    }
    Ok(())
}
