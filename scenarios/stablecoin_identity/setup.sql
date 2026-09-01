\set ON_ERROR_STOP on
SELECT fx_source_upsert('stack-stablecoin-market', 1, true, interval '1 hour');
SELECT fx_rate_insert('stack-stablecoin-market', 'USDT@ethereum/USD', 1, 1, rate_volume => 1000000);

