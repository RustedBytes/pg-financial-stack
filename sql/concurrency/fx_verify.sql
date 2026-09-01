\set ON_ERROR_STOP on
DO $assertions$
BEGIN
  ASSERT (SELECT count(*) FROM ledger_transactions WHERE idempotency_key = 'stack:fx:race:effect') = 1;
  ASSERT (SELECT count(*) FROM fx_quotes
          WHERE id = (SELECT value FROM stack_test_context WHERE key = 'race_quote')
            AND status = 'executed') = 1;
  ASSERT NOT EXISTS (SELECT FROM ledger_validate() WHERE status <> 'OK');
END
$assertions$;
