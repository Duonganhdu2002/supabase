# supabase
# GIẢI THÍCH CẤU TRÚC DATABASE CHO LANDING PAGE AGENCY

## 1. TỔNG QUAN

Database này được thiết kế cho landing page của một agency sáng tạo, với các tính năng:
- Quản lý nội dung (bài viết, dự án, dịch vụ)
- Hỗ trợ SEO tối ưu
- Theo dõi lịch sử thay đổi
- Quản lý người dùng và phân quyền
- Hỗ trợ đa ngôn ngữ (localization)
- Phân tích người dùng và hành vi truy cập

### Đặc điểm kỹ thuật:
- Sử dụng UUID làm khóa chính cho tất cả các bảng
- Áp dụng các nguyên tắc thiết kế chuẩn hóa
- Views tối ưu để hiển thị dữ liệu người dùng thân thiện
- Triggers tự động cập nhật và logging
- Row Level Security (RLS) để kiểm soát quyền truy cập
- JSONB cho phép lưu trữ dữ liệu có cấu trúc linh hoạt
- Hệ thống phân tích tích hợp để theo dõi và báo cáo hoạt động người dùng

## 2. CÁC BẢNG ENUM (LOOKUP TABLES)

Thay vì sử dụng CHECK constraints, database dùng các bảng riêng cho các giá trị enum.

### 2.1. Bảng `user_roles` - Vai trò người dùng
```sql
CREATE TABLE user_roles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(20) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Giá trị mặc định:**
- `admin`: Quản trị viên với quyền truy cập toàn bộ hệ thống
- `creator`: Người tạo nội dung, chỉ có thể quản lý nội dung của họ

**Ví dụ:**
```sql
-- Lấy danh sách người dùng với vai trò của họ
SELECT u.email, r.name AS role
FROM users u
JOIN user_roles r ON u.role_id = r.id;
```

### 2.2. Bảng `content_statuses` - Trạng thái nội dung
```sql
CREATE TABLE content_statuses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(20) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Giá trị mặc định:**
- `draft`: Bản nháp
- `review`: Đang chờ duyệt
- `published`: Đã xuất bản
- `archived`: Đã lưu trữ

**Ví dụ:**
```sql
-- Tìm tất cả bài viết đang ở trạng thái duyệt
SELECT bp.title, cs.name AS status
FROM blog_posts bp
JOIN content_statuses cs ON bp.status_id = cs.id
WHERE cs.name = 'review';
```

