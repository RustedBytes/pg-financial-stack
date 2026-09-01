# Technical Specification: `pg-financial-stack`

## 1. Purpose

`pg-financial-stack` is an integration, validation, compatibility, and benchmarking repository for the complete RustedBytes PostgreSQL financial extension ecosystem.

The repository does not implement financial business logic itself.

Its purpose is to prove that all extensions:

* install successfully together;
* work across supported PostgreSQL versions;
* remain interoperable regardless of supported installation order;
* preserve their documented invariants;
* behave correctly under concurrency;
* upgrade safely;
* remain secure under expected role separation;
* produce correct results in realistic end-to-end exchange workflows;
* maintain acceptable performance under load.

Target extensions:

```text
pg_money
pg_cryptocurrency
pg_fx
pg_ledger
pg_reconcile
pg_risk
```

Future extensions must be easy to add to the stack.

---

# 2. Repository

Recommended repository:

```text
RustedBytes/pg-financial-stack
```

Alternative:

```text
RustedBytes/pg-finance-stack
```

Recommended name:

```text
pg-financial-stack
```

because the repository is explicitly broader than only exchange functionality.

---

# 3. Core principle

Each individual extension remains responsible for its own:

```text
unit tests
type tests
extension-specific integration tests
benchmarks
security tests
```

`pg-financial-stack` is responsible for:

```text
cross-extension behavior
installation compatibility
full-stack correctness
cross-extension concurrency
upgrade compatibility
production-like workflows
system-level performance
```

Do not duplicate all extension-local tests.

---

# 4. Supported extensions

Initial manifest:

```yaml
extensions:
  pg_money:
    repository: https://github.com/RustedBytes/pg-money

  pg_cryptocurrency:
    repository: https://github.com/RustedBytes/pg-cryptocurrency

  pg_fx:
    repository: https://github.com/RustedBytes/pg-fx

  pg_ledger:
    repository: https://github.com/RustedBytes/pg-ledger

  pg_reconcile:
    repository: https://github.com/RustedBytes/pg-reconcile

  pg_risk:
    repository: https://github.com/RustedBytes/pg-risk
```

The repository should support:

```text
local sibling repositories
Git repositories
specific commits
specific tags/releases
```

---

# 5. Compatibility targets

Initial PostgreSQL matrix:

```text
PostgreSQL 14
PostgreSQL 15
PostgreSQL 16
PostgreSQL 17
PostgreSQL 18
```

Rust:

```text
Rust >= 1.96
```

pgrx:

```text
0.19.2
```

The stack test should fail if extensions expect incompatible pgrx or PostgreSQL versions.

---

# 6. Repository structure

Recommended layout:

```text
pg-financial-stack/
├── README.md
├── Cargo.toml
├── rust-toolchain.toml
├── justfile
├── Makefile
│
├── stack/
│   ├── extensions.toml
│   ├── compatibility.toml
│   └── versions.lock
│
├── docker/
│   ├── Dockerfile.pg14
│   ├── Dockerfile.pg15
│   ├── Dockerfile.pg16
│   ├── Dockerfile.pg17
│   ├── Dockerfile.pg18
│   └── docker-compose.yml
│
├── scripts/
│   ├── install-extension.sh
│   ├── install-stack.sh
│   ├── resolve-extensions.sh
│   ├── init-db.sh
│   ├── run-matrix.sh
│   ├── run-upgrade-tests.sh
│   ├── run-fault-tests.sh
│   └── cleanup.sh
│
├── sql/
│   ├── smoke/
│   ├── compatibility/
│   ├── workflows/
│   ├── concurrency/
│   ├── security/
│   ├── upgrades/
│   └── invariants/
│
├── tests/
│   ├── common/
│   ├── installation.rs
│   ├── interoperability.rs
│   ├── ledger.rs
│   ├── fx.rs
│   ├── reconcile.rs
│   ├── risk.rs
│   ├── concurrency.rs
│   ├── security.rs
│   ├── fault_injection.rs
│   └── workflows.rs
│
├── scenarios/
│   ├── fiat_exchange/
│   ├── crypto_exchange/
│   ├── deposits/
│   ├── withdrawals/
│   ├── reconciliation/
│   └── risk/
│
├── bench/
│   ├── Cargo.toml
│   ├── src/
│   ├── workloads/
│   ├── fixtures/
│   └── run.sh
│
├── fixtures/
│   ├── rates/
│   ├── bank/
│   ├── blockchain/
│   └── customers/
│
├── ci/
│   ├── smoke.sh
│   ├── matrix.sh
│   ├── nightly.sh
│   ├── upgrades.sh
│   └── benchmark.sh
│
└── docs/
    ├── ARCHITECTURE.md
    ├── TEST_MATRIX.md
    ├── INVARIANTS.md
    ├── SECURITY.md
    ├── BENCHMARKS.md
    ├── UPGRADES.md
    └── ADDING_EXTENSION.md
```

