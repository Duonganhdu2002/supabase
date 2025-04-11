-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ENUM TABLES

-- User roles enum table
CREATE TABLE user_roles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(20) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default user roles (chỉ giữ admin và creator)
INSERT INTO user_roles (name, description) VALUES
  ('admin', 'Full access to all system features'),
  ('creator', 'Can create and manage content');

-- Content status enum table
CREATE TABLE content_statuses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(20) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default content statuses
INSERT INTO content_statuses (name, description) VALUES
  ('draft', 'Content that is still being worked on'),
  ('review', 'Content pending review before publishing'),
  ('published', 'Content that is live and publicly visible'),
  ('archived', 'Content that has been removed from public view');

-- Contact submission status enum table
CREATE TABLE submission_statuses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(20) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default submission statuses
INSERT INTO submission_statuses (name, description) VALUES
  ('unread', 'New submission that has not been viewed'),
  ('read', 'Submission that has been viewed but not responded to'),
  ('responded', 'Submission that has been responded to'),
  ('archived', 'Submission that has been processed and archived');

-- Activity log action types
CREATE TABLE action_types (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(20) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default action types
INSERT INTO action_types (name, description) VALUES
  ('create', 'Resource was created'),
  ('update', 'Resource was updated'),
  ('delete', 'Resource was deleted'),
  ('publish', 'Resource was published'),
  ('unpublish', 'Resource was unpublished'),
  ('archive', 'Resource was archived');

-- USERS TABLE (chỉ có admin và creator)
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) NOT NULL UNIQUE,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  role_id UUID NOT NULL REFERENCES user_roles(id) ON DELETE RESTRICT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role_id ON users(role_id);

-- SERVICES TABLE
CREATE TABLE services (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) NOT NULL,
  slug VARCHAR(100) NOT NULL UNIQUE,
  description TEXT NOT NULL,
  icon VARCHAR(50),
  is_published BOOLEAN DEFAULT true,
  sort_order SMALLINT DEFAULT 0,
  created_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_services_slug ON services(slug);
CREATE INDEX idx_services_is_published ON services(is_published);
CREATE INDEX idx_services_created_by ON services(created_by_user_id);

-- TEAM MEMBERS TABLE
CREATE TABLE team_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) NOT NULL,
  role VARCHAR(100) NOT NULL,
  bio TEXT,
  avatar_url TEXT,
  email VARCHAR(255),
  social_links JSONB,
  is_published BOOLEAN DEFAULT true,
  sort_order SMALLINT DEFAULT 0,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  created_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_team_members_is_published ON team_members(is_published);
CREATE INDEX idx_team_members_user_id ON team_members(user_id);
CREATE INDEX idx_team_members_created_by ON team_members(created_by_user_id);

-- TAGS TABLE
CREATE TABLE tags (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(50) NOT NULL UNIQUE,
  slug VARCHAR(50) NOT NULL UNIQUE,
  created_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tags_slug ON tags(slug);
CREATE INDEX idx_tags_created_by ON tags(created_by_user_id);

-- PROJECTS TABLE
CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title VARCHAR(100) NOT NULL,
  slug VARCHAR(100) NOT NULL UNIQUE,
  summary TEXT NOT NULL,
  content TEXT NOT NULL,
  client_name VARCHAR(100),
  completed_date DATE,
  featured_image_url TEXT,
  gallery_images JSONB,
  meta_title VARCHAR(100),
  meta_description VARCHAR(160),
  is_published BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
  sort_order SMALLINT DEFAULT 0,
  status_id UUID NOT NULL REFERENCES content_statuses(id) ON DELETE RESTRICT,
  locale VARCHAR(10) DEFAULT 'en',
  structured_data JSONB,
  created_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_projects_slug ON projects(slug);
CREATE INDEX idx_projects_is_published ON projects(is_published);
CREATE INDEX idx_projects_is_featured ON projects(is_featured);
CREATE INDEX idx_projects_status_id ON projects(status_id);
CREATE INDEX idx_projects_created_at ON projects(created_at);
CREATE INDEX idx_projects_locale ON projects(locale);
CREATE INDEX idx_projects_created_by ON projects(created_by_user_id);

-- PROJECTS_SERVICES JUNCTION TABLE
CREATE TABLE projects_services (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  service_id UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(project_id, service_id)
);

CREATE INDEX idx_projects_services_project_id ON projects_services(project_id);
CREATE INDEX idx_projects_services_service_id ON projects_services(service_id);

-- PROJECTS_TAGS JUNCTION TABLE
CREATE TABLE projects_tags (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(project_id, tag_id)
);

CREATE INDEX idx_projects_tags_project_id ON projects_tags(project_id);
CREATE INDEX idx_projects_tags_tag_id ON projects_tags(tag_id);

-- BLOG POSTS TABLE
CREATE TABLE blog_posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title VARCHAR(100) NOT NULL,
  slug VARCHAR(100) NOT NULL UNIQUE,
  summary TEXT NOT NULL,
  content TEXT NOT NULL,
  featured_image_url TEXT,
  author_id UUID NOT NULL REFERENCES team_members(id) ON DELETE RESTRICT,
  meta_title VARCHAR(100),
  meta_description VARCHAR(160),
  is_published BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
  status_id UUID NOT NULL REFERENCES content_statuses(id) ON DELETE RESTRICT,
  locale VARCHAR(10) DEFAULT 'en',
  structured_data JSONB,
  reading_time SMALLINT,
  created_by_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  published_at TIMESTAMPTZ
);

