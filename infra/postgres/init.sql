-- Create the pgcrypto extension to automatically generate UUIDs
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Parent table: Original music track records
CREATE TABLE IF NOT EXISTS tracks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    artist VARCHAR(255),
    sample_rate INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Child table: Music chunks (Go extractor will process these)
CREATE TABLE IF NOT EXISTS chunks (
    id UUID PRIMARY KEY, -- The UUID will come from the Python Producer
    track_id UUID REFERENCES tracks(id) ON DELETE CASCADE,
    storage_url VARCHAR(512) NOT NULL, -- Where the file lives in MinIO
    start_time FLOAT, -- In seconds
    end_time FLOAT,   -- In seconds
    status VARCHAR(50) DEFAULT 'pending', -- pending, processing, completed, failed
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Grandchild table: Extracted features (The result from the Go extractor)
CREATE TABLE IF NOT EXISTS chunk_features (
    chunk_id UUID PRIMARY KEY REFERENCES chunks(id) ON DELETE CASCADE,
    tempo_bpm FLOAT,
    zero_crossing_rate FLOAT,
    spectral_centroid FLOAT,
    rms_energy FLOAT,
    mfcc FLOAT[], -- Array for more complex features (like spectrograms)
    extracted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes to improve performance for the future Python API
CREATE INDEX idx_chunks_track_id ON chunks(track_id);
CREATE INDEX idx_chunks_status ON chunks(status);