CREATE TABLE IF NOT EXISTS stack_bench_context (key text PRIMARY KEY, value text NOT NULL);

INSERT INTO stack_bench_context
SELECT 'ledger_source', ledger_create_account('bench:source', 'USD', 'ANY')::text
WHERE NOT EXISTS (SELECT FROM stack_bench_context WHERE key = 'ledger_source');
INSERT INTO stack_bench_context
SELECT 'ledger_target', ledger_create_account('bench:target', 'USD', 'ANY')::text
WHERE NOT EXISTS (SELECT FROM stack_bench_context WHERE key = 'ledger_target');
INSERT INTO stack_bench_context
SELECT 'ledger_third', ledger_create_account('bench:third', 'USD', 'ANY')::text
WHERE NOT EXISTS (SELECT FROM stack_bench_context WHERE key = 'ledger_third');

SELECT fx_source_upsert('bench-market', 1, true, interval '1 day');
SELECT fx_rate_insert('bench-market', 'USD/EUR', 0.85, 0.86, rate_volume => 1000000);

INSERT INTO stack_bench_context
SELECT 'risk_subject', risk_subject_create('CUSTOMER', 'bench-customer')::text
WHERE NOT EXISTS (SELECT FROM stack_bench_context WHERE key = 'risk_subject');

INSERT INTO stack_bench_context
SELECT 'reconcile_account', reconcile_create_account(
  'bench-bank', (SELECT value::uuid FROM stack_bench_context WHERE key = 'ledger_target'),
  'USD', 'bench-provider', 'bench-account', 'BANK', 'BOOK', 100
)::text
WHERE NOT EXISTS (SELECT FROM stack_bench_context WHERE key = 'reconcile_account');

