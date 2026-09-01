SELECT ledger_transfer(
  (SELECT value::uuid FROM stack_bench_context WHERE key = 'ledger_source'),
  (SELECT value::uuid FROM stack_bench_context WHERE key = 'ledger_target'),
  'USD 0.01', NULL, 'bench:transfer:' || gen_random_uuid()::text
);