CREATE INDEX idx_blog_posts_slug ON blog_posts(slug);
CREATE INDEX idx_blog_posts_author_id ON blog_posts(author_id);
CREATE INDEX idx_blog_posts_is_published ON blog_posts(is_published);
CREATE INDEX idx_blog_posts_is_featured ON blog_posts(is_featured);
CREATE INDEX idx_blog_posts_status_id ON blog_posts(status_id);
CREATE INDEX idx_blog_posts_created_at ON blog_posts(created_at);
CREATE INDEX idx_blog_posts_published_at ON blog_posts(published_at);
CREATE INDEX idx_blog_posts_locale ON blog_posts(locale);
CREATE INDEX idx_blog_posts_created_by ON blog_posts(created_by_user_id);

-- BLOG_POSTS_TAGS JUNCTION TABLE
CREATE TABLE blog_posts_tags (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  blog_post_id UUID NOT NULL REFERENCES blog_posts(id) ON DELETE CASCADE,
  tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(blog_post_id, tag_id)
);

CREATE INDEX idx_blog_posts_tags_blog_post_id ON blog_posts_tags(blog_post_id);
CREATE INDEX idx_blog_posts_tags_tag_id ON blog_posts_tags(tag_id);

-- CONTACT SUBMISSIONS TABLE (duy nhất bảng này người dùng thông thường có thể tương tác)
CREATE TABLE contact_submissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  message TEXT NOT NULL,
  company VARCHAR(100),
  service_interest UUID REFERENCES services(id) ON DELETE SET NULL,
  status_id UUID NOT NULL REFERENCES submission_statuses(id) ON DELETE RESTRICT,
  assigned_to_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_contact_submissions_email ON contact_submissions(email);
CREATE INDEX idx_contact_submissions_status_id ON contact_submissions(status_id);
CREATE INDEX idx_contact_submissions_created_at ON contact_submissions(created_at);
CREATE INDEX idx_contact_submissions_service_interest ON contact_submissions(service_interest);
CREATE INDEX idx_contact_submissions_assigned_to ON contact_submissions(assigned_to_user_id);

-- SITE_VISITS TABLE for tracking visitors
CREATE TABLE site_visits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  visitor_id VARCHAR(100) NOT NULL, -- Anonymous identifier (cookie or fingerprint)
  ip_address VARCHAR(45),
  user_agent TEXT,
  referrer_url TEXT,
  landing_page TEXT NOT NULL,
  country VARCHAR(2),
  region VARCHAR(100),
  city VARCHAR(100),
  browser VARCHAR(50),
  browser_version VARCHAR(50),
  os VARCHAR(50),
  os_version VARCHAR(50),
  device_type VARCHAR(20), -- 'mobile', 'tablet', 'desktop'
  is_bot BOOLEAN DEFAULT false,
  first_visit_at TIMESTAMPTZ DEFAULT NOW(),
  last_visit_at TIMESTAMPTZ DEFAULT NOW(),
  visit_count INTEGER DEFAULT 1,
  utm_source VARCHAR(100),
  utm_medium VARCHAR(100),
  utm_campaign VARCHAR(100),
  utm_term VARCHAR(100),
  utm_content VARCHAR(100),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL, -- Only set if user is logged in
  created_at TIMESTAMPTZ DEFAULT NOW()
) PARTITION BY RANGE (first_visit_at);

