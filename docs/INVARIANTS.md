# Stack invariants

`just validate-stack` runs each extension validator and the cross-stack checks
in `sql/invariants/full_stack.sql`. Every major workload must end with all rows
at `status = OK`.

The stack requires:

- every ledger transaction balances independently by full asset identity;
- cached balances equal immutable entry history and account versions remain valid;
- crypto ticker, network, and contract identity survive every adapter path;
- one executed FX quote maps to no more than one ledger financial effect;
- a denied risk decision cannot commit financial movement;
- reconciliation reads ledger history but never mutates it;
- manual reconciliation and risk decisions remain append-only and policy-versioned;
- conversion chains preserve exact smallest units and never use floating point;
- matching idempotency keys resolve to one canonical financial transaction;
- benchmark throughput is invalid when any validator fails.

Extension validators remain authoritative for extension-local invariants. The
stack runner composes their results rather than duplicating their algorithms.

