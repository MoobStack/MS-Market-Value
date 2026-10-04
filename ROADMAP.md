# Beta roadmap

Public version remains **0.1.0-beta** until the first finalized release. Build001 implements the requested scan/store/tooltip/reference-estimate behavior and its local tests.

## Immediate next build inputs

1. Native startup/UI/tooltip and full-scan results from the user's Forever client.
2. Reload, relog, character-switch and full-exit/restart persistence results.
3. Material listing coverage and suffix-price checks.
4. Item-specific disenchant exceptions and observed material/quantity mismatches.

Address concrete failures in the next build under the same public beta version. Preserve complete-snapshot replacement and tested error behavior.

## Loot-model qualification

Build a Forever-specific evidence-backed dataset where available. Track each bracket's evidence separately, including new materials and exceptions. Add model overrides or additional profiles when observations require them. Continue labeling unverified outcomes until supported by representative data.

## Finalized first release

- Qualify the supported native client build, auction coverage and SavedVariables lifecycle.
- Fix reproducible UI, taint and coexistence issues.
- Publish accurate supported-client and model-coverage statements.
- Select a software license if desired and update notices before distribution.
- Review/tag exact final source; regenerate verified assets and checksums.
- Select the first finalized release version only at that point.

Automatic purchasing, selling, posting, disenchant execution, historical price databases and combat features are outside the requested initial scope.