### 2.3. Bảng `submission_statuses` - Trạng thái liên hệ
```sql
CREATE TABLE submission_statuses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(20) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Giá trị mặc định:**
- `unread`: Chưa đọc
- `read`: Đã đọc
- `responded`: Đã phản hồi
- `archived`: Đã lưu trữ

### 2.4. Bảng `action_types` - Loại hành động (cho activity logs)
```sql
CREATE TABLE action_types (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(20) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Giá trị mặc định:**
- `create`: Tạo mới
- `update`: Cập nhật
- `delete`: Xóa
- `publish`: Xuất bản
- `unpublish`: Hủy xuất bản
- `archive`: Lưu trữ

## 3. CÁC BẢNG DỮ LIỆU CHÍNH

### 3.1. Bảng `users` - Người dùng hệ thống
```sql
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
```

**Ví dụ:**
```sql
-- Thêm người dùng mới với vai trò creator
INSERT INTO users (email, first_name, last_name, role_id)
VALUES ('nguyenvan@example.com', 'Văn', 'Nguyễn', 
        (SELECT id FROM user_roles WHERE name = 'creator'));
```

### 3.2. Bảng `services` - Dịch vụ của agency
```sql
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
```

**Ví dụ:**
```sql
-- Thêm một dịch vụ mới
INSERT INTO services (name, slug, description, icon, created_by_user_id)
VALUES ('Thiết kế web', 'thiet-ke-web', 'Dịch vụ thiết kế website chuyên nghiệp', 
        'web-design-icon', '550e8400-e29b-41d4-a716-446655440000');
```

### 3.3. Bảng `team_members` - Thành viên team
```sql
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
```

**Ví dụ:**
```sql
-- Thêm thành viên mới với liên kết mạng xã hội
INSERT INTO team_members (name, role, bio, social_links, user_id)
VALUES ('Minh Tuấn', 'Lead Designer', 'Chuyên gia thiết kế UI/UX với 5 năm kinh nghiệm',
        '{"facebook": "fb.com/minhtuan", "linkedin": "linkedin.com/in/minhtuan"}',
        '550e8400-e29b-41d4-a716-446655440000');
```

### 3.4. Bảng `tags` - Thẻ gắn cho bài viết/dự án
```sql
CREATE TABLE tags (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(50) NOT NULL UNIQUE,
  slug VARCHAR(50) NOT NULL UNIQUE,
  created_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 3.5. Bảng `projects` - Dự án đã thực hiện
```sql
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
```

**Ví dụ:**
```sql
-- Thêm dự án mới
INSERT INTO projects (title, slug, summary, content, client_name, meta_title, meta_description, status_id)
VALUES ('Website Công ty ABC', 'website-cong-ty-abc', 
        'Thiết kế website cho công ty ABC', 'Nội dung chi tiết về dự án...',
        'Công ty ABC', 'Website ABC | Dự án thiết kế web', 
        'Dự án thiết kế website cho công ty ABC với giao diện hiện đại',
        (SELECT id FROM content_statuses WHERE name = 'published'));
```

### 3.6. Bảng `blog_posts` - Bài viết blog
```sql
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
```

**Chi tiết đặc biệt:**
- `author_id`: Trực tiếp tham chiếu đến một thành viên team là tác giả
- `structured_data`: Lưu thông tin Schema.org dạng JSON
- `published_at`: Lưu thời điểm xuất bản, khác với created_at (thời điểm tạo)

**Ví dụ:**
```sql
-- Thêm bài viết với tác giả là team member
INSERT INTO blog_posts (
  title, slug, summary, content, 
  author_id, status_id, created_by_user_id
)
VALUES (
  'Xu hướng thiết kế web 2023', 'xu-huong-thiet-ke-web-2023',
  'Tổng hợp các xu hướng thiết kế web nổi bật năm 2023',
  'Nội dung chi tiết về các xu hướng...',
  (SELECT id FROM team_members WHERE name = 'Minh Tuấn'),
  (SELECT id FROM content_statuses WHERE name = 'published'),
  '550e8400-e29b-41d4-a716-446655440000'
);
```

### 3.7. Các bảng junction (nhiều-nhiều)

#### 3.7.1. Bảng `projects_services`
```sql
CREATE TABLE projects_services (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  service_id UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(project_id, service_id)
);
```

#### 3.7.2. Bảng `projects_tags`
```sql
CREATE TABLE projects_tags (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(project_id, tag_id)
);
```

#### 3.7.3. Bảng `blog_posts_tags`
```sql
CREATE TABLE blog_posts_tags (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  blog_post_id UUID NOT NULL REFERENCES blog_posts(id) ON DELETE CASCADE,
  tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(blog_post_id, tag_id)
);
```

**Ví dụ:**
```sql
-- Gán tags cho bài viết
INSERT INTO blog_posts_tags (blog_post_id, tag_id)
VALUES ('bbd8e498-7880-4484-9154-1455376b404b', 
        (SELECT id FROM tags WHERE name = 'UI/UX'));

-- Tìm tất cả bài viết có tag 'UI/UX'
SELECT bp.title 
FROM blog_posts bp
JOIN blog_posts_tags bpt ON bp.id = bpt.blog_post_id
JOIN tags t ON bpt.tag_id = t.id
WHERE t.name = 'UI/UX';
```

### 3.8. Bảng `contact_submissions` - Form liên hệ
```sql
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
```

### 3.9. Bảng `activity_logs` - Nhật ký hoạt động
```sql
CREATE TABLE activity_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  entity_type VARCHAR(50) NOT NULL, -- 'blog_post', 'project', etc.
  entity_id UUID NOT NULL,
  action_type_id UUID NOT NULL REFERENCES action_types(id) ON DELETE RESTRICT,
  changes JSONB, -- Lưu dữ liệu thay đổi (cũ/mới)
  ip_address VARCHAR(45),
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Ví dụ dữ liệu:**
```json
// Ví dữ liệu trong trường changes của activity_logs:
{
  "old": {
    "title": "Xu hướng thiết kế web 2023",
    "status_id": "9d75dd0f-2d1c-4e15-8fae-a2c328db56e9" // draft
  },
  "new": {
    "title": "Xu hướng thiết kế web 2023 - Cập nhật",
    "status_id": "6d3a4f8e-9c2b-4f87-a3e9-1f2d45b0821c" // published
  }
}
```

### 3.10. Bảng `site_visits` - Lưu thông tin về lượt truy cập
```sql
CREATE TABLE site_visits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  visitor_id VARCHAR(100) NOT NULL, -- Định danh ẩn danh (cookie hoặc fingerprint)
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
  user_id UUID REFERENCES users(id) ON DELETE SET NULL, -- Chỉ đặt nếu người dùng đã đăng nhập
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Chi tiết đặc biệt:**
- `visitor_id`: Mã định danh duy nhất cho mỗi khách truy cập, thường được tạo từ cookie hoặc browser fingerprint
- `visit_count`: Được tự động tăng lên thông qua trigger khi người dùng quay lại
- Lưu trữ thông tin UTM cho phép theo dõi hiệu quả của các chiến dịch marketing
- Các trường geolocation (country, region, city) cho phép phân tích người dùng theo khu vực

**Ví dụ:**
```sql
-- Thêm thông tin visit mới khi người dùng truy cập lần đầu
INSERT INTO site_visits (
  visitor_id, ip_address, user_agent, referrer_url, landing_page,
  country, region, city, browser, browser_version, os, os_version, device_type,
  utm_source, utm_medium, utm_campaign
)
VALUES (
  '0a1b2c3d4e5f', '203.0.113.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)...',
  'https://google.com', '/blog/xu-huong-thiet-ke-2023',
  'VN', 'Ho Chi Minh', 'Ho Chi Minh City', 'Chrome', '120.0', 'Windows', '10', 'desktop',
  'google', 'cpc', 'spring_promo_2023'
);

-- Cập nhật thông tin khi người dùng quay lại (trigger sẽ tự động tăng visit_count)
UPDATE site_visits 
SET landing_page = '/services' 
WHERE visitor_id = '0a1b2c3d4e5f';
```

### 3.11. Bảng `page_views` - Lưu thông tin về từng lượt xem trang
```sql
CREATE TABLE page_views (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  visit_id UUID NOT NULL REFERENCES site_visits(id) ON DELETE CASCADE,
  url_path TEXT NOT NULL,
  page_title TEXT,
  query_params JSONB,
  hash_fragment TEXT,
  time_on_page INTEGER, -- tính bằng giây
  exit_page BOOLEAN DEFAULT false,
  previous_page_id UUID REFERENCES page_views(id) ON DELETE SET NULL,
  events JSONB, -- Lưu trữ các sự kiện trên trang (click, gửi form, v.v.)
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Chi tiết đặc biệt:**
- Mỗi `page_view` liên kết với một `site_visit`, cho phép theo dõi hành trình người dùng
- `previous_page_id` cho phép xây dựng luồng di chuyển của người dùng
- `events` lưu trữ dưới dạng JSONB các tương tác của người dùng trên trang
- `time_on_page` được tính toán dựa trên thời gian giữa các lượt xem trang

**Ví dụ:**
```sql
-- Thêm lượt xem trang mới
INSERT INTO page_views (
  visit_id, url_path, page_title, query_params, time_on_page, events
)
VALUES (
  '550e8400-e29b-41d4-a716-446655440000', -- visit_id
  '/services/web-design',
  'Dịch vụ thiết kế web | Agency XYZ',
  '{"utm_source": "google", "utm_medium": "cpc"}',
  65, -- thời gian trên trang (giây)
  '{
    "clicks": [
      {"selector": ".cta-button", "timestamp": "2023-06-15T10:15:23Z"},
      {"selector": ".pricing-table", "timestamp": "2023-06-15T10:16:48Z"}
    ],
    "scrollDepth": 85
  }'
);

-- Cập nhật trạng thái exit_page khi người dùng rời khỏi trang
UPDATE page_views 
SET exit_page = true 
WHERE id = '7a1b2c3d-4e5f-6789-abcd-ef0123456789';
```

## 4. VIEWS - HIỂN THỊ DỮ LIỆU THÂN THIỆN

### 4.1. View `view_blog_posts`
```sql
CREATE VIEW view_blog_posts AS
SELECT 
  bp.id,
  bp.title,
  bp.slug,
  -- ...nhiều trường khác
  tm.name AS author_name,
  -- ...
  cs.name AS status_name,
  -- ...
  get_blog_post_tags(bp.id) AS tags,
  -- ...
FROM 
  blog_posts bp
JOIN 
  content_statuses cs ON bp.status_id = cs.id
JOIN 
  team_members tm ON bp.author_id = tm.id
JOIN 
  users u ON bp.created_by_user_id = u.id;
```

**Lợi ích:**
- Tự động hiển thị tên tác giả từ bảng team_members
- Hiển thị tên status thay vì ID
- Hiển thị danh sách tags dạng mảng (sử dụng hàm get_blog_post_tags)
- Cung cấp thông tin về người tạo (creator)

**Ví dụ truy vấn:**
```sql
-- Lấy tất cả bài viết kèm thông tin tác giả và tags
SELECT title, author_name, tags, status_name
FROM view_blog_posts
WHERE is_published = true
ORDER BY published_at DESC;
```

### 4.2. View `view_projects`
```sql
CREATE VIEW view_projects AS
SELECT 
  p.id,
  p.title,
  -- ...nhiều trường khác
  cs.name AS status_name,
  -- ...
  get_project_tags(p.id) AS tags,
  get_project_services(p.id) AS services,
  -- ...
FROM 
  projects p
JOIN 
  content_statuses cs ON p.status_id = cs.id
LEFT JOIN 
  users u ON p.created_by_user_id = u.id;
```

**Lợi ích:**
- Kết hợp dữ liệu từ nhiều bảng thành một view dễ sử dụng
- Hiển thị danh sách tags và services dạng mảng (sử dụng hàm get_project_tags, get_project_services)
- Cung cấp thông tin chi tiết về trạng thái và người tạo

### 4.3. View `view_contact_submissions`
```sql
CREATE VIEW view_contact_submissions AS
SELECT
  cs.id,
  cs.name,
  -- ...nhiều trường khác
  s.name AS service_name,
  ss.name AS status_name,
  CONCAT(u.first_name, ' ', u.last_name) AS assigned_to_name,
  -- ...
FROM
  contact_submissions cs
LEFT JOIN
  services s ON cs.service_interest = s.id
JOIN
  submission_statuses ss ON cs.status_id = ss.id
LEFT JOIN
  users u ON cs.assigned_to_user_id = u.id;
```

**Lợi ích:**
- Kết hợp thông tin liên hệ với dịch vụ quan tâm và người phụ trách
- Hiển thị tên trạng thái thay vì ID
- Dễ dàng truy vấn theo dịch vụ hoặc trạng thái

### 4.4. Functions phân tích dữ liệu

#### 4.4.1. Function `get_daily_page_views`
```sql
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
```

**Ví dụ sử dụng:**
```sql
-- Lấy thống kê lượt xem trang trong 30 ngày gần nhất
SELECT * FROM get_daily_page_views(CURRENT_DATE - 30, CURRENT_DATE);
```

#### 4.4.2. Function `get_visitor_stats`
```sql
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
```

**Ví dụ sử dụng:**
```sql
-- Lấy thống kê người truy cập trong tháng hiện tại
SELECT * FROM get_visitor_stats(DATE_TRUNC('month', CURRENT_DATE)::DATE, CURRENT_DATE);
```

## 5. TRIGGERS VÀ FUNCTIONS

### 5.1. Trigger cập nhật `updated_at`
```sql
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Ví dụ áp dụng cho bảng blog_posts
CREATE TRIGGER update_blog_posts_modtime
  BEFORE UPDATE ON blog_posts
  FOR EACH ROW
  EXECUTE PROCEDURE update_modified_column();
```

**Lợi ích:** Tự động cập nhật trường updated_at mỗi khi dữ liệu thay đổi.

### 5.2. Trigger ghi log hoạt động

```sql
CREATE OR REPLACE FUNCTION log_activity()
RETURNS TRIGGER AS $$
DECLARE
  action_type_uuid UUID;
  change_data JSONB;
  entity_type TEXT;
  user_id UUID;
BEGIN
  -- Xác định loại đối tượng
  entity_type := TG_TABLE_NAME;
  
  -- Lấy ID người dùng đang xác thực
  user_id := auth.uid();
  
  -- ...
  
  -- Xác định loại hành động
  IF TG_OP = 'INSERT' THEN
    -- ...
  ELSIF TG_OP = 'UPDATE' THEN
    -- ...
    -- Xử lý đặc biệt cho thay đổi trạng thái (publish/unpublish)
    IF TG_TABLE_NAME IN ('blog_posts', 'projects') AND OLD.status_id != NEW.status_id THEN
      -- ...
    END IF;
  ELSIF TG_OP = 'DELETE' THEN
    -- ...
  END IF;
  
  -- Ghi vào bảng activity_logs
  INSERT INTO activity_logs(...)
  VALUES (...);
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;
```

**Lợi ích:**
- Tự động ghi lại mọi thay đổi trong hệ thống
- Phát hiện các hành động đặc biệt (publish, unpublish)
- Lưu trữ dữ liệu trước và sau khi thay đổi
- Hỗ trợ kiểm tra lịch sử và khôi phục dữ liệu

### 5.3. Functions hỗ trợ

#### 5.3.1. Function `get_blog_author_name`
```sql
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
```

#### 5.3.2. Function `get_blog_post_tags`
```sql
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
```

#### 5.3.3. Function `get_project_tags` và `get_project_services`
```sql
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
```

### 5.4. Trigger cập nhật thông tin lượt truy cập

```sql
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
```

**Lợi ích:** Tự động cập nhật trường `last_visit_at` và tăng biến đếm `visit_count` mỗi khi một người dùng quay lại website.

## 6. ROW LEVEL SECURITY (RLS)

RLS giúp phân quyền truy cập dữ liệu ở cấp độ hàng.

### 6.1. RLS cho `blog_posts`
```sql
-- Ai cũng có thể xem bài viết đã xuất bản
CREATE POLICY "Anyone can view published blog posts" ON blog_posts 
  FOR SELECT USING (
    is_published = true AND EXISTS (
      SELECT 1 FROM content_statuses s
      WHERE blog_posts.status_id = s.id AND s.name = 'published'
    )
  );

-- Creator có thể quản lý (CRUD) bài viết của họ
CREATE POLICY "Creators can CRUD their own blog posts" ON blog_posts 
  FOR ALL USING (auth.uid() = created_by_user_id);

-- Admin có thể quản lý (CRUD) tất cả bài viết
CREATE POLICY "Admins can CRUD all blog posts" ON blog_posts 
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users u
      JOIN user_roles r ON u.role_id = r.id
      WHERE u.id = auth.uid() AND r.name = 'admin'
    )
  );
```

### 6.2. RLS cho `projects`
```sql
-- Ai cũng có thể xem dự án đã xuất bản
CREATE POLICY "Anyone can view published projects" ON projects 
  FOR SELECT USING (
    is_published = true AND EXISTS (
      SELECT 1 FROM content_statuses s
      WHERE projects.status_id = s.id AND s.name = 'published'
    )
  );

-- Creator có thể quản lý (CRUD) dự án của họ
CREATE POLICY "Creators can CRUD their own projects" ON projects 
  FOR ALL USING (auth.uid() = created_by_user_id);

-- Admin có thể quản lý (CRUD) tất cả dự án
CREATE POLICY "Admins can CRUD all projects" ON projects 
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users u
      JOIN user_roles r ON u.role_id = r.id
      WHERE u.id = auth.uid() AND r.name = 'admin'
    )
  );
```

### 6.3. RLS cho `contact_submissions`
```sql
-- Cho phép bất kỳ ai cũng có thể gửi form liên hệ
CREATE POLICY "Anyone can submit contact form" ON contact_submissions 
  FOR INSERT WITH CHECK (true);

-- Chỉ admin/creator mới có thể xem và cập nhật thông tin liên hệ
CREATE POLICY "Admins can view and update all submissions" ON contact_submissions 
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users u
      JOIN user_roles r ON u.role_id = r.id
      WHERE u.id = auth.uid() AND r.name = 'admin'
    )
  );

-- Creator chỉ có thể xem và cập nhật các liên hệ được gán cho họ
CREATE POLICY "Creators can view assigned submissions" ON contact_submissions 
  FOR SELECT USING (
    assigned_to_user_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM users u
      JOIN user_roles r ON u.role_id = r.id
      WHERE u.id = auth.uid() AND r.name = 'creator'
    )
  );
```

### 6.4. RLS cho `site_visits` và `page_views`
```sql
-- Chỉ admin mới có thể xem dữ liệu phân tích
CREATE POLICY "Admins can view all site visits" ON site_visits
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users u
      JOIN user_roles r ON u.role_id = r.id
      WHERE u.id = auth.uid() AND r.name = 'admin'
    )
  );

CREATE POLICY "Admins can view all page views" ON page_views
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users u
      JOIN user_roles r ON u.role_id = r.id
      WHERE u.id = auth.uid() AND r.name = 'admin'
    )
  );
```

**Lợi ích:** Bảo vệ dữ liệu phân tích nhạy cảm, chỉ cho phép quản trị viên truy cập.

## 7. HƯỚNG DẪN SỬ DỤNG

### 7.1. Lấy bài viết đã xuất bản với tags
```sql
SELECT * FROM view_blog_posts
WHERE is_published = true AND status_name = 'published'
ORDER BY published_at DESC;
```

### 7.2. Tìm kiếm bài viết theo tags
```sql
SELECT title, summary, author_name
FROM view_blog_posts
WHERE 'design' = ANY(tags) AND is_published = true
ORDER BY published_at DESC;
```

### 7.3. Lấy dự án theo dịch vụ
```sql
SELECT p.title, p.summary, p.client_name
FROM view_projects p
WHERE 'Web Design' = ANY(p.services) AND p.is_published = true;
```

### 7.4. Lấy lịch sử thay đổi của một bài viết
```sql
SELECT
  u.email AS modified_by,
  at.name AS action_type,
  al.changes,
  al.created_at
FROM
  activity_logs al
JOIN
  users u ON al.user_id = u.id
JOIN
  action_types at ON al.action_type_id = at.id
WHERE
  al.entity_type = 'blog_posts' AND
  al.entity_id = '550e8400-e29b-41d4-a716-446655440000'
ORDER BY
  al.created_at DESC;
```

### 7.5. Phân tích hành vi người dùng trên trang

```sql
-- Lấy các trang được xem nhiều nhất trong tuần qua
SELECT url_path, COUNT(*) AS view_count
FROM page_views
WHERE created_at >= CURRENT_DATE - 7
GROUP BY url_path
ORDER BY view_count DESC
LIMIT 10;

-- Phân tích thời gian trung bình người dùng ở lại trên mỗi trang
SELECT url_path, AVG(time_on_page) AS avg_time_seconds
FROM page_views
WHERE time_on_page IS NOT NULL
GROUP BY url_path
ORDER BY avg_time_seconds DESC;

-- Xác định tỷ lệ chuyển đổi (lượt xem trang liên hệ dẫn đến gửi form)
WITH contact_page_views AS (
  SELECT COUNT(*) AS view_count FROM page_views WHERE url_path = '/contact'
),
form_submissions AS (
  SELECT COUNT(*) AS submission_count FROM contact_submissions
  WHERE created_at >= CURRENT_DATE - 30
)
SELECT 
  view_count, 
  submission_count,
  ROUND((submission_count::numeric / view_count) * 100, 2) AS conversion_rate
FROM contact_page_views, form_submissions;
```

### 7.6. Phân tích nguồn lưu lượng và người dùng

```sql
-- Các nguồn truy cập website chính
SELECT utm_source, COUNT(*) AS visit_count
FROM site_visits
WHERE utm_source IS NOT NULL AND created_at >= CURRENT_DATE - 30
GROUP BY utm_source
ORDER BY visit_count DESC;

-- Phân tích thiết bị người dùng
SELECT device_type, COUNT(*) AS user_count, 
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM site_visits), 2) AS percentage
FROM site_visits
GROUP BY device_type
ORDER BY user_count DESC;

-- Theo dõi người dùng mới và quay lại
SELECT 
  DATE_TRUNC('day', created_at)::DATE AS day,
  COUNT(*) FILTER (WHERE visit_count = 1) AS new_visitors,
  COUNT(*) FILTER (WHERE visit_count > 1) AS returning_visitors
FROM site_visits
WHERE created_at >= CURRENT_DATE - 14
GROUP BY day
ORDER BY day;
```

## 8. LƯU Ý VÀ MỞ RỘNG

1. **Xử lý đa ngôn ngữ**: Trường `locale` hỗ trợ đa ngôn ngữ. Có thể mở rộng để lưu các phiên bản nội dung đa ngôn ngữ.

2. **Caching**: Nên cài đặt caching cho các view và các truy vấn thường xuyên sử dụng.

3. **Full-text search**: Có thể kích hoạt tìm kiếm toàn văn bằng cách sử dụng GIN index trên PostgreSQL.

4. **Media management**: Hệ thống hiện tại chỉ lưu URL hình ảnh, có thể mở rộng để quản lý media tốt hơn.

5. **Version control**: Activity logs đã cung cấp dữ liệu cơ bản cho việc kiểm soát phiên bản, có thể phát triển thêm chức năng phục hồi phiên bản cũ.

6. **Tích hợp AI**: Có thể tích hợp các tính năng AI như gợi ý tags, tóm tắt nội dung, hoặc phân tích cảm xúc cho feedback.

7. **Analytics**: Mở rộng hệ thống để theo dõi tương tác người dùng và phân tích hiệu suất nội dung.

8. **Scheduled Content**: Triển khai tính năng lên lịch xuất bản cho bài viết và dự án.

9. **Phân tích thời gian thực**: Triển khai tích hợp với các nền tảng phân tích thời gian thực như Grafana hoặc Power BI để trực quan hóa dữ liệu từ `page_views` và `site_visits`.

10. **Theo dõi chuyển đổi**: Phát triển hệ thống theo dõi mục tiêu và chuyển đổi dựa trên tương tác người dùng được ghi lại trong `page_views`.

## 9. BẢO MẬT VÀ PERFORMANCE

1. **RLS Policies**: Đảm bảo kiểm tra kỹ các RLS policy để không có lỗ hổng bảo mật.

2. **Indexes**: Tất cả các khóa ngoại và các trường tìm kiếm phổ biến đều được tạo index.

3. **Validation**: Thêm validation phía server và client để đảm bảo tính toàn vẹn dữ liệu.

4. **API Rate Limiting**: Triển khai giới hạn tần suất gọi API để tránh quá tải và tấn công DDoS.

5. **Backup**: Cấu hình sao lưu tự động và kế hoạch phục hồi dữ liệu đầy đủ. 

6. **Table Partitioning**: Các bảng có tốc độ tăng trưởng cao được thiết kế với partitioning để tối ưu hiệu suất:
   - `site_visits`: Phân vùng theo `first_visit_at` để dữ liệu người dùng được tổ chức theo thời gian
   - `page_views`: Phân vùng theo `created_at` để dễ dàng truy vấn và quản lý dữ liệu lượt xem theo khoảng thời gian
   - `activity_logs`: Phân vùng theo `created_at` giúp tối ưu hiệu suất với lượng lớn bản ghi lịch sử hoạt động

   ```sql
   -- Ví dụ cho bảng page_views với phân vùng theo tháng
   CREATE TABLE page_views (
     -- các trường
     created_at TIMESTAMPTZ DEFAULT NOW()
   ) PARTITION BY RANGE (created_at);
   
   -- Tạo partition cho tháng 4/2025
   CREATE TABLE page_views_202504 PARTITION OF page_views
       FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');
   ```

7. **Quản lý Partition Tự động**: Hệ thống sử dụng stored procedure để tự động tạo và quản lý các partition mới:
   ```sql
   -- Tạo partition cho 3 tháng tới cho tất cả các bảng được phân vùng
   SELECT create_monthly_partitions(3);
   ```
   
   Quy trình này có thể được lên lịch chạy hàng tháng để đảm bảo luôn có đủ partition sẵn sàng, đồng thời giúp:
   - Truy vấn hiệu quả hơn khi tìm kiếm theo ngày
   - Dễ dàng xóa dữ liệu cũ (chỉ cần xóa hoặc lưu trữ các partition cũ)
   - Cải thiện hiệu suất backup và vacuum
   - Duy trì hiệu năng cao khi lượng dữ liệu tăng nhanh 