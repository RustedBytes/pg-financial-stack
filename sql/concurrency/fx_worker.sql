\set ON_ERROR_STOP on
BEGIN;
SELECT ledger_transfer(
  (SELECT value::uuid FROM stack_test_context WHERE key = 'account_a'),
  (SELECT value::uuid FROM stack_test_context WHERE key = 'account_b'),
  'USD 0.01',
  'fx:' || (SELECT value FROM stack_test_context WHERE key = 'race_quote'),
  'stack:fx:race:effect'
);
DO $execute$
BEGIN
  PERFORM fx_execute_quote((SELECT value FROM stack_test_context WHERE key = 'race_quote'));
EXCEPTION WHEN object_not_in_prerequisite_state THEN
  -- Deterministic already-executed error is an allowed loser outcome.
  NULL;
END
$execute$;
COMMIT;
