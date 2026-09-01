\set ON_ERROR_STOP on

SELECT ledger_create_account('stack:customer:usd', 'USD', 'ANY') AS customer_usd \gset
SELECT ledger_create_account('stack:liquidity:usd', 'USD', 'ANY') AS liquidity_usd \gset
SELECT ledger_create_account('stack:fee:usd', 'USD', 'ANY') AS fee_usd \gset
SELECT ledger_create_account('stack:liquidity:eur', 'EUR', 'ANY') AS liquidity_eur \gset
SELECT ledger_create_account('stack:customer:eur', 'EUR', 'ANY') AS customer_eur \gset

SELECT ledger_transfer(
  :'liquidity_usd', :'customer_usd', 'USD 1000.00', 'stack:initial-funding',
  'stack:initial-funding', '2026-01-01 00:00:00+00'
) AS funding_transaction \gset

SELECT risk_subject_create('CUSTOMER', 'stack-customer', 'retail') AS risk_subject \gset
SELECT risk_policy_create('stack-exchange-policy', 'FX_EXCHANGE', segment => 'retail') AS risk_policy \gset
SELECT risk_rule_create(
  :'risk_policy', 'stack-exchange-limit', 'ROLLING_VOLUME_LIMIT',
  '{"asset":"USD","window":"24 hours","max_units":"1000000"}'
) AS ignored \gset

SELECT fx_source_upsert('stack-market', 1, true, interval '1 hour');
SELECT fx_rate_insert(
  'stack-market', 'USD/EUR', 0.8500, 0.8500,
  rate_observed_at => clock_timestamp(), rate_volume => 1000000
);
SELECT (fx_create_quote(
  'USD 995.00'::money_with_currency, 'EUR', customer_segment => 'retail',
  customer_id => 'stack-customer', expires_in => interval '1 hour'
)).id AS quote_id \gset

SELECT set_config('stack.customer_usd', :'customer_usd', false);
SELECT set_config('stack.liquidity_usd', :'liquidity_usd', false);
SELECT set_config('stack.fee_usd', :'fee_usd', false);
SELECT set_config('stack.liquidity_eur', :'liquidity_eur', false);
SELECT set_config('stack.customer_eur', :'customer_eur', false);
SELECT set_config('stack.risk_subject', :'risk_subject', false);
SELECT set_config('stack.quote_id', :'quote_id', false);
