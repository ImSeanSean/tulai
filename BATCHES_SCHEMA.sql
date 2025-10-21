-- Create batches table with start_year and end_year
CREATE TABLE IF NOT EXISTS batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    start_year INT NOT NULL,
    end_year INT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Only one batch should be active at a time (enforced in app logic)

-- Add batch_id to pending_submissions
ALTER TABLE pending_submissions ADD COLUMN IF NOT EXISTS batch_id UUID REFERENCES batches(id);

-- Add batch_id to students
ALTER TABLE students ADD COLUMN IF NOT EXISTS batch_id UUID REFERENCES batches(id);

-- Policy: Allow select/insert/update for authenticated users
ALTER TABLE batches ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all for authenticated" ON batches FOR ALL TO authenticated USING (true) WITH CHECK (true);
