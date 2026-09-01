\set ON_ERROR_STOP on
DO $assertions$
BEGIN
  ASSERT (SELECT status = 'executed' AND pair = 'BTC/USD'
                 AND input_asset = 'BTC' AND output_asset = 'USD'
          FROM fx_quotes WHERE id = current_setting('stack.crypto_quote'));
  ASSERT 2 = (SELECT count(*)
              FROM ledger_entries e
              JOIN ledger_transactions t ON t.id = e.transaction_id
              WHERE t.reference = 'fx:' || current_setting('stack.crypto_quote')
                AND ledger_amount_asset(e.amount)::text = 'BTC@bitcoin');
  ASSERT NOT EXISTS (SELECT FROM ledger_validate() WHERE status <> 'OK');
END
$assertions$;
