# Phase 1.5 QA Checklist

- Timezone change: existing `localDay` logs do not re-bucket when device timezone changes.
- DST boundary: toggling a completion on DST transition day keeps the correct local day.
- Schedule updates: changing schedule mask immediately updates streaks and XP deterministically.
- History edits: backdating and removing completions recompute XP/streaks correctly.
- Stats performance: stats page stays responsive with 50+ habits and 6+ months of logs.
- Battles determinism: weekly/monthly progress changes only with log changes (no manual events).