---

# 7. Extension manifest

Create:

```text
stack/extensions.toml
```

Example:

```toml
[stack]
pgrx_version = "0.19.2"
rust_version = "1.96"

[extensions.pg_money]
repo = "https://github.com/RustedBytes/pg-money"
branch = "master"
required = true

[extensions.pg_cryptocurrency]
repo = "https://github.com/RustedBytes/pg-cryptocurrency"
branch = "master"
required = true

[extensions.pg_fx]
repo = "https://github.com/RustedBytes/pg-fx"
branch = "main"
required = true

[extensions.pg_ledger]
repo = "https://github.com/RustedBytes/pg-ledger"
branch = "master"
required = true

[extensions.pg_reconcile]
repo = "https://github.com/RustedBytes/pg-reconcile"
branch = "main"
required = true

[extensions.pg_risk]
repo = "https://github.com/RustedBytes/pg-risk"
branch = "main"
required = true
```

Support overrides:

```bash
PG_STACK_PG_LEDGER_PATH=../pg-ledger
```

or:

```bash
PG_STACK_PG_LEDGER_REF=v0.1.1
```

---

# 8. Version lockfile

Generate:

```text
stack/versions.lock
```

Example:

```toml
[pg_money]
commit = "..."
version = "0.1.x"

[pg_cryptocurrency]
commit = "..."
version = "0.1.x"

[pg_fx]
commit = "..."
version = "0.1.0"

[pg_ledger]
commit = "..."
version = "0.1.1"

[pg_reconcile]
commit = "..."

[pg_risk]
commit = "..."
```

CI must print this manifest in test artifacts.

This makes every stack run reproducible.

---

# 9. Installation modes

Support three modes.

## 9.1 Local development

Repositories exist as siblings:

```text
workspace/
├── pg-money/
├── pg-cryptocurrency/
├── pg-fx/
├── pg-ledger/
├── pg-reconcile/
├── pg-risk/
└── pg-financial-stack/
```

Run:

```bash
just test-local pg18
```

## 9.2 Git mode

Stack repository clones the extension versions defined by the manifest.

```bash
just resolve
just test pg18
```

## 9.3 Released artifact mode

Install packaged extension artifacts rather than source builds.

This is important for release validation.

Example:

```bash
just test-release-stack pg18
```

---

# 10. Installation-order matrix

Optional adapters mean extension installation order matters.

Test supported order permutations.

At minimum:

```text
money
cryptocurrency
fx
ledger
reconcile
risk
```

and several intentionally different orders:

```text
ledger
money
cryptocurrency
fx
reconcile
risk
```

```text
fx
ledger
risk
reconcile
money
cryptocurrency
```

```text
cryptocurrency
money
ledger
reconcile
fx
risk
```

```text
risk
reconcile
ledger
fx
money
cryptocurrency
```

Testing all:

```text
6! = 720
```

permutations in every normal CI run is unnecessary.

Instead:

```text
PR CI:
    curated representative matrix

nightly:
    all 720 permutations if feasible
```

If all permutations are not officially supported, define the exact supported subset.

---

# 11. Late adapter enablement

For every optional dependency combination, test:

```text
extension A installed
extension B installed later
adapter enable function called
```

Examples:

```sql
CREATE EXTENSION pg_ledger;
CREATE EXTENSION pg_money;

SELECT ledger_enable_pg_money();
```

