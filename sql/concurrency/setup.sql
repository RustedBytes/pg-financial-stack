\set ON_ERROR_STOP on
CREATE TABLE IF NOT EXISTS stack_test_context (key text PRIMARY KEY, value text NOT NULL);

SELECT ledger_create_account('stack:race:a', 'USD', 'ANY') AS account_a \gset
SELECT ledger_create_account('stack:race:b', 'USD', 'ANY') AS account_b \gset
SELECT ledger_create_account('stack:race:c', 'USD', 'ANY') AS account_c \gset
INSERT INTO stack_test_context VALUES
  ('account_a', :'account_a'), ('account_b', :'account_b'), ('account_c', :'account_c');

SELECT risk_subject_create('CUSTOMER', 'stack-race-customer') AS subject_id \gset
SELECT risk_policy_create('stack-race-policy', 'WITHDRAWAL') AS policy_id \gset
SELECT risk_rule_create(:'policy_id', 'stack-race-limit', 'ROLLING_VOLUME_LIMIT',
  '{"asset":"USD","window":"24 hours","max_units":"50000"}');
SELECT status FROM risk_check(:'subject_id', 'WITHDRAWAL', 'USD 400.00',
  idempotency_key => 'stack:risk:initial');
INSERT INTO stack_test_context VALUES ('risk_subject', :'subject_id');

SELECT fx_source_upsert('stack-race-market', 1, true, interval '1 hour');
SELECT fx_rate_insert('stack-race-market', 'USD/EUR', 0.85, 0.85, rate_volume => 10000);
SELECT (fx_create_quote('USD 1.00'::money_with_currency, 'EUR', customer_id => 'stack-race')).id AS race_quote \gset
INSERT INTO stack_test_context VALUES ('race_quote', :'race_quote');

