# Upgrade policy

Upgrade, dump/restore, binary golden values, and `pg_upgrade` automation are the
v0.2 scope defined by the specification. `scripts/run-upgrade-tests.sh` refuses
to run without both `PG_STACK_OLD_ARTIFACT_DIR` and
`PG_STACK_NEW_ARTIFACT_DIR`, preventing a normal current-version run from being
misreported as an upgrade test.

The required workflow is: install an exactly locked old stack, populate the
deterministic fixture, snapshot text/binary values and invariants, install new
binaries, run each `ALTER EXTENSION ... UPDATE`, then compare and validate. Major
migrations cover 14→15, 15→16, 16→17, and 17→18 where both artifact sets support
the endpoints.

