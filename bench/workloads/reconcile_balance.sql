SELECT reconcile_balance_insert(
  (SELECT value::uuid FROM stack_bench_context WHERE key = 'reconcile_account'),
  ledger_to_money(ledger_balance((SELECT value::uuid FROM stack_bench_context WHERE key = 'ledger_target'))),
  clock_timestamp(), 'bench-balance-' || gen_random_uuid()::text
);

