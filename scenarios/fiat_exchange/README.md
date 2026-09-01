# Canonical fiat exchange

This deterministic scenario is the v0.1 acceptance test. It prices a USD/EUR
quote, persists an ALLOW decision, atomically posts exact USD/EUR and fee legs,
executes the quote once, and reconciles the resulting customer USD balance.

Run it through `just test pg18`; the runner keeps all four files in one psql
session because setup variables are promoted to session settings.
