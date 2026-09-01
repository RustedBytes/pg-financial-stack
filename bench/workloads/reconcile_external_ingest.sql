SELECT reconcile_external_transaction_insert(
  (SELECT value::uuid FROM stack_bench_context WHERE key = 'reconcile_account'),
  'bench-external-' || gen_random_uuid()::text, 'USD 0.01'::money_with_currency,
  'CREDIT', clock_timestamp(), 'SETTLED', clock_timestamp(),
  NULL, NULL, NULL, '{}', 'bench:external:' || gen_random_uuid()::text
);

