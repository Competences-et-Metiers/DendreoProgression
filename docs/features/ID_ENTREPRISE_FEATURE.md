# id_entreprise Feature Implementation

## Overview

This feature adds support for retrieving and storing the `id_entreprise` (company ID) of participants from laps queries. The `id_entreprise` field is now included in all participant-related API responses.

## Changes Made

### 1. Database Schema Changes

- **Participant Model**: Added `id_entreprise` column to the `participants` table
- **Migration Script**: Created `add_id_entreprise_column.py` to add the column to existing databases
- **Database Init**: Updated `database/init/01-init.sql` to include the column in new installations

### 2. Data Processing Updates

- **Dendreo Sync**: Updated `_process_lap_record()` to extract `id_entreprise` from laps data
- **Data Processor**: Updated `_process_participant()` to handle `id_entreprise` field
- **Participant Creation**: Updated `_get_or_create_participant()` to store `id_entreprise`

### 3. API Response Updates

- **Courses API**: Added `id_entreprise` to participant data in `/api/courses/courses` endpoint
- **Course Participants**: Added `id_entreprise` to participant data in `/api/courses/courses/{course_id}/participants` endpoint
- **Participant Details**: Added `id_entreprise` to participant data in `/api/courses/participants/{participant_id}` endpoint
- **Schemas**: Updated Pydantic schemas to include `id_entreprise` field

### 4. Data Source

The `id_entreprise` is extracted from laps data in two locations:
1. **Top-level**: `lap_record.get('id_entreprise')`
2. **Participant object**: `lap_record.get('participant', {}).get('id_entreprise')`

The implementation prioritizes the top-level `id_entreprise` value.

## API Response Format

All participant-related API responses now include the `id_entreprise` field:

```json
{
  "id": 123,
  "id_participant": "35",
  "nom": "HIESSE",
  "prenom": "Gaelle", 
  "email": "gaellehiesse@gmail.com",
  "id_entreprise": "35",
  "overall_progression": 75.5,
  "activity_status": "active"
}
```

## Migration Instructions

### For New Installations
The `id_entreprise` column is automatically included in new database installations.

### For Existing Installations
Run the migration script to add the column to existing databases:

```bash
cd back
python add_id_entreprise_column.py
```

## Testing

A test script is provided to verify the functionality:

```bash
cd back
python test_id_entreprise.py
```

This script tests:
1. Extraction of `id_entreprise` from sample laps data
2. Database storage and retrieval of `id_entreprise` values

## Database Schema

The participants table now includes:

```sql
CREATE TABLE participants (
    id SERIAL PRIMARY KEY,
    id_participant VARCHAR UNIQUE,
    nom VARCHAR,
    prenom VARCHAR,
    email VARCHAR,
    id_entreprise VARCHAR,  -- NEW COLUMN
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## Backward Compatibility

- The `id_entreprise` field is nullable, so existing data remains unaffected
- API responses gracefully handle missing `id_entreprise` values (returns `null`)
- Existing sync processes continue to work without modification

## Example Laps Data

The feature processes laps data like this:

```json
{
  "id_lap": "297",
  "id_entreprise": "35",  // Extracted from here
  "participant": {
    "id_participant": "35",
    "nom": "HIESSE",
    "prenom": "Gaelle",
    "email": "gaellehiesse@gmail.com",
    "id_entreprise": "35"  // Also available here
  }
}
```

The implementation extracts the top-level `id_entreprise` value and stores it with the participant record. 