# Archived Scripts

This folder contains one-time scripts that were used during development but are no longer needed for daily operations.

## migrations/
Database migration scripts that have already been applied:
- `add_id_entreprise_column.py` - Added id_entreprise column to participants
- `add_planned_duration_column.py` - Added planned_duration_hours to courses
- `add_sync_metadata_table.py` - Created sync_metadata table
- `add_time_tracking_columns.py` - Added time tracking columns to modules
- `complete_time_duration_migration.py` - Completed time/duration migration
- `import_hubspot_ids.py` - One-time HubSpot ID import
- `restore_removed_participants.py` - One-time participant restoration
- `update_hubspot_progression.py` - One-time HubSpot progression update

## tests/
Ad-hoc test scripts used during development:
- `test_cleanup_functionality.py`
- `test_hubspot_connection.py`
- `test_id_entreprise.py`
- `test_sync_deployment_logic.py`
- `test_time_aggregation.py`

These scripts are kept for reference but should not be run in production.
