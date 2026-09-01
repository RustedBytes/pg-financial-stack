\set ON_ERROR_STOP on
SELECT 1 / CASE WHEN NOT EXISTS (
  SELECT FROM fx_quotes WHERE input_asset = 'USDT@tron' AND output_asset = 'USD'
) THEN 1 ELSE 0 END;

