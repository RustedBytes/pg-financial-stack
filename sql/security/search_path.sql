\set ON_ERROR_STOP on

CREATE SCHEMA IF NOT EXISTS attacker;
CREATE TABLE attacker.ledger_accounts (id uuid, current_balance_units bigint);
CREATE FUNCTION attacker.ledger_balance(uuid) RETURNS ledger_amount
LANGUAGE plpgsql AS $$ BEGIN RAISE EXCEPTION 'attacker function executed'; END $$;

SELECT ledger_create_account('stack:security:source', 'USD', 'ANY') AS secure_source \gset
SELECT ledger_create_account('stack:security:target', 'USD', 'ANY') AS secure_target \gset
SELECT set_config('stack.secure_target', :'secure_target', false);
SET search_path = attacker, public;
SELECT public.ledger_transfer(
  :'secure_source', :'secure_target', 'USD 1.00', 'stack:security:transfer',
  'stack:security:transfer'
);
RESET search_path;

DO $assertions$
BEGIN
  ASSERT ledger_amount_units(ledger_balance(current_setting('stack.secure_target')::uuid)) = 100;
  ASSERT NOT EXISTS (SELECT FROM ledger_validate() WHERE status <> 'OK');
END
$assertions$;
