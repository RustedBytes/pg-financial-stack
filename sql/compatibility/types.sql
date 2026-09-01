\set ON_ERROR_STOP on

DO $assertions$
BEGIN
  -- Fiat survives pg_money -> pg_ledger -> pg_money exactly.
  ASSERT ledger_to_money(ledger_amount('USD 100.00'::money_with_currency))
      = 'USD 100.00'::money_with_currency;
  ASSERT ledger_amount_units(ledger_amount('JPY 1'::money_with_currency)) = 1;
  ASSERT ledger_amount_units(ledger_amount('USD 0.01'::money_with_currency)) = 1;

  -- Crypto survives pg_cryptocurrency -> pg_ledger -> pg_cryptocurrency exactly.
  ASSERT ledger_amount(ledger_to_crypto(ledger_amount('0.00000001 BTC'::crypto_amount)))
      = ledger_amount('0.00000001 BTC'::crypto_amount);
  ASSERT ledger_amount(ledger_to_crypto(ledger_amount('0.000001 USDT@ethereum'::crypto_amount)))
      = ledger_amount('0.000001 USDT@ethereum'::crypto_amount);

  -- Equal tickers on distinct networks are distinct assets through every adapter.
  ASSERT reconcile_asset('USDT@ethereum') <> reconcile_asset('USDT@tron');
  ASSERT risk_asset('USDT@ethereum') <> risk_asset('USDT@tron');
  ASSERT ledger_amount_asset(ledger_amount('1 USDT@ethereum'::crypto_amount))::text
      <> reconcile_asset('USDT@tron');
  ASSERT reconcile_asset('USDC@ethereum') <> reconcile_asset('USDC@solana');
  ASSERT reconcile_asset('BTC@bitcoin') <> reconcile_asset('BTC@ethereum/8');

  -- Adapter arithmetic is exact numeric/integer arithmetic, never float.
  ASSERT pg_typeof(ledger_amount_units(ledger_amount('USD 1.23'::money_with_currency)))::text
      IN ('bigint', 'numeric');
END
$assertions$;
