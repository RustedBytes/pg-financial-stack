\set ON_ERROR_STOP on
CREATE SCHEMA finance_money;
CREATE SCHEMA finance_crypto;
-- Non-relocatable extensions intentionally reject a SCHEMA clause. Their
-- secure, extension-owned object resolution is exercised by search_path.sql.
CREATE EXTENSION pg_money SCHEMA finance_money;
CREATE EXTENSION pg_cryptocurrency SCHEMA finance_crypto;
CREATE EXTENSION pg_fx;
CREATE EXTENSION pg_ledger;
CREATE EXTENSION pg_reconcile;
CREATE EXTENSION pg_risk;
SELECT ledger_enable_pg_money(), ledger_enable_pg_cryptocurrency();
SELECT fx_enable_pg_money(), fx_enable_pg_cryptocurrency();
SELECT reconcile_enable_pg_money(), reconcile_enable_pg_cryptocurrency(), reconcile_enable_pg_ledger();
SELECT risk_enable_pg_money(), risk_enable_pg_cryptocurrency(), risk_enable_pg_ledger();

SET search_path = finance_crypto, finance_money, public, pg_catalog;
DO $assertions$
BEGIN
  ASSERT money_currency('USD 1'::money_with_currency) = 'USD';
  ASSERT crypto_asset_symbol(crypto_amount_asset('1 BTC'::crypto_amount)) = 'BTC';
  ASSERT crypto_asset_network(crypto_amount_asset('1 BTC'::crypto_amount))::text = 'bitcoin';
END
$assertions$;
RESET search_path;
