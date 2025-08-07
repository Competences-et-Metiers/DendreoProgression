-- Create database schema for DendreoProgression

-- The database will be created automatically by PostgreSQL using POSTGRES_DB environment variable
-- No need to create it manually - just connect to it

-- Participants table
CREATE TABLE IF NOT EXISTS participants (
    id SERIAL PRIMARY KEY,
    id_participant VARCHAR UNIQUE,
    nom VARCHAR,
    prenom VARCHAR,
    email VARCHAR,
    id_entreprise VARCHAR,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Courses table
CREATE TABLE IF NOT EXISTS courses (
    id SERIAL PRIMARY KEY,
    id_action_formation VARCHAR,
    id_lam VARCHAR,
    intitule VARCHAR,
    status VARCHAR,
    total_modules INTEGER DEFAULT 0,
    planned_duration_hours FLOAT DEFAULT 0.0,  -- Planned duration in hours from duree_heures
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT _adf_lam_uc UNIQUE (id_action_formation, id_lam)
);

-- Modules table
CREATE TABLE IF NOT EXISTS modules (
    id SERIAL PRIMARY KEY,
    id_lmp VARCHAR,
    id_lam VARCHAR,
    intitule VARCHAR,
    course_id INTEGER REFERENCES courses(id),
    participant_id INTEGER REFERENCES participants(id) NOT NULL,
    lms_progression FLOAT DEFAULT 0.0,
    lms_last_access_at TIMESTAMP WITH TIME ZONE,
    mode_organisation VARCHAR(50) DEFAULT 'elearning_async',
    -- Time tracking data
    lms_time_spent INTEGER DEFAULT 0,  -- Time spent in seconds
    lms_started_at TIMESTAMP WITH TIME ZONE,
    lms_completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT _lmp_participant_uc UNIQUE (id_lmp, participant_id)
);

-- Participant courses junction table
CREATE TABLE IF NOT EXISTS participant_courses (
    id SERIAL PRIMARY KEY,
    participant_id INTEGER REFERENCES participants(id),
    course_id INTEGER REFERENCES courses(id),
    id_lap VARCHAR,
    overall_progression FLOAT DEFAULT 0.0,
    activity_status VARCHAR(20) DEFAULT 'inactive',
    last_activity TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Participant HubSpot data table
CREATE TABLE IF NOT EXISTS participant_hubspot_data (
    id SERIAL PRIMARY KEY,
    participant_id INTEGER REFERENCES participants(id) NOT NULL,
    id_action_formation VARCHAR NOT NULL,
    id_lap VARCHAR,
    c_url_transaction_hubspot VARCHAR,
    c_id_transaction_hubspot VARCHAR,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT _participant_adf_uc UNIQUE (participant_id, id_action_formation)
);

-- Sync metadata table for tracking sync operations
CREATE TABLE IF NOT EXISTS sync_metadata (
    id SERIAL PRIMARY KEY,
    sync_type VARCHAR NOT NULL,
    last_sync_at TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR NOT NULL,
    stats TEXT,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_participants_id_participant ON participants(id_participant);
CREATE INDEX IF NOT EXISTS idx_courses_id_action_formation ON courses(id_action_formation);
CREATE INDEX IF NOT EXISTS idx_courses_id_lam ON courses(id_lam);
CREATE INDEX IF NOT EXISTS idx_modules_id_lmp ON modules(id_lmp);
CREATE INDEX IF NOT EXISTS idx_modules_participant_id ON modules(participant_id);
CREATE INDEX IF NOT EXISTS idx_modules_course_id ON modules(course_id);
CREATE INDEX IF NOT EXISTS idx_participant_courses_participant_id ON participant_courses(participant_id);
CREATE INDEX IF NOT EXISTS idx_participant_courses_course_id ON participant_courses(course_id);
CREATE INDEX IF NOT EXISTS idx_participant_hubspot_data_participant_id ON participant_hubspot_data(participant_id);
CREATE INDEX IF NOT EXISTS idx_sync_metadata_sync_type ON sync_metadata(sync_type);
CREATE INDEX IF NOT EXISTS idx_sync_metadata_last_sync_at ON sync_metadata(last_sync_at);
CREATE INDEX IF NOT EXISTS idx_sync_metadata_status ON sync_metadata(status);

-- Create indexes for new time tracking columns
CREATE INDEX IF NOT EXISTS idx_modules_lms_time_spent ON modules(lms_time_spent);
CREATE INDEX IF NOT EXISTS idx_modules_lms_started_at ON modules(lms_started_at);
CREATE INDEX IF NOT EXISTS idx_modules_lms_completed_at ON modules(lms_completed_at);

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers to automatically update updated_at timestamps
CREATE TRIGGER update_participants_updated_at BEFORE UPDATE ON participants FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_courses_updated_at BEFORE UPDATE ON courses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_modules_updated_at BEFORE UPDATE ON modules FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_participant_courses_updated_at BEFORE UPDATE ON participant_courses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_participant_hubspot_data_updated_at BEFORE UPDATE ON participant_hubspot_data FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_sync_metadata_updated_at BEFORE UPDATE ON sync_metadata FOR EACH ROW EXECUTE FUNCTION update_updated_at_column(); 