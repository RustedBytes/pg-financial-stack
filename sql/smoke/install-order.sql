\set ON_ERROR_STOP on
\getenv SQL_ORDER SQL_ORDER

DO $roles$
DECLARE role_name text;
BEGIN
  FOREACH role_name IN ARRAY ARRAY[
    'reconcile_reader', 'reconcile_ingestor', 'reconcile_operator', 'reconcile_admin',
    'risk_reader', 'risk_evaluator', 'risk_operator', 'risk_admin'
  ] LOOP
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = role_name) THEN
      EXECUTE format('CREATE ROLE %I NOLOGIN', role_name);
    END IF;
  END LOOP;
END
$roles$;

SELECT format('CREATE EXTENSION %I', extension_name)
FROM unnest(string_to_array(:'SQL_ORDER', ' ')) WITH ORDINALITY AS item(extension_name, position)
ORDER BY position
\gexec

SELECT format('SELECT %I()', function_name)
FROM unnest(ARRAY[
  'ledger_enable_pg_money', 'ledger_enable_pg_cryptocurrency',
  'fx_enable_pg_money', 'fx_enable_pg_cryptocurrency',
  'reconcile_enable_pg_ledger', 'reconcile_enable_pg_money',
  'reconcile_enable_pg_cryptocurrency', 'risk_enable_pg_ledger',
  'risk_enable_pg_fx', 'risk_enable_pg_reconcile', 'risk_enable_pg_money',
  'risk_enable_pg_cryptocurrency'
]) AS function_name
WHERE to_regprocedure(function_name || '()') IS NOT NULL
\gexec

DO $assertions$
BEGIN
  ASSERT (SELECT count(*) FROM pg_extension WHERE extname = ANY (ARRAY[
    'pg_money', 'pg_cryptocurrency', 'pg_fx', 'pg_ledger', 'pg_reconcile', 'pg_risk'
  ])) = 6;
  ASSERT to_regprocedure('ledger_amount(money_with_currency)') IS NOT NULL;
  ASSERT to_regprocedure('ledger_amount(crypto_amount)') IS NOT NULL;
  ASSERT to_regprocedure('fx_create_quote(money_with_currency,text,text,text,interval,fx_rounding_mode,jsonb)') IS NOT NULL;
  ASSERT to_regprocedure('risk_check(uuid,risk_operation_kind,money_with_currency,text,uuid,text,timestamptz,jsonb,text,timestamptz)') IS NOT NULL;
END
$assertions$;
