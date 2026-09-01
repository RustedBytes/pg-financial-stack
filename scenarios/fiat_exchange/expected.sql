\set ON_ERROR_STOP on

DO $assertions$
BEGIN
  ASSERT fx_quote_effective_status(current_setting('stack.quote_id')) = 'executed';
  ASSERT (SELECT input_amount = 995 AND output_amount = 845.75
          FROM fx_quotes WHERE id = current_setting('stack.quote_id'));
  ASSERT ledger_amount_units(ledger_balance(current_setting('stack.customer_usd')::uuid)) = 0;
  ASSERT ledger_amount_units(ledger_balance(current_setting('stack.customer_eur')::uuid)) = 84575;
  ASSERT ledger_amount_units(ledger_balance(current_setting('stack.fee_usd')::uuid)) = 500;
  ASSERT ledger_amount_units(ledger_balance(current_setting('stack.liquidity_usd')::uuid)) = -500;
  ASSERT ledger_amount_units(ledger_balance(current_setting('stack.liquidity_eur')::uuid)) = -84575;
  ASSERT (SELECT count(*) FROM ledger_transactions WHERE idempotency_key = 'stack:exchange:1') = 1;
  ASSERT (SELECT count(*) FROM risk_decisions WHERE idempotency_key = 'stack:exchange:risk:1' AND status = 'ALLOW') = 1;
  ASSERT (SELECT reference = 'fx:' || current_setting('stack.quote_id')
                 AND metadata->>'quote_id' = current_setting('stack.quote_id')
          FROM ledger_transactions WHERE idempotency_key = 'stack:exchange:1');
  ASSERT (SELECT metadata->>'quote_id' = current_setting('stack.quote_id')
          FROM risk_decisions WHERE idempotency_key = 'stack:exchange:risk:1');
  ASSERT NOT EXISTS (SELECT FROM ledger_validate() WHERE status <> 'OK');
END
$assertions$;
