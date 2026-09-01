\set ON_ERROR_STOP on

DO $roles$
DECLARE role_name text;
BEGIN
  FOREACH role_name IN ARRAY ARRAY[
    'extension_owner', 'exchange_app', 'market_data_ingestor', 'ledger_reader',
    'reconcile_reader', 'reconcile_ingestor', 'reconcile_operator',
    'reconcile_admin', 'risk_reader', 'risk_evaluator', 'risk_operator',
    'risk_admin', 'auditor', 'unprivileged'
  ] LOOP
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = role_name) THEN
      EXECUTE format('CREATE ROLE %I NOLOGIN', role_name);
    END IF;
  END LOOP;
END
$roles$;

CREATE EXTENSION IF NOT EXISTS pg_money;
CREATE EXTENSION IF NOT EXISTS pg_cryptocurrency;
CREATE EXTENSION IF NOT EXISTS pg_fx;
CREATE EXTENSION IF NOT EXISTS pg_ledger;
CREATE EXTENSION IF NOT EXISTS pg_reconcile;
CREATE EXTENSION IF NOT EXISTS pg_risk;

DO $assertions$
DECLARE missing text[];
BEGIN
  SELECT array_agg(required.name ORDER BY required.name)
    INTO missing
  FROM unnest(ARRAY[
    'pg_money', 'pg_cryptocurrency', 'pg_fx', 'pg_ledger', 'pg_reconcile', 'pg_risk'
  ]) AS required(name)
  WHERE NOT EXISTS (SELECT FROM pg_extension e WHERE e.extname = required.name);
  ASSERT missing IS NULL, format('missing extensions: %s', missing);
END
$assertions$;

SELECT extname, extversion
FROM pg_extension
WHERE extname = ANY (ARRAY[
  'pg_money', 'pg_cryptocurrency', 'pg_fx', 'pg_ledger', 'pg_reconcile', 'pg_risk'
])
ORDER BY extname;

