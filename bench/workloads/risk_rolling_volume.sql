SELECT status FROM risk_check(
  (SELECT value::uuid FROM stack_bench_context WHERE key = 'risk_subject'),
  'DEPOSIT', 'USD 1.00'::money_with_currency,
  idempotency_key => 'bench:risk:' || gen_random_uuid()::text
);