-- Create partitions for April and May 2025
CREATE TABLE site_visits_202504 PARTITION OF site_visits
    FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');
    
CREATE TABLE site_visits_202505 PARTITION OF site_visits
    FOR VALUES FROM ('2025-05-01') TO ('2025-06-01');

-- Recreate indexes on the partitioned table
CREATE INDEX idx_site_visits_visitor_id ON site_visits(visitor_id);
CREATE INDEX idx_site_visits_ip_address ON site_visits(ip_address);
CREATE INDEX idx_site_visits_first_visit_at ON site_visits(first_visit_at);
CREATE INDEX idx_site_visits_last_visit_at ON site_visits(last_visit_at);
CREATE INDEX idx_site_visits_country ON site_visits(country);
CREATE INDEX idx_site_visits_device_type ON site_visits(device_type);
CREATE INDEX idx_site_visits_user_id ON site_visits(user_id);
CREATE INDEX idx_site_visits_utm_source ON site_visits(utm_source);

-- PAGE_VIEWS TABLE for tracking individual page views
CREATE TABLE page_views (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  visit_id UUID NOT NULL REFERENCES site_visits(id) ON DELETE CASCADE,
  url_path TEXT NOT NULL,
  page_title TEXT,
  query_params JSONB,
  hash_fragment TEXT,
  time_on_page INTEGER, -- in seconds
  exit_page BOOLEAN DEFAULT false,
  previous_page_id UUID REFERENCES page_views(id) ON DELETE SET NULL,
  events JSONB, -- Stores events triggered on the page (clicks, form submissions, etc.)
  created_at TIMESTAMPTZ DEFAULT NOW()
) PARTITION BY RANGE (created_at);

-- Create partitions for April and May 2025
CREATE TABLE page_views_202504 PARTITION OF page_views
    FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');
    
CREATE TABLE page_views_202505 PARTITION OF page_views
    FOR VALUES FROM ('2025-05-01') TO ('2025-06-01');

-- Recreate indexes on the partitioned table
CREATE INDEX idx_page_views_visit_id ON page_views(visit_id);
CREATE INDEX idx_page_views_url_path ON page_views(url_path);
CREATE INDEX idx_page_views_created_at ON page_views(created_at);
CREATE INDEX idx_page_views_exit_page ON page_views(exit_page);
CREATE INDEX idx_page_views_time_on_page ON page_views(time_on_page);

-- ACTIVITY LOGS TABLE for tracking content changes
CREATE TABLE activity_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  entity_type VARCHAR(50) NOT NULL, -- 'blog_post', 'project', etc.
  entity_id UUID NOT NULL,
  action_type_id UUID NOT NULL REFERENCES action_types(id) ON DELETE RESTRICT,
  changes JSONB, -- Stores the changes made (old/new values)
  ip_address VARCHAR(45),
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
) PARTITION BY RANGE (created_at);

-- Create partitions for April and May 2025
CREATE TABLE activity_logs_202504 PARTITION OF activity_logs
    FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');
    
CREATE TABLE activity_logs_202505 PARTITION OF activity_logs
    FOR VALUES FROM ('2025-05-01') TO ('2025-06-01');

-- Recreate indexes on the partitioned table
CREATE INDEX idx_activity_logs_user_id ON activity_logs(user_id);
CREATE INDEX idx_activity_logs_entity_type ON activity_logs(entity_type);
CREATE INDEX idx_activity_logs_entity_id ON activity_logs(entity_id);
CREATE INDEX idx_activity_logs_action_type_id ON activity_logs(action_type_id);
CREATE INDEX idx_activity_logs_created_at ON activity_logs(created_at);

-- Function to get the author name from team_members table
CREATE OR REPLACE FUNCTION get_blog_author_name(post_id UUID)
RETURNS TEXT AS $$
DECLARE
  author_name TEXT;
  author_id UUID;
BEGIN
  -- Get the author id
  SELECT bp.author_id INTO author_id
  FROM blog_posts bp
  WHERE bp.id = post_id;
  
  -- Get author name from team_members
  SELECT tm.name INTO author_name 
  FROM team_members tm 
  WHERE tm.id = author_id;
  
  RETURN author_name;
