# Adding an extension

1. Add its repository, default ref, and required flag to `stack/extensions.toml`.
2. Add compatible version ranges and every supported position to
   `stack/compatibility.toml`.
3. Ensure its Cargo features advertise every supported PostgreSQL major and its
   pgrx version matches the stack.
4. Add late-enablement calls and assertions to `sql/compatibility/adapters.sql`.
5. Add it to smoke installation and the representative order matrix.
6. Add cross-extension type, security, and invariant checks—without copying its
   local unit tests.
7. Add a deterministic scenario when it participates in a financial workflow.
8. Extend benchmark setup/workloads only for genuinely system-level behavior.
9. Exclude its Git cache path from the root Cargo workspace.
10. Update CI artifacts, architecture, and the test matrix.

The resolver iterates manifest entries, so no installer code change is needed
for a conventional pgrx extension. Non-pgrx or packaged-only extensions need an
explicit installer strategy before their manifest entry can be `required`.
