\set ON_ERROR_STOP on
SELECT ledger_create_account('stack:crypto:btc', 'BTC@bitcoin', 'ANY') AS customer_btc \gset
SELECT ledger_create_account('stack:crypto:btc-liquidity', 'BTC@bitcoin', 'ANY') AS liquidity_btc \gset
SELECT ledger_create_account('stack:crypto:usd', 'USD', 'ANY') AS customer_usd \gset
SELECT ledger_create_account('stack:crypto:usd-liquidity', 'USD', 'ANY') AS liquidity_usd \gset
SELECT fx_source_upsert('stack-crypto-market', 1, true, interval '1 hour');
-- pg_fx uses the native-coin ticker for pricing while pg_ledger retains the
-- network-qualified asset identity in its postings.
SELECT fx_rate_insert('stack-crypto-market', 'BTC/USD', 100000, 100000, rate_volume => 10);
