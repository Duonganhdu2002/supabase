# GIẢI THÍCH CẤU TRÚC DATABASE CHO LANDING PAGE AGENCY

## 1. TỔNG QUAN

Database này được thiết kế cho landing page của một agency sáng tạo, với các tính năng:
- Quản lý nội dung (bài viết, dự án, dịch vụ)
- Hỗ trợ SEO tối ưu
- Theo dõi lịch sử thay đổi
- Quản lý người dùng và phân quyền
- Hỗ trợ đa ngôn ngữ (localization)

### Đặc điểm kỹ thuật:
- Sử dụng UUID làm khóa chính cho tất cả các bảng
- Áp dụng các nguyên tắc thiết kế chuẩn hóa
- Hỗ trợ quan hệ đa hình (polymorphic relationships)
- Views tối ưu để hiển thị dữ liệu người dùng thân thiện
- Triggers tự động cập nhật và logging

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

### 2.3. Bảng `author_types` - Loại tác giả
```sql
CREATE TABLE author_types (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(20) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Giá trị mặc định:**
- `team_member`: Tác giả là thành viên của agency
- `user`: Tác giả là người dùng đăng ký

**Ví dụ:**
```sql
-- Tìm các bài viết được viết bởi thành viên trong team
SELECT bp.title, tm.name AS author
FROM blog_posts bp
JOIN author_types at ON bp.author_type_id = at.id
JOIN team_members tm ON bp.author_id = tm.id
WHERE at.name = 'team_member';
```

### 2.4. Bảng `submission_statuses` - Trạng thái liên hệ
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

### 2.5. Bảng `action_types` - Loại hành động (cho activity logs)
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
  author_id UUID NOT NULL,
  author_type_id UUID NOT NULL REFERENCES author_types(id) ON DELETE RESTRICT,
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
- `author_id` + `author_type_id`: Hỗ trợ quan hệ đa hình, tác giả có thể là team_member hoặc user
- `structured_data`: Lưu thông tin Schema.org dạng JSON
- `published_at`: Lưu thời điểm xuất bản, khác với created_at (thời điểm tạo)

**Ví dụ:**
```sql
-- Thêm bài viết với tác giả là team member
INSERT INTO blog_posts (
  title, slug, summary, content, 
  author_id, author_type_id, 
  status_id, created_by_user_id
)
VALUES (
  'Xu hướng thiết kế web 2023', 'xu-huong-thiet-ke-web-2023',
  'Tổng hợp các xu hướng thiết kế web nổi bật năm 2023',
  'Nội dung chi tiết về các xu hướng...',
  (SELECT id FROM team_members WHERE name = 'Minh Tuấn'),
  (SELECT id FROM author_types WHERE name = 'team_member'),
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

### 3.8. Bảng `testimonials` - Đánh giá của khách hàng
```sql
CREATE TABLE testimonials (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_name VARCHAR(100) NOT NULL,
  client_role VARCHAR(100),
  client_company VARCHAR(100),
  client_avatar_url TEXT,
  content TEXT NOT NULL,
  rating SMALLINT CHECK (rating >= 1 AND rating <= 5),
  is_published BOOLEAN DEFAULT true,
  sort_order SMALLINT DEFAULT 0,
  project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
  created_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 3.9. Bảng `contact_submissions` - Form liên hệ
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

### 3.10. Bảng `activity_logs` - Nhật ký hoạt động
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
// Ví dụ dữ liệu trong trường changes của activity_logs:
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

## 4. VIEWS - HIỂN THỊ DỮ LIỆU THÂN THIỆN

### 4.1. View `view_blog_posts`
```sql
CREATE VIEW view_blog_posts AS
SELECT 
  bp.id,
  bp.title,
  bp.slug,
  -- ...nhiều trường khác
  CASE 
    WHEN at.name = 'team_member' THEN (SELECT tm.name FROM team_members tm WHERE tm.id = bp.author_id)
    WHEN at.name = 'user' THEN (SELECT CONCAT(u.first_name, ' ', u.last_name) FROM users u WHERE u.id = bp.author_id)
    ELSE 'Unknown'
  END AS author_name,
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
  author_types at ON bp.author_type_id = at.id
JOIN 
  users u ON bp.created_by_user_id = u.id;
```

**Lợi ích:**
- Tự động hiển thị tên tác giả (dù là team member hay user)
- Hiển thị tên status thay vì ID
- Hiển thị danh sách tags dạng mảng
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
### 4.3. View `view_contact_submissions`

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
-- ...
END;
$$ LANGUAGE plpgsql;
```

#### 5.3.2. Function `get_blog_post_tags`
```sql
CREATE OR REPLACE FUNCTION get_blog_post_tags(post_id UUID)
RETURNS TEXT[] AS $$
-- ...
END;
$$ LANGUAGE plpgsql;
```

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

-- Tác giả (user) có thể chỉnh sửa bài viết của họ
CREATE POLICY "User authors can edit their authored blog posts" ON blog_posts
  FOR UPDATE USING (
    auth.uid() = author_id AND 
    EXISTS (
      SELECT 1 FROM author_types at
      WHERE blog_posts.author_type_id = at.id AND at.name = 'user'
    )
  );
```

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

## 8. LƯU Ý VÀ MỞ RỘNG

1. **Xử lý đa ngôn ngữ**: Trường `locale` hỗ trợ đa ngôn ngữ. Có thể mở rộng để lưu các phiên bản nội dung đa ngôn ngữ.

2. **Caching**: Nên cài đặt caching cho các view và các truy vấn thường xuyên sử dụng.

3. **Full-text search**: Có thể kích hoạt tìm kiếm toàn văn bằng cách sử dụng GIN index.

4. **Media management**: Hệ thống hiện tại chỉ lưu URL hình ảnh, có thể mở rộng để quản lý media tốt hơn.

5. **Version control**: Activity logs đã cung cấp dữ liệu cơ bản cho việc kiểm soát phiên bản, có thể phát triển thêm chức năng phục hồi phiên bản cũ. 