and:

```sql
CREATE EXTENSION pg_fx;
CREATE EXTENSION pg_cryptocurrency;

SELECT fx_enable_pg_cryptocurrency();
```

Likewise:

```text
reconcile ↔ ledger
reconcile ↔ money
reconcile ↔ cryptocurrency

risk ↔ ledger
risk ↔ fx
risk ↔ reconcile
risk ↔ money
risk ↔ cryptocurrency
```

Adapter enablement should be idempotent where documented.

---

# 12. Smoke test

The simplest test must prove:

```sql
CREATE EXTENSION pg_money;
CREATE EXTENSION pg_cryptocurrency;
CREATE EXTENSION pg_fx;
CREATE EXTENSION pg_ledger;
CREATE EXTENSION pg_reconcile;
CREATE EXTENSION pg_risk;
```

Then verify:

```sql
SELECT extname, extversion
FROM pg_extension
WHERE extname LIKE 'pg_%';
```

All extensions must load without:

```text
missing symbols
duplicate SQL objects
schema conflicts
incorrect dependencies
ABI failures
```

---

# 13. Schema-isolation tests

Test default installation and dedicated schemas.

Example:

```sql
CREATE SCHEMA finance_money;
CREATE SCHEMA finance_crypto;
CREATE SCHEMA pricing;
CREATE SCHEMA accounting;
CREATE SCHEMA reconciliation;
CREATE SCHEMA risk;

CREATE EXTENSION pg_money SCHEMA finance_money;
CREATE EXTENSION pg_cryptocurrency SCHEMA finance_crypto;
CREATE EXTENSION pg_fx SCHEMA pricing;
CREATE EXTENSION pg_ledger SCHEMA accounting;
CREATE EXTENSION pg_reconcile SCHEMA reconciliation;
CREATE EXTENSION pg_risk SCHEMA risk;
```

Then test adapters across schemas.

This is especially important because several extensions pin secure search paths.

---

# 14. Core type interoperability

Test conversions exhaustively.

## Fiat

```text
pg_money
→ pg_ledger
→ pg_reconcile
→ pg_risk
```

Example:

```sql
'USD 100'::money_with_currency
```

must preserve:

```text
currency
value
smallest-unit representation
```

## Cryptocurrency

```text
pg_cryptocurrency
→ pg_ledger
→ pg_reconcile
→ pg_risk
```

Example:

```text
USDT@ethereum
```

must never become:

```text
USDT@tron
```

---

# 15. Critical asset-identity tests

Mandatory negative tests:

```text
USDT@ethereum != USDT@tron

USDC@ethereum != USDC@solana

BTC@bitcoin != arbitrary BTC-like token
```

No adapter may accidentally normalize away network or contract identity.

---

# 16. Precision tests

Test boundary values for:

```text
USD 2 decimals
JPY 0 decimals
BTC 8 decimals
ETH 18 decimals
USDT 6 decimals
```

Reject excess precision where the source extension would reject it.

Test:

```text
very large amounts
zero
one smallest unit
negative ledger postings
maximum practical numeric values
```

No path may introduce floating point.

---

# 17. Full-stack fiat exchange scenario

Create canonical scenario:

```text
customer has:
    1000 USD

market:
    USD/EUR

customer quote:
    0.8500

fee:
    5 USD
```

Expected flow:

```text
pg_fx
    creates quote

pg_risk
    ALLOW

pg_ledger
    customer USD -1000
    liquidity USD +995
    fee USD +5
    liquidity EUR -845.75
    customer EUR +845.75

pg_fx
    quote → EXECUTED

pg_reconcile
    later confirms external balances
```

All financial mutations must commit atomically.

---

# 18. Full-stack crypto → fiat scenario

Example:

```text
customer sells:
    0.1 BTC

receives:
    USD
```

Validate:

```text
BTC asset identity
price source
quote
risk
per-asset ledger balancing
fee accounting
reconciliation metadata
```

---

# 19. Stablecoin network scenario

Mandatory scenario:

```text
customer has:
    1000 USDT@tron

quote requests:
    USDT@ethereum → USD
```

Expected:

