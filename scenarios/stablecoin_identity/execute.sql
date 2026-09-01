\set ON_ERROR_STOP on
DO $assertions$
DECLARE rejected boolean := false;
BEGIN
  BEGIN
    PERFORM fx_create_quote('1000 USDT@tron'::crypto_amount, 'USD');
  EXCEPTION WHEN OTHERS THEN
    rejected := true;
  END;
  ASSERT rejected, 'ticker-only stablecoin substitution was accepted';
END
$assertions$;
