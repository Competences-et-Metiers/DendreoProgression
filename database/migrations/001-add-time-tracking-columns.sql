-- Migration: Add time tracking and planned duration columns
-- This script adds the new columns needed for time tracking functionality
-- Run this on your production database to add the new columns

-- Add planned_duration_hours column to courses table
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'courses' AND column_name = 'planned_duration_hours'
    ) THEN
        ALTER TABLE courses ADD COLUMN planned_duration_hours FLOAT DEFAULT 0.0;
        RAISE NOTICE 'Added planned_duration_hours column to courses table';
    ELSE
        RAISE NOTICE 'planned_duration_hours column already exists in courses table';
    END IF;
END $$;

-- Add time tracking columns to modules table
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'modules' AND column_name = 'lms_time_spent'
    ) THEN
        ALTER TABLE modules ADD COLUMN lms_time_spent INTEGER DEFAULT 0;
        RAISE NOTICE 'Added lms_time_spent column to modules table';
    ELSE
        RAISE NOTICE 'lms_time_spent column already exists in modules table';
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'modules' AND column_name = 'lms_started_at'
    ) THEN
        ALTER TABLE modules ADD COLUMN lms_started_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'Added lms_started_at column to modules table';
    ELSE
        RAISE NOTICE 'lms_started_at column already exists in modules table';
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'modules' AND column_name = 'lms_completed_at'
    ) THEN
        ALTER TABLE modules ADD COLUMN lms_completed_at TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'Added lms_completed_at column to modules table';
    ELSE
        RAISE NOTICE 'lms_completed_at column already exists in modules table';
    END IF;
END $$;

-- Create indexes for new time tracking columns (if they don't exist)
CREATE INDEX IF NOT EXISTS idx_modules_lms_time_spent ON modules(lms_time_spent);
CREATE INDEX IF NOT EXISTS idx_modules_lms_started_at ON modules(lms_started_at);
CREATE INDEX IF NOT EXISTS idx_modules_lms_completed_at ON modules(lms_completed_at);

-- Add comments to document the new columns
COMMENT ON COLUMN courses.planned_duration_hours IS 'Planned duration in hours from duree_heures field in Dendreo API';
COMMENT ON COLUMN modules.lms_time_spent IS 'Time spent in seconds by participant on this module';
COMMENT ON COLUMN modules.lms_started_at IS 'Timestamp when participant started this module';
COMMENT ON COLUMN modules.lms_completed_at IS 'Timestamp when participant completed this module';

-- Verify the migration
SELECT 
    'Migration completed successfully' as status,
    COUNT(*) as total_tables,
    SUM(CASE WHEN table_name = 'courses' THEN 1 ELSE 0 END) as courses_table_exists,
    SUM(CASE WHEN table_name = 'modules' THEN 1 ELSE 0 END) as modules_table_exists
FROM information_schema.tables 
WHERE table_name IN ('courses', 'modules') 
AND table_schema = 'public';

-- Show the new columns
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name IN ('courses', 'modules') 
AND column_name IN ('planned_duration_hours', 'lms_time_spent', 'lms_started_at', 'lms_completed_at')
ORDER BY table_name, column_name;