```text
reject asset mismatch
```

No automatic ticker-only substitution.

---

# 20. Deposit scenario

Bank deposit:

```text
external bank transaction:
    +1000 USD
```

Application imports external observation.

Ledger:

```text
bank.external
customer.available
```

Then:

```text
pg_reconcile
    external transaction ↔ ledger transaction
```

Expected:

```text
EXACT
```

---

# 21. Crypto deposit scenario

Example:

```text
BTC txid
output index
amount
address
block height
```

The stack must:

```text
import external crypto transaction

credit ledger

match reconciliation by explicit blockchain reference
```

No heuristic amount-only match should win if txid-based identity exists.

---

# 22. Withdrawal lifecycle

Test:

```text
customer available
→ customer reserved
→ external withdrawal
→ settled
```

Success flow:

```text
available -100
reserved +100

external send succeeds

reserved -100
external/custody +100
```

Failure flow:

```text
reserved -100
available +100
```

Verify risk and reconciliation around both paths.

---

# 23. Risk concurrency scenario

Initial usage:

```text
40,000 UAH
```

Limit:

```text
50,000 UAH
```

Two concurrent operations:

```text
10,000 UAH
10,000 UAH
```

Expected:

```text
exactly one operation succeeds
```

The other must not pass based on a stale pre-lock risk state.

---

# 24. Ledger concurrency scenario

Create accounts:

```text
A
B
C
```

Run:

```text
A → B
B → A
A → C
C → A
```

with:

```text
1
4
16
64
128
```

workers.

Verify:

```text
no permanent deadlocks
no lost updates
balance versions remain valid
ledger_validate() passes
```

---

# 25. Quote execution race

Create one FX quote.

Attempt execution concurrently from:

```text
100 workers
```

Expected:

```text
exactly one effective execution
one ledger financial effect
one executed quote
```

All other attempts:

```text
idempotent result
or deterministic already-executed error
```

depending on API contract.

---

# 26. Quote expiration race

Race:

```text
fx_execute_quote()
```

against:

```text
fx_expire_quotes_batch()
```

Expected final states must never include:

```text
ledger money moved
+
quote expired instead of executed
```

after a successful commit.

---

# 27. Ledger idempotency race

Run identical:

```text
ledger_post(
    idempotency_key = X
)
```

from 100 concurrent sessions.

Expected:

```text
one canonical ledger transaction
```

Same key + different payload:

```text
IDEMPOTENCY_CONFLICT
```

---

# 28. External ingestion race

Insert the same:

```text
bank transaction
blockchain event
balance observation
```

concurrently through `pg_reconcile`.

Expected:

```text
one canonical external item
```

No duplicate evidence record where idempotency contract forbids duplicates.

---

# 29. Reconciliation tests

Test:

```text
exact balance
within tolerance
outside tolerance

exact transaction match
probable match
ambiguous match
unmatched external
unmatched ledger
conflict
```

Historical tests must verify reconciliation uses:

```text
ledger balance at event/as_of time
```

not current cached balance.

---

# 30. Risk/reconciliation integration

Scenario:

```text
hot wallet latest reconciliation:
    MISMATCH
```

Risk rule:

```text
withdrawals allowed only if MATCHED
```

Expected:

```text
crypto withdrawal → DENY
```

Then ingest correcting observation and reconcile.

Expected:

```text
MATCHED
```

Next withdrawal can pass if all other rules pass.

---

# 31. Reversal scenario

Original:

```text
customer -100 USD
merchant +100 USD
```

Ledger reversal:

```text
customer +100 USD
merchant -100 USD
```

Verify:

```text
ledger history remains immutable
reversal linked correctly
reconciliation understands corresponding external reversal
risk historical volume follows documented policy
```

---

# 32. Failure injection

The stack repository should deliberately inject failures.

Examples:

```text
error after risk_check
error after ledger_post before fx_execute_quote
error after fx_execute_quote before COMMIT
connection termination before COMMIT
serialization failure
deadlock retry
worker process kill
```

Verify atomicity.

Critical invariant:

```text
uncommitted operations must leave no partial financial state
```

---

# 33. PostgreSQL crash test

