\set ON_ERROR_STOP on

SELECT ledger_enable_pg_money();
SELECT ledger_enable_pg_cryptocurrency();
SELECT fx_enable_pg_money();
SELECT fx_enable_pg_cryptocurrency();
SELECT reconcile_enable_pg_ledger();
SELECT reconcile_enable_pg_money();
SELECT reconcile_enable_pg_cryptocurrency();
SELECT risk_enable_pg_ledger();
SELECT risk_enable_pg_fx();
SELECT risk_enable_pg_reconcile();
SELECT risk_enable_pg_money();
SELECT risk_enable_pg_cryptocurrency();

-- Calling every supported late-enablement adapter a second time proves idempotency.
SELECT ledger_enable_pg_money();
SELECT ledger_enable_pg_cryptocurrency();
SELECT fx_enable_pg_money();
SELECT fx_enable_pg_cryptocurrency();
SELECT reconcile_enable_pg_ledger();
SELECT reconcile_enable_pg_money();
SELECT reconcile_enable_pg_cryptocurrency();
SELECT risk_enable_pg_ledger();
SELECT risk_enable_pg_fx();
SELECT risk_enable_pg_reconcile();
SELECT risk_enable_pg_money();
SELECT risk_enable_pg_cryptocurrency();

DO $assertions$
BEGIN
  ASSERT to_regprocedure('ledger_amount(money_with_currency)') IS NOT NULL;
  ASSERT to_regprocedure('ledger_amount(crypto_amount)') IS NOT NULL;
  ASSERT to_regprocedure('reconcile_balance_insert(uuid,money_with_currency,timestamptz,text,text,timestamptz,jsonb,text)') IS NOT NULL;
  ASSERT to_regprocedure('reconcile_balance_insert(uuid,crypto_amount,timestamptz,text,text,timestamptz,jsonb,text)') IS NOT NULL;
  ASSERT to_regprocedure('risk_check(uuid,risk_operation_kind,crypto_amount,text,uuid,text,timestamptz,jsonb,text,timestamptz)') IS NOT NULL;
END
$assertions$;