END;
$$ LANGUAGE plpgsql;

-- Function to get tags for a blog post as an array
CREATE OR REPLACE FUNCTION get_blog_post_tags(post_id UUID)
RETURNS TEXT[] AS $$
DECLARE
  tag_names TEXT[];
BEGIN
  SELECT array_agg(t.name) INTO tag_names
  FROM blog_posts_tags bpt
  JOIN tags t ON bpt.tag_id = t.id
  WHERE bpt.blog_post_id = post_id;
  
  RETURN tag_names;
END;
$$ LANGUAGE plpgsql;

-- Function to get tags for a project as an array
CREATE OR REPLACE FUNCTION get_project_tags(project_id UUID)
RETURNS TEXT[] AS $$
DECLARE
  tag_names TEXT[];
BEGIN
  SELECT array_agg(t.name) INTO tag_names
  FROM projects_tags pt
  JOIN tags t ON pt.tag_id = t.id
  WHERE pt.project_id = project_id;
  
  RETURN tag_names;
END;
$$ LANGUAGE plpgsql;

-- Function to get services for a project as an array
CREATE OR REPLACE FUNCTION get_project_services(project_id UUID)
RETURNS TEXT[] AS $$
DECLARE
  service_names TEXT[];
BEGIN
  SELECT array_agg(s.name) INTO service_names
  FROM projects_services ps
  JOIN services s ON ps.service_id = s.id
  WHERE ps.project_id = project_id;
  
  RETURN service_names;
END;
$$ LANGUAGE plpgsql;

-- VIEW: Comprehensive Blog Posts View
CREATE VIEW view_blog_posts AS
SELECT 
  bp.id,
  bp.title,
  bp.slug,
  bp.summary,
  bp.content,
  bp.featured_image_url,
  bp.author_id,
  tm.name AS author_name,
  bp.meta_title,
  bp.meta_description,
  bp.is_published,
  bp.is_featured,
  bp.status_id,
  cs.name AS status_name,
  cs.description AS status_description,
  bp.locale,
  bp.reading_time,
  bp.structured_data,
  get_blog_post_tags(bp.id) AS tags,
  bp.created_by_user_id,
  u.email AS creator_email,
  CONCAT(u.first_name, ' ', u.last_name) AS creator_name,
  bp.created_at,
  bp.updated_at,
  bp.published_at
FROM 
  blog_posts bp
JOIN 
  content_statuses cs ON bp.status_id = cs.id
JOIN 
  team_members tm ON bp.author_id = tm.id
JOIN 
  users u ON bp.created_by_user_id = u.id;

-- VIEW: Comprehensive Projects View
CREATE VIEW view_projects AS
SELECT 
  p.id,
  p.title,
  p.slug,
  p.summary,
  p.content,
  p.client_name,
  p.completed_date,
  p.featured_image_url,
  p.gallery_images,
  p.meta_title,
  p.meta_description,
  p.is_published,
  p.is_featured,
  p.sort_order,
  p.status_id,
  cs.name AS status_name,
  cs.description AS status_description,
  p.locale,
  p.structured_data,
  get_project_tags(p.id) AS tags,
  get_project_services(p.id) AS services,
  p.created_by_user_id,
  u.email AS creator_email,
  CONCAT(u.first_name, ' ', u.last_name) AS creator_name,
  p.created_at,
  p.updated_at
FROM 
  projects p
JOIN 
  content_statuses cs ON p.status_id = cs.id
LEFT JOIN 
  users u ON p.created_by_user_id = u.id;

-- VIEW: Contact Submissions with Status Name
CREATE VIEW view_contact_submissions AS
SELECT
  cs.id,
  cs.name,
  cs.email,
  cs.phone,
  cs.message,
  cs.company,
  cs.service_interest,
  s.name AS service_name,
  cs.status_id,
  ss.name AS status_name,
  cs.assigned_to_user_id,
  CONCAT(u.first_name, ' ', u.last_name) AS assigned_to_name,
  cs.created_at,
  cs.updated_at
FROM
  contact_submissions cs
LEFT JOIN
  services s ON cs.service_interest = s.id
JOIN
  submission_statuses ss ON cs.status_id = ss.id
LEFT JOIN
  users u ON cs.assigned_to_user_id = u.id;

