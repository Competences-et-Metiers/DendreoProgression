# Feature Proposals & Future Work

This document tracks proposed features and enhancements for the Dendreo Progression platform.

## On Hold

### Progression Delta Tracker
**Status:** On Hold
**Priority:** High (when resumed)
**Documentation:** [PROGRESSION_DELTA_TRACKER.md](./PROGRESSION_DELTA_TRACKER.md)

**Summary:** Track daily progression changes to identify "stagnant" users who log in regularly but don't make meaningful progress.

**Key Benefits:**
- Distinguish between "active" (logging in) and "progressing" (actually advancing)
- Enable targeted intervention for users who need help
- Better resource allocation for coaching staff
- Historical progression audit trail

**Implementation Estimate:** 4 weeks
- Week 1: Database foundation
- Week 2: Enhanced inactivity detection
- Week 3: Frontend integration
- Week 4: Optimization & monitoring

**Next Step:** Review [full documentation](./PROGRESSION_DELTA_TRACKER.md) when ready to implement.

---

## Implemented

### Inactive Management Page Enhancements
**Status:** ✅ Completed (2026-02-04)

**Phase 1 - Basic Features:**
- Sorting by inactivity, name, progression, status
- Status filtering (at risk, stalled, long inactive)
- Active users toggle with configurable days threshold
- localStorage persistence for all filters
- Clickable participant and course names
- All UI text in French

**Phase 2 - Data Aggregation & Filtering (2026-02-04):**
- **Fixed duplicate entries:** Participants now grouped by ADF (Action de Formation) instead of individual LAM modules
- **Aggregated metrics per ADF:**
  - Average progression across all modules
  - Total modules count
  - Total planned duration (sum of all LAM durations)
  - Total time spent (actual hours worked)
  - Most recent activity across all modules
- **Duration display:** Changed from "Xh prévues" to "Xh / Yh" format (actual/planned)
- **ADF filter:** Collapsible multi-select dropdown with search to filter by specific training programs
  - Searchable list of all ADFs
  - Select/deselect all option
  - Badge counter showing selected formations
  - Persistent selections in localStorage

---

## Proposed (Not Yet Planned)

*Add new proposals here as they arise*

---

**Last Updated:** 2026-02-04 (Phase 2 enhancements added)
