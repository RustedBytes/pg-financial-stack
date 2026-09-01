\set ON_ERROR_STOP on
SELECT ledger_transfer(
  CASE (:worker::int % 4)
    WHEN 0 THEN (SELECT value::uuid FROM stack_test_context WHERE key = 'account_a')
    WHEN 1 THEN (SELECT value::uuid FROM stack_test_context WHERE key = 'account_b')
    WHEN 2 THEN (SELECT value::uuid FROM stack_test_context WHERE key = 'account_a')
    ELSE (SELECT value::uuid FROM stack_test_context WHERE key = 'account_c') END,
  CASE (:worker::int % 4)
    WHEN 0 THEN (SELECT value::uuid FROM stack_test_context WHERE key = 'account_b')
    WHEN 1 THEN (SELECT value::uuid FROM stack_test_context WHERE key = 'account_a')
    WHEN 2 THEN (SELECT value::uuid FROM stack_test_context WHERE key = 'account_c')
    ELSE (SELECT value::uuid FROM stack_test_context WHERE key = 'account_a') END,
  'USD 0.01', NULL, 'stack:ledger-race:' || :worker,
  clock_timestamp()
);

