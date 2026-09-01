\set ON_ERROR_STOP on
BEGIN;
SELECT status FROM risk_check(
  (SELECT value::uuid FROM stack_test_context WHERE key = 'risk_subject'),
  'WITHDRAWAL', 'USD 100.00', idempotency_key => 'stack:risk:race:' || :worker
);
SELECT pg_sleep(0.2);
COMMIT;

