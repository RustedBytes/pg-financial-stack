SELECT status FROM risk_evaluate(
  (SELECT value::uuid FROM stack_bench_context WHERE key = 'risk_subject'),
  'DEPOSIT', 'USD 1.00'::money_with_currency
);

