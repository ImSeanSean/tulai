# Database Schema: pending_submissions Table

## SQL Migration

Run this SQL in your Supabase SQL Editor to create the `pending_submissions` table:

```sql
-- Create pending_submissions table
CREATE TABLE IF NOT EXISTS pending_submissions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    last_name TEXT,
    first_name TEXT,
    middle_name TEXT,
    name_extension TEXT,
    house_street_sitio TEXT,
    barangay TEXT,
    municipality_city TEXT,
    province TEXT,
    birthdate TEXT,
    sex TEXT,
    place_of_birth TEXT,
    civil_status TEXT,
    religion TEXT,
    ethnic_group TEXT,
    mother_tongue TEXT,
    contact_number TEXT,
    is_pwd BOOLEAN DEFAULT false,
    father_last_name TEXT,
    father_first_name TEXT,
    father_middle_name TEXT,
    father_occupation TEXT,
    mother_last_name TEXT,
    mother_first_name TEXT,
    mother_middle_name TEXT,
    mother_occupation TEXT,
    last_school_attended TEXT,
    last_grade_level_completed TEXT,
    reason_for_incomplete_schooling TEXT,
    has_attended_als BOOLEAN DEFAULT false,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Add RLS (Row Level Security) policies
ALTER TABLE pending_submissions ENABLE ROW LEVEL SECURITY;

-- Policy: Allow insert for anyone (students submitting forms)
CREATE POLICY "Allow insert for anyone"
    ON pending_submissions
    FOR INSERT
    TO public
    WITH CHECK (true);

-- Policy: Allow select for authenticated teachers/admins
CREATE POLICY "Allow select for authenticated users"
    ON pending_submissions
    FOR SELECT
    TO authenticated
    USING (true);

-- Policy: Allow delete for authenticated teachers/admins
CREATE POLICY "Allow delete for authenticated users"
    ON pending_submissions
    FOR DELETE
    TO authenticated
    USING (true);

-- Create index for faster queries
CREATE INDEX idx_pending_submissions_submitted_at ON pending_submissions(submitted_at DESC);
CREATE INDEX idx_pending_submissions_name ON pending_submissions(last_name, first_name);
```

## Table Structure

### Fields:

- **id** (UUID): Primary key, auto-generated
- **Personal Information**: last_name, first_name, middle_name, name_extension
- **Address**: house_street_sitio, barangay, municipality_city, province
- **Personal Details**: birthdate, sex, place_of_birth, civil_status, religion, ethnic_group, mother_tongue, contact_number, is_pwd
- **Father/Guardian**: father_last_name, father_first_name, father_middle_name, father_occupation
- **Mother/Guardian**: mother_last_name, mother_first_name, mother_middle_name, mother_occupation
- **Education**: last_school_attended, last_grade_level_completed, reason_for_incomplete_schooling, has_attended_als
- **Timestamps**: submitted_at, created_at

### Security:

- **RLS Enabled**: Row Level Security is enabled
- **Insert Policy**: Anyone can insert (public access for student submissions)
- **Select Policy**: Only authenticated users (teachers/admins) can view
- **Delete Policy**: Only authenticated users (teachers/admins) can delete

## Workflow

1. **Student Submission**:

   - Student fills out enrollment form
   - Data is inserted into `pending_submissions` table
   - Student sees success message

2. **Teacher Review**:

   - Teacher navigates to "Pending Submissions" in dashboard
   - Reviews all pending submissions
   - Clicks "Review" button to see detailed view

3. **Teacher Approval**:

   - Teacher edits/corrects any information
   - Validates all required fields
   - Clicks "Approve & Add Student"
   - Data is moved from `pending_submissions` to `students` table
   - Original pending submission is deleted

4. **Alternative: Delete**:
   - Teacher can delete invalid/duplicate submissions
   - Confirmation dialog before deletion

## Features

- **Search**: Search pending submissions by student name
- **Sort**: Automatically sorted by submission date (newest first)
- **Edit Before Approval**: Teachers can correct any mistakes before adding to main database
- **Field Validation**: Required fields are marked and validated
- **Warning Indicators**: Missing required fields show warning icons
- **Two-column Layout**: Desktop view shows fields in 2 columns for efficient editing