Nightly test only.

Workflow:

```text
BEGIN
risk_check
ledger_post
fx_execute_quote
```

Kill PostgreSQL before commit or during WAL flush in controlled test environment.

Restart.

Verify:

```text
either whole transaction exists
or none exists
```

Never partial exchange state.

---

# 34. Security test matrix

Create roles:

```text
extension_owner
exchange_app
market_data_ingestor
ledger_reader
reconcile_ingestor
reconcile_operator
risk_evaluator
risk_admin
auditor
unprivileged
```

Verify the expected permission boundaries.

Examples:

`unprivileged` must not:

```text
insert ledger entries
modify FX observations
modify quote pricing
modify reconciliation results
modify risk decisions
execute internal underscore functions
```

---

# 35. Search-path attack tests

Because several functions are `SECURITY DEFINER`, test hostile caller-controlled schemas.

Example:

```sql
CREATE SCHEMA attacker;

CREATE TABLE attacker.ledger_accounts (...);

SET search_path = attacker, public;
```

Then call public APIs.

Expected:

```text
extension functions still resolve trusted extension objects
```

No caller-controlled shadowing.

---

# 36. Direct mutation tests

Attempts must fail where the extension security contract prohibits them:

```sql
UPDATE ledger_entries ...
DELETE FROM ledger_transactions ...

UPDATE fx_quotes SET customer_rate = ...

UPDATE reconcile_balance_results ...

UPDATE risk_decisions ...
```

---

# 37. Invariant runner

Create one common stack function/script:

```bash
just validate-stack
```

It should call extension validation APIs:

```sql
SELECT * FROM ledger_validate();
SELECT * FROM reconcile_validate();
SELECT * FROM risk_validate();
```

plus stack-specific checks.

---

# 38. Stack-level invariants

Define in:

```text
docs/INVARIANTS.md
```

At minimum:

```text
all ledger transactions balance independently by asset

cached ledger balances equal entry history

immutable ledger data was not modified

crypto network identity remains preserved across all adapters

executed FX quote corresponds to no more than one ledger execution

risk-denied operation has no committed financial movement

reconciliation does not alter ledger history

manual reconciliation decisions are append-only

no risk decision silently changes historical policy version

adapter conversions preserve exact smallest units

no extension path introduces floating-point arithmetic
```

---

# 39. Stack integrity SQL

Create:

```text
sql/invariants/full_stack.sql
```

Return:

```text
check
status
violations
details
```

Example:

```text
ledger_balance                  OK       0
ledger_transaction_balance      OK       0
fx_execution_uniqueness         OK       0
asset_identity                  OK       0
reconcile_consistency           OK       0
risk_decision_consistency       OK       0
```

---

# 40. Upgrade testing

A major purpose of the repository must be upgrade safety.

For each extension:

```text
previous release
→ current release
```

Workflow:

```text
1. install old full stack
2. populate realistic data
3. snapshot expected results
4. install new extension binaries
5. ALTER EXTENSION ... UPDATE
6. rerun validation
7. compare results
```

---

# 41. Upgrade fixture dataset

Generate a stable fixture containing:

```text
100 customers

multiple currencies:
    USD
    EUR
    UAH
    JPY

crypto:
    BTC
    ETH
    USDT@ethereum
    USDT@tron

10k ledger transactions

1k FX quotes

external reconciliation history

risk decisions

reversals

idempotency records
```

Save deterministic seed.

---

# 42. Binary compatibility checks

For custom PostgreSQL base types, create golden test values.

Dump:

```text
binary COPY output
text output
comparison/hash behavior
```

before upgrade.

After upgrade, verify:

```text
old persisted values remain readable
ordering remains stable where promised
hash/equality semantics remain compatible
```

---

# 43. Dump/restore tests

Test:

```bash
pg_dump
createdb new_db
pg_restore
```

for the full extension stack.

Verify:

```text
all custom types restore
extension dependencies resolve
adapter functions restore correctly
ledger invariants pass
```

Run across same PostgreSQL major version.

Later add supported major-version migration testing.

---

# 44. `pg_upgrade` testing

Nightly/release CI should test supported major migrations:

