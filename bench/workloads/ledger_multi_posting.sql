SELECT ledger_post(ARRAY[
  ledger_posting((SELECT value::uuid FROM stack_bench_context WHERE key = 'ledger_source'), '-0.02 USD'),
  ledger_posting((SELECT value::uuid FROM stack_bench_context WHERE key = 'ledger_target'), '0.01 USD'),
  ledger_posting((SELECT value::uuid FROM stack_bench_context WHERE key = 'ledger_third'), '0.01 USD')
], idempotency_key => 'bench:multi:' || gen_random_uuid()::text);