-- TRIGGERS FOR AUTOMATIC UPDATED_AT UPDATES

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to log activity
CREATE OR REPLACE FUNCTION log_activity()
RETURNS TRIGGER AS $$
DECLARE
  action_type_uuid UUID;
  change_data JSONB;
  entity_type TEXT;
  user_id UUID;
BEGIN
  -- Determine entity type based on TG_TABLE_NAME
  entity_type := TG_TABLE_NAME;
  
  -- Get the authenticated user ID
  user_id := auth.uid();
  
  -- Default to NULL if no user is authenticated
  IF user_id IS NULL THEN
    user_id := NULL;
  END IF;
  
  -- Determine action type
  IF TG_OP = 'INSERT' THEN
    SELECT id INTO action_type_uuid FROM action_types WHERE name = 'create';
    change_data := jsonb_build_object('new', row_to_json(NEW));
  ELSIF TG_OP = 'UPDATE' THEN
    SELECT id INTO action_type_uuid FROM action_types WHERE name = 'update';
    change_data := jsonb_build_object('old', row_to_json(OLD), 'new', row_to_json(NEW));
    
    -- Special case for status changes (publish/unpublish)
    IF TG_TABLE_NAME IN ('blog_posts', 'projects') AND OLD.status_id != NEW.status_id THEN
      -- Check if status changed to 'published'
      IF NEW.status_id IN (SELECT id FROM content_statuses WHERE name = 'published') THEN
        SELECT id INTO action_type_uuid FROM action_types WHERE name = 'publish';
      -- Check if status changed from 'published' to something else
      ELSIF OLD.status_id IN (SELECT id FROM content_statuses WHERE name = 'published') THEN
        SELECT id INTO action_type_uuid FROM action_types WHERE name = 'unpublish';
      -- Check if status changed to 'archived'
      ELSIF NEW.status_id IN (SELECT id FROM content_statuses WHERE name = 'archived') THEN
        SELECT id INTO action_type_uuid FROM action_types WHERE name = 'archive';
      END IF;
    END IF;
  ELSIF TG_OP = 'DELETE' THEN
    SELECT id INTO action_type_uuid FROM action_types WHERE name = 'delete';
    change_data := jsonb_build_object('old', row_to_json(OLD));
  END IF;
  
  -- Insert into activity_logs
  INSERT INTO activity_logs(
    user_id, 
    entity_type, 
    entity_id, 
    action_type_id, 
    changes, 
    ip_address, 
    created_at
  )
  VALUES (
    user_id,
    entity_type,
    CASE WHEN TG_OP = 'DELETE' THEN OLD.id ELSE NEW.id END,
    action_type_uuid,
    change_data,
    NULL, -- IP address is not available in triggers
    NOW()
  );
  
  RETURN NULL; -- for AFTER triggers
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER update_users_modtime
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE PROCEDURE update_modified_column();

CREATE TRIGGER update_team_members_modtime
  BEFORE UPDATE ON team_members
  FOR EACH ROW
  EXECUTE PROCEDURE update_modified_column();

CREATE TRIGGER update_services_modtime
  BEFORE UPDATE ON services
  FOR EACH ROW
  EXECUTE PROCEDURE update_modified_column();

CREATE TRIGGER update_tags_modtime
  BEFORE UPDATE ON tags
  FOR EACH ROW
  EXECUTE PROCEDURE update_modified_column();

CREATE TRIGGER update_projects_modtime
  BEFORE UPDATE ON projects
  FOR EACH ROW
  EXECUTE PROCEDURE update_modified_column();

CREATE TRIGGER update_blog_posts_modtime
  BEFORE UPDATE ON blog_posts
  FOR EACH ROW
  EXECUTE PROCEDURE update_modified_column();

CREATE TRIGGER update_contact_submissions_modtime
  BEFORE UPDATE ON contact_submissions
  FOR EACH ROW
  EXECUTE PROCEDURE update_modified_column();

-- Create triggers for activity logging
CREATE TRIGGER log_blog_posts_activity
  AFTER INSERT OR UPDATE OR DELETE ON blog_posts
  FOR EACH ROW
  EXECUTE PROCEDURE log_activity();

CREATE TRIGGER log_projects_activity
  AFTER INSERT OR UPDATE OR DELETE ON projects
  FOR EACH ROW
  EXECUTE PROCEDURE log_activity();

