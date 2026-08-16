-- Migrations for AKSI Application Backend (Supabase)
-- Created at: 2026-08-06

-- 1. Create Tables

-- Table: email_reputations
CREATE TABLE email_reputations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email_address TEXT UNIQUE NOT NULL,
    domain TEXT NOT NULL,
    trust_score INTEGER DEFAULT 50 CHECK (trust_score >= 0 AND trust_score <= 100),
    is_verified_official BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Table: email_tags
CREATE TABLE email_tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email_id UUID REFERENCES email_reputations(id) ON DELETE CASCADE,
    tag_name TEXT NOT NULL,
    upvotes INTEGER DEFAULT 0,
    downvotes INTEGER DEFAULT 0,
    is_moderated BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (email_id, tag_name)
);

-- Table: community_reports
CREATE TABLE community_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    email_id UUID REFERENCES email_reputations(id) ON DELETE CASCADE,
    category_tag TEXT NOT NULL,
    evidence_url TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Setup Storage Bucket for Evidences
INSERT INTO storage.buckets (id, name, public) VALUES ('evidence_bucket', 'evidence_bucket', false);

-- 3. Database Functions & Triggers

-- Trigger: Auto-update updated_at for email_reputations
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_email_reputations_updated_at
BEFORE UPDATE ON email_reputations
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Function: Increment Upvote for a Tag safely
CREATE OR REPLACE FUNCTION increment_tag_upvote(tag_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE email_tags
    SET upvotes = upvotes + 1
    WHERE id = tag_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Increment Downvote for a Tag safely
CREATE OR REPLACE FUNCTION increment_tag_downvote(tag_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE email_tags
    SET downvotes = downvotes + 1
    WHERE id = tag_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 4. Row Level Security (RLS) Policies

-- Enable RLS on all tables
ALTER TABLE email_reputations ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_reports ENABLE ROW LEVEL SECURITY;

-- Policies for email_reputations
-- Anyone (Public & Authenticated) can read email reputations
CREATE POLICY "Public read access for email_reputations"
ON email_reputations FOR SELECT
TO public
USING (true);

-- Only authenticated users (Moderators) can insert/update/delete email reputations manually
-- Allow authenticated and public users to insert new email reputations when reporting
CREATE POLICY "Public users can insert email_reputations"
ON email_reputations FOR INSERT
TO public
WITH CHECK (true);

-- Policies for email_tags
-- Anyone can read tags
CREATE POLICY "Public read access for email_tags"
ON email_tags FOR SELECT
TO public
USING (true);

-- Authenticated and public users can insert new tags
CREATE POLICY "Public users can insert email_tags"
ON email_tags FOR INSERT
TO public
WITH CHECK (true);

-- Direct update disabled for public. Handled via increment RPC above.

-- Policies for community_reports
-- Reporter can see their own reports
CREATE POLICY "Public can view reports"
ON community_reports FOR SELECT
TO public
USING (true);

-- Auth and public users can insert reports
CREATE POLICY "Public users can insert community_reports"
ON community_reports FOR INSERT
TO public
WITH CHECK (true);

-- Storage Bucket Policies
CREATE POLICY "Public users can upload evidences"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'evidence_bucket');

-- Only reporters can view their evidences
CREATE POLICY "Public can view evidences"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'evidence_bucket');