```text
PG14 → PG15
PG15 → PG16
PG16 → PG17
PG17 → PG18
```

where extension binaries support both sides.

Verify after migration:

```text
all extensions load
data remains readable
full-stack invariants pass
```

---

# 45. Benchmark harness

Create a Rust benchmark driver using:

```text
tokio
tokio-postgres or sqlx
hdrhistogram
serde
clap
```

Avoid benchmark logic based only on shell loops.

---

# 46. Workloads

Minimum benchmark workloads:

```text
ledger_transfer
ledger_multi_posting
ledger_idempotent_replay

fx_rate_insert
fx_quote_create
fx_quote_execute

reconcile_external_ingest
reconcile_balance
reconcile_exact_match

risk_amount_check
risk_rolling_volume
risk_exposure_check

full_exchange
```

---

# 47. Concurrency levels

Run:

```text
1
4
16
32
64
128
```

clients where infrastructure permits.

Capture:

```text
throughput
mean
p50
p95
p99
p99.9
errors
retries
deadlocks
serialization failures
```

---

# 48. Benchmark correctness

Every benchmark must run validation afterwards.

Performance tests are invalid if:

```text
ledger_validate() fails
```

or another invariant fails.

Never report throughput for an incorrect state.

---

# 49. Database-growth measurements

Measure:

```text
bytes per ledger posting
bytes per transaction
bytes per quote
bytes per external transaction
bytes per risk decision
```

Use:

```sql
pg_total_relation_size(...)
```

before and after deterministic workloads.

---

# 50. Baseline storage sizes

Include scenarios:

```text
100k
1M
10M
```

rows for high-volume tables.

At minimum model:

```text
ledger_entries
ledger_transactions
fx_rates
fx_quotes
reconcile_external_transactions
risk_decisions
```

---

# 51. Performance regression thresholds

Support baseline comparison.

Example:

```toml
[thresholds.full_exchange]
max_p99_regression_percent = 15
max_throughput_regression_percent = 10
```

CI should warn or fail according to configuration.

Use stable dedicated infrastructure for hard regression gates.

---

# 52. Test runner CLI

Provide:

```bash
just test pg18
```

```bash
just test-all
```

```bash
just test-install-order pg18
```

```bash
just test-security pg18
```

```bash
just test-concurrency pg18
```

```bash
just test-upgrades pg18
```

```bash
just bench pg18
```

```bash
just nightly
```

---

# 53. Optional Rust CLI

Recommended later:

```text
pg-financial-stack-cli
```

Commands:

```bash
pg-financial-stack test

pg-financial-stack test --postgres 18

pg-financial-stack matrix

pg-financial-stack validate

pg-financial-stack bench

pg-financial-stack versions

pg-financial-stack scenario fiat-exchange
```

The CLI should primarily orchestrate PostgreSQL and tests, not reimplement extension logic.

---

# 54. Docker images

Build one container per PostgreSQL major version.

Example:

```text
ghcr.io/rustedbytes/pg-financial-stack:pg14
ghcr.io/rustedbytes/pg-financial-stack:pg15
ghcr.io/rustedbytes/pg-financial-stack:pg16
ghcr.io/rustedbytes/pg-financial-stack:pg17
ghcr.io/rustedbytes/pg-financial-stack:pg18
```

Each image should contain:

```text
PostgreSQL
Rust toolchain where source builds are needed
pgrx
extension artifacts
test runner
```

---

# 55. Docker Compose

Provide a simple local environment:

```bash
docker compose up postgres
```

and:

```bash
just install-local-stack
```

Optional services later:

```text
Prometheus
Grafana
```

for performance experiments, but they are not required for v0.1.

---

# 56. GitHub Actions

Recommended workflows:

```text
ci.yml
nightly.yml
release-validation.yml
upgrade.yml
benchmark.yml
```

---

# 57. Pull-request CI

Keep PR validation reasonably fast.

Run:

```text
PostgreSQL 18:
    full test suite

PostgreSQL 14:
    smoke + compatibility

PostgreSQL 16:
    smoke + selected workflows
```

Run:

