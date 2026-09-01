\set ON_ERROR_STOP on
DO $assertions$
BEGIN
  ASSERT (SELECT count(*) FROM risk_decisions
          WHERE idempotency_key LIKE 'stack:risk:race:%' AND status = 'ALLOW') = 1;
  ASSERT (SELECT count(*) FROM risk_decisions
          WHERE idempotency_key LIKE 'stack:risk:race:%' AND status = 'DENY') = 1;
  ASSERT NOT EXISTS (SELECT FROM risk_validate() WHERE status <> 'OK');
END
$assertions$;

