\set ON_ERROR_STOP off
BEGIN;
SELECT ledger_transfer(
  (SELECT value::uuid FROM stack_test_context WHERE key = 'account_a'),
  (SELECT value::uuid FROM stack_test_context WHERE key = 'account_b'),
  'USD 9.99', NULL, 'stack:fault:must-rollback'
);
DO $$ BEGIN RAISE EXCEPTION 'injected failure after ledger_post'; END $$;
COMMIT;
\set ON_ERROR_STOP on
SELECT 1 / CASE WHEN NOT EXISTS (
  SELECT FROM ledger_transactions WHERE idempotency_key = 'stack:fault:must-rollback'
) THEN 1 ELSE 0 END AS atomic_rollback_ok;

