\set ON_ERROR_STOP on

SELECT reconcile_create_account(
  'stack-customer-usd', current_setting('stack.customer_usd')::uuid, 'USD',
  'stack-bank', 'customer-usd', 'BANK', 'BOOK', 0
) AS customer_reconcile \gset
SELECT reconcile_balance_insert(
  :'customer_reconcile', 'USD 0.00'::money_with_currency,
  '2026-01-01 00:02:00+00', 'stack-bank:balance:1', NULL,
  '2026-01-01 00:02:01+00'
);
SELECT (reconcile_balance(:'customer_reconcile', '2026-01-01 00:02:00+00')).id AS result_id \gset
SELECT set_config('stack.reconcile_result', :'result_id', false);

DO $assertions$
BEGIN
  ASSERT (SELECT status FROM reconcile_balance_results
          WHERE id = current_setting('stack.reconcile_result')::uuid) = 'MATCHED';
  ASSERT NOT EXISTS (SELECT FROM reconcile_validate() WHERE status <> 'OK');
  ASSERT NOT EXISTS (SELECT FROM risk_validate() WHERE status <> 'OK');
END
$assertions$;
