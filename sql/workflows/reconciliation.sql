\set ON_ERROR_STOP on

SELECT ledger_create_account('stack:reconcile:source', 'USD', 'ANY') AS rec_source \gset
SELECT ledger_create_account('stack:reconcile:mapped', 'USD', 'ANY') AS rec_mapped \gset
SELECT reconcile_create_account(
  'stack-reconciliation', :'rec_mapped', 'USD', 'stack-bank', 'historical-usd',
  'BANK', 'BOOK', 1
) AS rec_account \gset
SELECT ledger_transfer(:'rec_source', :'rec_mapped', 'USD 10.00',
  'stack:rec:deposit', 'stack:rec:deposit', '2026-02-01 10:00:00+00');

SELECT reconcile_balance_insert(:'rec_account', 'USD 10.00'::money_with_currency,
  '2026-02-01 10:00:00+00', 'stack:rec:exact', NULL, '2026-02-01 10:00:01+00');
SELECT (reconcile_balance(:'rec_account', '2026-02-01 10:00:00+00')).id AS exact_result \gset

SELECT reconcile_balance_insert(:'rec_account', 'USD 9.99'::money_with_currency,
  '2026-02-01 10:01:00+00', 'stack:rec:tolerance', NULL, '2026-02-01 10:01:01+00');
SELECT (reconcile_balance(:'rec_account', '2026-02-01 10:01:00+00')).id AS tolerance_result \gset

SELECT reconcile_balance_insert(:'rec_account', 'USD 9.00'::money_with_currency,
  '2026-02-01 10:02:00+00', 'stack:rec:mismatch', NULL, '2026-02-01 10:02:01+00');
SELECT (reconcile_balance(:'rec_account', '2026-02-01 10:02:00+00')).id AS mismatch_result \gset

SELECT ledger_transfer(:'rec_source', :'rec_mapped', 'USD 2.00',
  'stack:rec:later', 'stack:rec:later', '2026-02-01 10:30:00+00');
SELECT set_config('stack.rec_exact', :'exact_result', false);
SELECT set_config('stack.rec_tolerance', :'tolerance_result', false);
SELECT set_config('stack.rec_mismatch', :'mismatch_result', false);
SELECT set_config('stack.rec_mapped', :'rec_mapped', false);

DO $assertions$
BEGIN
  ASSERT (SELECT status FROM reconcile_balance_results
          WHERE id = current_setting('stack.rec_exact')::uuid) = 'MATCHED';
  ASSERT (SELECT status FROM reconcile_balance_results
          WHERE id = current_setting('stack.rec_tolerance')::uuid) = 'WITHIN_TOLERANCE';
  ASSERT (SELECT status FROM reconcile_balance_results
          WHERE id = current_setting('stack.rec_mismatch')::uuid) = 'MISMATCH';
  ASSERT (SELECT ledger_balance_units FROM reconcile_balance_results
          WHERE id = current_setting('stack.rec_exact')::uuid) = 1000;
  ASSERT ledger_amount_units(ledger_balance(current_setting('stack.rec_mapped')::uuid)) = 1200;
  ASSERT NOT EXISTS (SELECT FROM reconcile_validate() WHERE status <> 'OK');
END
$assertions$;
