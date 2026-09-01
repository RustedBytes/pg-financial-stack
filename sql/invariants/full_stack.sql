\set ON_ERROR_STOP on

DROP TABLE IF EXISTS stack_invariant_results;
CREATE TEMP TABLE stack_invariant_results (
  check_name text PRIMARY KEY,
  status text NOT NULL,
  violations bigint NOT NULL,
  details text NOT NULL
);

INSERT INTO stack_invariant_results
SELECT 'ledger_validate', CASE WHEN count(*) = 0 THEN 'OK' ELSE 'FAIL' END,
       count(*), coalesce(string_agg(check_name || ': ' || violations, '; '), 'all extension checks pass')
FROM ledger_validate() WHERE status <> 'OK';

INSERT INTO stack_invariant_results
SELECT 'ledger_idempotency', CASE WHEN count(*) = 0 THEN 'OK' ELSE 'FAIL' END,
       count(*), 'each non-null idempotency key names one canonical transaction'
FROM (
  SELECT idempotency_key FROM ledger_transactions WHERE idempotency_key IS NOT NULL
  GROUP BY idempotency_key HAVING count(*) > 1
) duplicate;

INSERT INTO stack_invariant_results
SELECT 'fx_execution_uniqueness', CASE WHEN count(*) = 0 THEN 'OK' ELSE 'FAIL' END,
       count(*), 'an executed quote has at most one referenced ledger transaction'
FROM (
  SELECT q.id
  FROM fx_quotes q
  JOIN ledger_transactions t ON t.reference = 'fx:' || q.id::text
  WHERE q.status = 'executed'
  GROUP BY q.id HAVING count(*) > 1
) duplicate;

INSERT INTO stack_invariant_results
SELECT 'asset_identity',
       CASE WHEN reconcile_asset('USDT@ethereum') <> reconcile_asset('USDT@tron')
              AND risk_asset('USDT@ethereum') <> risk_asset('USDT@tron')
            THEN 'OK' ELSE 'FAIL' END,
       CASE WHEN reconcile_asset('USDT@ethereum') <> reconcile_asset('USDT@tron')
                   AND risk_asset('USDT@ethereum') <> risk_asset('USDT@tron')
            THEN 0 ELSE 1 END,
       'network-qualified crypto identities survive adapter conversion';

INSERT INTO stack_invariant_results
SELECT 'reconcile_validate', CASE WHEN count(*) = 0 THEN 'OK' ELSE 'FAIL' END,
       count(*), coalesce(string_agg(check_name || ': ' || violations, '; '), 'all extension checks pass')
FROM reconcile_validate() WHERE status <> 'OK';

INSERT INTO stack_invariant_results
SELECT 'risk_validate', CASE WHEN count(*) = 0 THEN 'OK' ELSE 'FAIL' END,
       count(*), coalesce(string_agg(check_name || ': ' || violations, '; '), 'all extension checks pass')
FROM risk_validate() WHERE status <> 'OK';

INSERT INTO stack_invariant_results
SELECT 'exact_smallest_units',
       CASE WHEN ledger_amount_units(ledger_amount('USD 0.01'::money_with_currency)) = 1
              AND ledger_amount_units(ledger_amount('0.00000001 BTC'::crypto_amount)) = 1
            THEN 'OK' ELSE 'FAIL' END,
       CASE WHEN ledger_amount_units(ledger_amount('USD 0.01'::money_with_currency)) = 1
              AND ledger_amount_units(ledger_amount('0.00000001 BTC'::crypto_amount)) = 1
            THEN 0 ELSE 1 END,
       'fiat and crypto adapters preserve one smallest unit';

TABLE stack_invariant_results ORDER BY check_name;

DO $assertions$
BEGIN
  ASSERT NOT EXISTS (SELECT FROM stack_invariant_results WHERE status <> 'OK'),
    (SELECT string_agg(check_name || ': ' || details, E'\n')
     FROM stack_invariant_results WHERE status <> 'OK');
END
$assertions$;