```text
representative installation orders
security tests
basic concurrency tests
full-stack fiat workflow
crypto identity workflow
```

---

# 58. Main-branch CI

Run all:

```text
PG14
PG15
PG16
PG17
PG18
```

with full functionality tests.

---

# 59. Nightly CI

Nightly should include:

```text
large concurrency tests

installation-order exhaustive/expanded matrix

fault injection

long-running ledger workload

reconciliation stress

risk race tests

pg_dump/restore

pg_upgrade

large dataset benchmarks
```

---

# 60. Release validation

Before releasing any extension, stack CI should support:

```text
candidate extension branch/tag
+
latest released versions of every companion
```

Example:

```text
pg_ledger candidate 0.2.0

against:
pg_money latest
pg_cryptocurrency latest
pg_fx latest
pg_reconcile latest
pg_risk latest
```

Then reverse:

```text
latest pg_ledger
+
candidate pg_fx
```

This detects ecosystem breakage before publishing.

---

# 61. Compatibility manifest

Maintain:

```text
stack/compatibility.toml
```

Example:

```toml
[[compatible]]
pg_money = ">=0.1,<0.2"
pg_cryptocurrency = ">=0.1,<0.2"
pg_fx = ">=0.1,<0.2"
pg_ledger = ">=0.1,<0.2"
pg_reconcile = ">=0.1,<0.2"
pg_risk = ">=0.1,<0.2"
```

The manifest must eventually become part of release policy.

---

# 62. Stack version

The stack repo may have its own semantic version:

```text
pg-financial-stack 0.1.0
```

representing a tested combination.

Example release:

```text
Financial Stack 0.1.0

pg_money          0.1.3
pg_cryptocurrency 0.1.2
pg_fx             0.1.0
pg_ledger         0.1.1
pg_reconcile      0.1.0
pg_risk           0.1.0
```

This is valuable for deployments.

---

# 63. Golden stack releases

Create Git tags such as:

```text
stack-v0.1.0
stack-v0.2.0
```

Each must lock exact extension commits.

This allows production deployments to say:

```text
we run RustedBytes Financial Stack v0.2.0
```

rather than independently tracking six moving repositories.

---

# 64. Scenario framework

Each end-to-end scenario should contain:

```text
setup.sql
execute.sql
expected.sql
validate.sql
README.md
```

Example:

```text
scenarios/fiat_exchange/
├── setup.sql
├── execute.sql
├── expected.sql
├── validate.sql
└── README.md
```

---

# 65. Deterministic test data

Avoid uncontrolled randomness in correctness tests.

Use fixed:

```text
UUIDs
timestamps
amounts
rates
assets
customer IDs
external references
```

Randomized/property tests should use a printed deterministic seed.

---

# 66. Property tests

Add Rust property tests for cross-extension invariants.

Examples:

For every valid fiat amount:

```text
money
→ ledger
→ money

must equal original
```

For crypto:

```text
crypto_amount
→ ledger_amount
→ crypto_amount

must preserve:
asset identity
units
```

For balanced posting sets:

```text
ledger_post succeeds
```

For unbalanced sets:

```text
ledger_post always rejects
```

---

# 67. Fuzzing

The stack repository does not need to replace per-extension fuzzing.

But useful cross-extension fuzz targets include:

```text
amount conversion chains
asset identity adapter chains
FX quote → ledger metadata
malformed extension installation order/adapter enable sequences
```

---

# 68. Observability during tests

Record:

```text
PostgreSQL version
extension versions
commit hashes
Rust version
pgrx version
test seed
CPU
RAM
OS
database settings
```

Benchmark output must include these values.

---

# 69. PostgreSQL logs

On failure, CI artifacts should include:

```text
postgresql.log
stack version manifest
failed SQL
test runner output
EXPLAIN plans for configured benchmark failures where useful
```

---

# 70. Database snapshots

For difficult failures, optionally preserve:

```text
pg_dump
```

as CI artifacts.

Do not enable by default for every successful test.

---

# 71. Documentation

`README.md` should immediately answer:

```text
what extensions make up the stack?
which versions are compatible?
how do I run it locally?
how do I validate a candidate extension?
how do I run end-to-end tests?
```

