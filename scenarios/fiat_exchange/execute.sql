\set ON_ERROR_STOP on

BEGIN;
SELECT status AS risk_status FROM risk_check(
  current_setting('stack.risk_subject')::uuid,
  'FX_EXCHANGE', 'USD 1000.00'::money_with_currency,
  metadata => jsonb_build_object('quote_id', current_setting('stack.quote_id')),
  idempotency_key => 'stack:exchange:risk:1'
) \gset
SELECT 1 / CASE WHEN :'risk_status' = 'ALLOW' THEN 1 ELSE 0 END AS risk_must_allow;

SELECT ledger_post(
  ARRAY[
    ledger_posting(current_setting('stack.customer_usd')::uuid, '-1000 USD'),
    ledger_posting(current_setting('stack.liquidity_usd')::uuid, '995 USD'),
    ledger_posting(current_setting('stack.fee_usd')::uuid, '5 USD'),
    ledger_posting(current_setting('stack.liquidity_eur')::uuid, '-845.75 EUR'),
    ledger_posting(current_setting('stack.customer_eur')::uuid, '845.75 EUR')
  ],
  reference => 'fx:' || current_setting('stack.quote_id'),
  idempotency_key => 'stack:exchange:1',
  event_at => '2026-01-01 00:01:00+00',
  metadata => fx_quote_ledger_metadata(current_setting('stack.quote_id'))
) AS exchange_transaction \gset
SELECT fx_execute_quote(current_setting('stack.quote_id'));
COMMIT;