CREATE TRIGGER log_services_activity
  AFTER INSERT OR UPDATE OR DELETE ON services
  FOR EACH ROW
  EXECUTE PROCEDURE log_activity();

CREATE TRIGGER log_team_members_activity
  AFTER INSERT OR UPDATE OR DELETE ON team_members
  FOR EACH ROW
  EXECUTE PROCEDURE log_activity();

-- RLS POLICIES FOR ACCESS CONTROL

-- Users table policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view all other users" ON users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins can update any profile" ON users FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM users u
    JOIN user_roles r ON u.role_id = r.id
    WHERE u.id = auth.uid() AND r.name = 'admin'
  )
);

-- Blog post policies
ALTER TABLE blog_posts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view published blog posts" ON blog_posts 
  FOR SELECT USING (
    is_published = true AND EXISTS (
      SELECT 1 FROM content_statuses s
      WHERE blog_posts.status_id = s.id AND s.name = 'published'
    )
  );
CREATE POLICY "Creators can CRUD their own blog posts" ON blog_posts 
  FOR ALL USING (auth.uid() = created_by_user_id);
CREATE POLICY "Admins can CRUD all blog posts" ON blog_posts 
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users u
      JOIN user_roles r ON u.role_id = r.id
      WHERE u.id = auth.uid() AND r.name = 'admin'
    )
  );

-- Projects policies
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view published projects" ON projects 
  FOR SELECT USING (
    is_published = true AND EXISTS (
      SELECT 1 FROM content_statuses s
      WHERE projects.status_id = s.id AND s.name = 'published'
    )
  );
CREATE POLICY "Creators can CRUD their own projects" ON projects 
  FOR ALL USING (auth.uid() = created_by_user_id);
CREATE POLICY "Admins can CRUD all projects" ON projects 
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users u
      JOIN user_roles r ON u.role_id = r.id
      WHERE u.id = auth.uid() AND r.name = 'admin'
    )
  );

-- Contact submissions policies
ALTER TABLE contact_submissions ENABLE ROW LEVEL SECURITY;
-- Cho phép bất kỳ ai cũng có thể gửi form liên hệ
CREATE POLICY "Anyone can submit contact form" ON contact_submissions FOR INSERT WITH CHECK (true);
-- Chỉ admin/creator mới có thể xem và cập nhật thông tin liên hệ
CREATE POLICY "Admins can view and update all submissions" ON contact_submissions 
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users u
      JOIN user_roles r ON u.role_id = r.id
      WHERE u.id = auth.uid() AND r.name = 'admin'
    )
  );
CREATE POLICY "Creators can view assigned submissions" ON contact_submissions 
  FOR SELECT USING (
    assigned_to_user_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM users u
      JOIN user_roles r ON u.role_id = r.id
      WHERE u.id = auth.uid() AND r.name = 'creator'
    )
  );
CREATE POLICY "Creators can update assigned submissions" ON contact_submissions 
  FOR UPDATE USING (
    assigned_to_user_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM users u
      JOIN user_roles r ON u.role_id = r.id
      WHERE u.id = auth.uid() AND r.name = 'creator'
    )
  );

-- Site visits and page views policies
ALTER TABLE site_visits ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins can view all site visits" ON site_visits
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users u
      JOIN user_roles r ON u.role_id = r.id
      WHERE u.id = auth.uid() AND r.name = 'admin'
    )
  );

ALTER TABLE page_views ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins can view all page views" ON page_views
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users u
      JOIN user_roles r ON u.role_id = r.id
      WHERE u.id = auth.uid() AND r.name = 'admin'
    )
  );

