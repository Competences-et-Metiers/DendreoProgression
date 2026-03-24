-- Migration 002: Create interventions table for staff intervention tracking
-- This table stores all staff actions (snooze, note, email, call, dismiss) on inactive participants

CREATE TABLE IF NOT EXISTS interventions (
    id SERIAL PRIMARY KEY,
    participant_id INTEGER NOT NULL REFERENCES participants(id),
    participant_course_id INTEGER REFERENCES participant_courses(id),
    id_action_formation VARCHAR,
    user_id INTEGER NOT NULL REFERENCES users(id),
    intervention_type VARCHAR(20) NOT NULL,
    details JSONB,
    hubspot_note_id VARCHAR,
    snooze_until TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_interventions_participant_id ON interventions(participant_id);
CREATE INDEX IF NOT EXISTS idx_interventions_participant_adf ON interventions(participant_id, id_action_formation);
CREATE INDEX IF NOT EXISTS idx_interventions_type ON interventions(intervention_type);
CREATE INDEX IF NOT EXISTS idx_interventions_snooze_until ON interventions(snooze_until);
CREATE INDEX IF NOT EXISTS idx_interventions_user_id ON interventions(user_id);

-- Prevent duplicate active dismissals for the same participant+ADF
CREATE UNIQUE INDEX IF NOT EXISTS idx_one_active_dismiss
    ON interventions(participant_id, id_action_formation)
    WHERE intervention_type = 'dismiss' AND is_active = TRUE;

-- Document columns
COMMENT ON TABLE interventions IS 'Staff intervention records for participant inactivity tracking';
COMMENT ON COLUMN interventions.intervention_type IS 'Type: snooze, note, email, call, dismiss';
COMMENT ON COLUMN interventions.details IS 'JSON payload specific to intervention type';
COMMENT ON COLUMN interventions.hubspot_note_id IS 'HubSpot note ID if intervention was pushed to HubSpot';
COMMENT ON COLUMN interventions.snooze_until IS 'Expiry date for snooze interventions';
COMMENT ON COLUMN interventions.is_active IS 'FALSE when a dismiss is reversed or snooze cancelled';

-- Verify
SELECT 'Migration 002 completed successfully' as status,
    EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'interventions') as table_exists;
