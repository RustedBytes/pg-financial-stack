\set ON_ERROR_STOP on

-- The smoke test creates roles before extension installation so extension
-- permission hooks can grant only the documented API surface.
SET SESSION AUTHORIZATION unprivileged;
DO $negative$
BEGIN
  BEGIN
    UPDATE ledger_transactions SET reference = 'forged';
    ASSERT false, 'unprivileged updated immutable ledger history';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    UPDATE fx_quotes SET customer_rate = 999;
    ASSERT false, 'unprivileged changed quote pricing';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    UPDATE reconcile_balance_results SET status = 'MATCHED';
    ASSERT false, 'unprivileged changed reconciliation history';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    UPDATE risk_decisions SET reason = '{}';
    ASSERT false, 'unprivileged changed risk history';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    PERFORM _risk_ledger_balance(NULL, clock_timestamp());
    ASSERT false, 'unprivileged executed an internal risk function';
  EXCEPTION WHEN insufficient_privilege OR undefined_function THEN NULL;
  END;
END
$negative$;
RESET SESSION AUTHORIZATION;

-- The evaluator can use the typed public decision API but cannot administer policy.
SELECT risk_subject_create('CUSTOMER', 'stack-security-customer') AS security_subject \gset
SET SESSION AUTHORIZATION risk_evaluator;
SELECT status FROM risk_evaluate(:'security_subject', 'DEPOSIT', 'USD 1.00'::money_with_currency);
DO $negative$
BEGIN
  BEGIN
    PERFORM risk_policy_create('forged-policy', 'DEPOSIT');
    ASSERT false, 'risk evaluator created policy';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END
$negative$;
RESET SESSION AUTHORIZATION;
