# Cleanup Functionality

This document describes the new cleanup functionality that has been added to the Dendreo sync process to remove participants and courses that are no longer active.

## Overview

The backend now includes comprehensive cleanup functionality that removes:

1. **Removed Participants**: Participants who are no longer enrolled in specific courses
2. **Orphaned Participants**: Participants who are no longer enrolled in any courses
3. **Orphaned Courses**: Courses that are no longer active in the system

## Cleanup Process

The cleanup process runs automatically during each sync operation and includes the following steps:

### 1. Removed Participants Cleanup (`_cleanup_removed_participants`)

This method removes participants who are no longer enrolled in specific courses:

- Compares current participant-course combinations with existing records
- Removes associated modules first (due to foreign key constraints)
- Removes participant-course enrollment records
- Updates statistics tracking

### 2. Orphaned Participants Cleanup (`_cleanup_orphaned_participants`)

This method removes participants who are no longer enrolled in any courses:

- Finds participants with no remaining participant-course records
- Removes associated HubSpot data first
- Removes the participant record
- Updates statistics tracking

### 3. Orphaned Courses Cleanup (`_cleanup_orphaned_courses`)

This method removes courses that are no longer active:

- Compares current active courses with existing course records
- Removes associated modules first (due to foreign key constraints)
- Removes associated participant-course records
- Removes the course record
- Updates statistics tracking

## Statistics Tracking

The cleanup process tracks the following statistics:

- `participants_removed`: Number of orphaned participants removed
- `participant_courses_removed`: Number of participant-course enrollments removed
- `courses_removed`: Number of orphaned courses removed
- `modules_removed`: Number of modules removed during cleanup

## Integration with Sync Process

The cleanup process is integrated into the main sync workflow:

1. **Process ADFs**: Create/update active courses
2. **Process LMPs**: Create/update modules and participant enrollments
3. **Process HubSpot Data**: Update participant-course records with HubSpot data
4. **Cleanup Removed Participants**: Remove participants no longer in courses
5. **Cleanup Orphaned Participants**: Remove participants not enrolled in any courses
6. **Cleanup Orphaned Courses**: Remove courses no longer active
7. **Update HubSpot Deals**: Update progression data in HubSpot

## Testing

A test script has been created to verify the cleanup functionality:

```bash
python3 back/test_cleanup_functionality.py
```

This script:
- Creates test data (participants, courses, modules, enrollments)
- Tests each cleanup method individually
- Verifies that the correct records are removed
- Cleans up test data after testing

## Configuration

The cleanup process is enabled by default and runs automatically during each sync operation. No additional configuration is required.

## Logging

The cleanup process provides detailed logging:

- Information about each record being removed
- Summary statistics after cleanup
- Error handling with rollback on failures

## Safety Features

The cleanup process includes several safety features:

- **Conservative Approach**: Only removes participants/courses that have no modules
- **Foreign Key Handling**: Removes child records before parent records
- **Transaction Rollback**: Rolls back changes on errors
- **Detailed Logging**: Logs all operations for audit purposes
- **Statistics Tracking**: Tracks all cleanup operations
- **Module-Based Validation**: Validates that participants/courses have no modules before removal

## API Response

The sync API endpoints now include cleanup statistics in their responses:

```json
{
  "status": "success",
  "message": "Sync completed successfully",
  "stats": {
    "participants_created": 10,
    "participants_updated": 5,
    "participants_removed": 2,
    "courses_created": 3,
    "courses_updated": 1,
    "courses_removed": 1,
    "modules_created": 25,
    "modules_updated": 15,
    "modules_removed": 8,
    "participant_courses_created": 12,
    "participant_courses_updated": 6,
    "participant_courses_removed": 3
  }
}
```

## Monitoring

Monitor the cleanup process through:

1. **Sync Logs**: Check sync logs for cleanup messages
2. **API Statistics**: Review sync API responses for cleanup stats
3. **Database Queries**: Monitor database for removed records

## Troubleshooting

If cleanup issues occur:

1. **Check Logs**: Review sync logs for error messages
2. **Verify Foreign Keys**: Ensure proper foreign key relationships
3. **Test Cleanup**: Run the test script to verify functionality
4. **Database Backup**: Always backup before major sync operations
5. **Analyze Removals**: Run `python3 back/restore_removed_participants.py` to analyze what was removed
6. **Restore from Backup**: If participants were incorrectly removed, restore from database backup

## Future Enhancements

Potential future enhancements:

- **Configurable Cleanup**: Allow enabling/disabling specific cleanup types
- **Dry Run Mode**: Test cleanup without making changes
- **Selective Cleanup**: Clean up specific courses or participants
- **Cleanup Scheduling**: Run cleanup independently of sync process 