---

# 72. `ARCHITECTURE.md`

Document:

```text
pg_money
       │
       ├─────────────┐
       ▼             ▼
pg_cryptocurrency   pg_fx
       │             │
       └──────┬──────┘
              ▼
          pg_ledger
              │
              ▼
        pg_reconcile
              │
              ▼
           pg_risk
```

This is conceptual dependency, not necessarily hard PostgreSQL extension dependency.

---

# 73. `ADDING_EXTENSION.md`

Adding another extension should require:

```text
1. add manifest entry
2. add installer definition
3. define adapters/interactions
4. add smoke test
5. add installation-order cases
6. add invariant checks
7. add full-stack scenario if applicable
```

Future examples:

```text
pg_compliance
pg_settlement
```

if such extensions are ever created.

---

# 74. CI failure categories

Classify failures:

```text
BUILD
INSTALL
ADAPTER
TYPE_COMPATIBILITY
INVARIANT
SECURITY
CONCURRENCY
UPGRADE
PERFORMANCE
SCENARIO
```

This will make six-repository failures easier to triage.

---

# 75. Fast validation mode

For extension development:

```bash
just check-extension pg-ledger
```

Should:

```text
build candidate local pg-ledger

install released/stable versions of companions

run only pg-ledger-relevant stack tests
```

Similarly:

```bash
just check-extension pg-fx
```

This will be important for developer productivity.

---

# 76. Full validation mode

For release:

```bash
just release-check
```

Run:

```text
all PostgreSQL versions
all core scenarios
security tests
concurrency
upgrade path
dump/restore
full invariant validation
```

---

# 77. Initial v0.1 scope

Implement:

```text
manifest-based extension installation

local repository mode

PG14–18 Docker environments

smoke installation test

representative installation-order matrix

adapter interoperability tests

fiat type chain

crypto type chain

full fiat exchange scenario

crypto identity isolation scenario

ledger concurrency test

FX execution race

risk concurrency test

reconciliation test

security role checks

stack invariant runner

basic benchmark runner

GitHub Actions
```

---

# 78. v0.2 scope

Add:

```text
upgrade matrix

pg_dump/restore

pg_upgrade

fault injection

large-scale benchmarks

all/expanded installation-order permutations

property tests

release compatibility manifest

stack releases
```

---

# 79. v1.0 criteria

The stack repository can be considered 1.0 when:

```text
all six extensions have stable versions

PostgreSQL 14–18 test matrix passes

supported installation orders are documented and tested

cross-extension type conversions are stable

security matrix passes

high-contention financial workflows pass

upgrade testing is automated

dump/restore passes

fault-injection tests prove transaction atomicity

full-stack invariants pass after every major workload

a locked stack release can be reproduced exactly
```

---

# 80. Primary acceptance test

The most important v0.1 test should be one complete exchange workflow.

Initial state:

```text
customer:
    1000 USD

liquidity:
    sufficient USD/EUR

market data:
    valid fresh USD/EUR rate

risk:
    customer permitted
```

Operation:

```text
customer exchanges 1000 USD → EUR
```

The test must verify:

```text
pg_fx:
    quote exists
    quote pricing is exact
    quote transitions to EXECUTED exactly once

pg_risk:
    ALLOW decision persisted

pg_ledger:
    exact USD postings
    exact EUR postings
    fee posting
    per-asset balance == 0
    account balances correct
    ledger_validate() passes

pg_reconcile:
    external fixture balances reconcile

full stack:
    no floating point
    no duplicate transaction
    correct asset identities
    correct audit references
```

Then repeat the same execution request concurrently.

Expected:

```text
exactly one financial effect
```

This scenario should be the canonical definition of whether the stack works.

---

# 81. Final repository objective

`pg-financial-stack` should become the single place that answers:

> Do these exact versions of all RustedBytes financial PostgreSQL extensions work correctly together?

A green stack build should mean:

```text
buildable
installable
interoperable
secure
concurrency-safe
upgrade-safe
financially invariant
```

for the tested version combination.

The individual repositories prove that each extension works.

`pg-financial-stack` proves that the **financial system composed from them works**.

