BEGIN;
SELECT status FROM risk_evaluate(
  (SELECT value::uuid FROM stack_bench_context WHERE key = 'risk_subject'),
  'FX_EXCHANGE', 'USD 1.00'::money_with_currency
);
SELECT ledger_transfer(
  (SELECT value::uuid FROM stack_bench_context WHERE key = 'ledger_source'),
  (SELECT value::uuid FROM stack_bench_context WHERE key = 'ledger_target'),
  'USD 0.01', NULL, 'bench:exchange:' || gen_random_uuid()::text
);
SELECT fx_execute_quote((fx_create_quote(
  'USD 1.00'::money_with_currency, 'EUR', customer_id => 'bench-customer'
)).id);
COMMIT;

