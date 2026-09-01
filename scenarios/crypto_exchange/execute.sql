\set ON_ERROR_STOP on
SELECT (fx_create_quote('0.1 BTC'::crypto_amount, 'USD', customer_id => 'stack-crypto-customer')).id AS quote_id \gset
BEGIN;
SELECT ledger_post(ARRAY[
  ledger_posting(:'customer_btc'::uuid, '-0.1 BTC@bitcoin'),
  ledger_posting(:'liquidity_btc'::uuid, '0.1 BTC@bitcoin'),
  ledger_posting(:'liquidity_usd'::uuid, '-10000 USD'),
  ledger_posting(:'customer_usd'::uuid, '10000 USD')
], reference => 'fx:' || :'quote_id', idempotency_key => 'stack:crypto:exchange:1',
metadata => fx_quote_ledger_metadata(:'quote_id'));
SELECT fx_execute_quote(:'quote_id');
COMMIT;
SELECT set_config('stack.crypto_quote', :'quote_id', false);
