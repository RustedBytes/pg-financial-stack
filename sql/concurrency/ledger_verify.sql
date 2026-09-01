\set ON_ERROR_STOP on
DO $assertions$
BEGIN
  ASSERT NOT EXISTS (SELECT FROM ledger_validate() WHERE status <> 'OK');
  ASSERT (SELECT count(*) FROM ledger_transactions WHERE idempotency_key LIKE 'stack:ledger-race:%') > 0;
  ASSERT (SELECT count(DISTINCT idempotency_key) = count(*)
          FROM ledger_transactions WHERE idempotency_key LIKE 'stack:ledger-race:%');
END
$assertions$;