-- Function to aggregate page_views data for analytics
CREATE OR REPLACE FUNCTION get_daily_page_views(start_date DATE, end_date DATE)
RETURNS TABLE (
  date DATE,
  url_path TEXT,
  view_count BIGINT,
  avg_time_on_page NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    DATE(pv.created_at) AS date,
    pv.url_path,
    COUNT(*) AS view_count,
    AVG(pv.time_on_page)::NUMERIC AS avg_time_on_page
  FROM 
    page_views pv
  WHERE 
    DATE(pv.created_at) BETWEEN start_date AND end_date
  GROUP BY 
    DATE(pv.created_at),
    pv.url_path
  ORDER BY 
    date DESC, 
    view_count DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get visitor statistics
CREATE OR REPLACE FUNCTION get_visitor_stats(start_date DATE, end_date DATE)
RETURNS TABLE (
  date DATE,
  new_visitors BIGINT,
  returning_visitors BIGINT,
  total_visitors BIGINT,
  mobile_count BIGINT,
  tablet_count BIGINT,
  desktop_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    DATE(sv.created_at) AS date,
    COUNT(*) FILTER (WHERE sv.visit_count = 1) AS new_visitors,
    COUNT(*) FILTER (WHERE sv.visit_count > 1) AS returning_visitors,
    COUNT(*) AS total_visitors,
    COUNT(*) FILTER (WHERE sv.device_type = 'mobile') AS mobile_count,
    COUNT(*) FILTER (WHERE sv.device_type = 'tablet') AS tablet_count,
    COUNT(*) FILTER (WHERE sv.device_type = 'desktop') AS desktop_count
  FROM 
    site_visits sv
  WHERE 
    DATE(sv.created_at) BETWEEN start_date AND end_date
  GROUP BY 
    DATE(sv.created_at)
  ORDER BY 
    date DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to update the last_visit_at timestamp for site_visits
CREATE OR REPLACE FUNCTION update_site_visit()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_visit_at = NOW();
    NEW.visit_count = OLD.visit_count + 1;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_site_visit_timestamp
  BEFORE UPDATE ON site_visits
  FOR EACH ROW
  EXECUTE PROCEDURE update_site_visit(); 

-- Function to create monthly partitions for all partitioned tables
CREATE OR REPLACE FUNCTION create_monthly_partitions(
  months_ahead INTEGER DEFAULT 3
)
RETURNS void AS $$
DECLARE
  partition_date DATE;
  partition_start DATE;
  partition_end DATE;
  partition_name TEXT;
  current_month DATE := DATE_TRUNC('month', CURRENT_DATE);
BEGIN
  -- Loop through the specified number of months ahead
  FOR i IN 0..months_ahead LOOP
    -- Calculate the partition date (current month + i months)
    partition_date := current_month + (i || ' months')::INTERVAL;
    partition_start := DATE_TRUNC('month', partition_date);
    partition_end := partition_start + '1 month'::INTERVAL;
    
    -- Format for partition name: tablename_YYYYMM
    partition_name := TO_CHAR(partition_date, 'YYYYMM');
    
    -- Create site_visits partition if it doesn't exist
    IF NOT EXISTS (
      SELECT 1 FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE c.relname = 'site_visits_' || partition_name
    ) THEN
      EXECUTE format(
        'CREATE TABLE site_visits_%s PARTITION OF site_visits
         FOR VALUES FROM (%L) TO (%L)',
        partition_name, partition_start, partition_end
      );
      RAISE NOTICE 'Created partition site_visits_%', partition_name;
    END IF;
    
    -- Create page_views partition if it doesn't exist
    IF NOT EXISTS (
      SELECT 1 FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE c.relname = 'page_views_' || partition_name
    ) THEN
      EXECUTE format(
        'CREATE TABLE page_views_%s PARTITION OF page_views
         FOR VALUES FROM (%L) TO (%L)',
        partition_name, partition_start, partition_end
      );
      RAISE NOTICE 'Created partition page_views_%', partition_name;
    END IF;
    
    -- Create activity_logs partition if it doesn't exist
    IF NOT EXISTS (
      SELECT 1 FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE c.relname = 'activity_logs_' || partition_name
    ) THEN
      EXECUTE format(
        'CREATE TABLE activity_logs_%s PARTITION OF activity_logs
         FOR VALUES FROM (%L) TO (%L)',
        partition_name, partition_start, partition_end
      );
      RAISE NOTICE 'Created partition activity_logs_%', partition_name;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Example usage: Create partitions for the next 3 months (default)
-- SELECT create_monthly_partitions();

-- Example: Create partitions for the next 6 months
-- SELECT create_monthly_partitions(6);

-- Note: This function can be scheduled to run monthly using pg_cron extension:
-- Run this if you have pg_cron extension installed:
-- 
-- SELECT cron.schedule(
--   'monthly-partition-creation',
--   '0 0 1 * *',  -- At midnight on the 1st of every month
--   $$SELECT create_monthly_partitions(3)$$
-- ); 