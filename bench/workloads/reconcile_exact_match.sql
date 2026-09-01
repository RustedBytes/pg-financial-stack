SELECT count(*) FROM reconcile_transactions(
  (SELECT value::uuid FROM stack_bench_context WHERE key = 'reconcile_account'), clock_timestamp()
);

