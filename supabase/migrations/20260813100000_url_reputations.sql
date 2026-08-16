CREATE TABLE url_reputations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    url TEXT UNIQUE NOT NULL,
    domain TEXT NOT NULL,
    category_tag TEXT NOT NULL,
    report_count INTEGER DEFAULT 1 CHECK (report_count >= 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TRIGGER update_url_reputations_updated_at
BEFORE UPDATE ON url_reputations
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE FUNCTION increment_url_report(target_url TEXT, category TEXT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO url_reputations (url, domain, category_tag)
    VALUES (
        target_url,
        SPLIT_PART(SPLIT_PART(target_url, '://', 2), '/', 1),
        category
    )
    ON CONFLICT (url)
    DO UPDATE SET report_count = url_reputations.report_count + 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

ALTER TABLE url_reputations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read access for url_reputations"
ON url_reputations FOR SELECT
TO public
USING (true);

CREATE POLICY "Public users can insert url_reputations"
ON url_reputations FOR INSERT
TO public
WITH CHECK (true);
