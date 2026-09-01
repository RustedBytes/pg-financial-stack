# Security validation

The smoke fixture creates roles before extension installation so each extension
can grant its documented API permissions: application, market ingestion,
ledger reading, reconciliation ingestion/operation/admin, risk
evaluation/operation/admin, auditing, and an unprivileged caller.

`sql/security/roles.sql` verifies that an unprivileged user cannot mutate
ledger history, quote pricing, reconciliation results, or risk decisions. It
also checks that a risk evaluator can evaluate typed amounts without gaining
policy administration. `sql/security/search_path.sql` installs hostile objects
ahead of `public` and proves security-definer APIs still reach extension-owned
objects.

Tests must run as a disposable PostgreSQL superuser because they switch session
authorization. Never point the stack suite at a production database.

