\set ON_ERROR_STOP on
SELECT 1 / CASE WHEN reconcile_asset('USDT@ethereum') <> reconcile_asset('USDT@tron') THEN 1 ELSE 0 END;
