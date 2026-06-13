-- ============================================================
-- AN CỰU GALLERIA HUẾ - DATABASE SCHEMA
-- PostgreSQL / Supabase
-- Version: 1.0.0
-- Created: 2025
-- ============================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ─── ENUMS ─────────────────────────────────────────────────

CREATE TYPE property_type AS ENUM (
  'shophouse', 'nha-pho', 'dat-nen', 'can-ho', 'biet-thu', 'van-phong', 'kho-xuong'
);

CREATE TYPE property_status AS ENUM (
  'available', 'sold', 'rented', 'pending', 'draft'
);

CREATE TYPE legal_status AS ENUM (
  'so-do', 'so-hong', 'gcnqsdd', 'hop-dong', 'dang-lam-so'
);

CREATE TYPE direction AS ENUM (
  'dong', 'tay', 'nam', 'bac', 'dong-nam', 'dong-bac', 'tay-nam', 'tay-bac'
);

CREATE TYPE project_status AS ENUM (
  'sap-mo-ban', 'dang-mo-ban', 'da-ban-het', 'hoan-thien'
);

CREATE TYPE lead_status AS ENUM (
  'new', 'contacted', 'qualified', 'closed', 'lost'
);

CREATE TYPE lead_source AS ENUM (
  'website', 'facebook', 'tiktok', 'google', 'zalo', 'referral', 'walk-in', 'other'
);

CREATE TYPE blog_category AS ENUM (
  'kien-thuc-dau-tu', 'phap-ly', 'phan-tich-du-an', 'thi-truong-hue', 'tin-tuc'
);

-- ─── AREAS TABLE ───────────────────────────────────────────

CREATE TABLE areas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) NOT NULL,
  slug VARCHAR(100) UNIQUE NOT NULL,
  city VARCHAR(100) NOT NULL DEFAULT 'Huế',
  district VARCHAR(100),
  description TEXT,
  price_from BIGINT, -- VND per m2
  price_to BIGINT,
  property_count INTEGER DEFAULT 0,
  icon VARCHAR(10),
  is_featured BOOLEAN DEFAULT false,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed areas
INSERT INTO areas (name, slug, district, price_from, price_to, icon, is_featured, sort_order) VALUES
  ('An Cựu', 'an-cuu', 'TP. Huế', 40000000, 120000000, '🏛️', true, 1),
  ('Vỹ Dạ', 'vy-da', 'TP. Huế', 30000000, 80000000, '🌸', true, 2),
  ('Thủy Dương', 'thuy-duong', 'Hương Thủy', 8000000, 25000000, '🌊', true, 3),
  ('Phú Thượng', 'phu-thuong', 'Phú Vang', 5000000, 15000000, '🌾', true, 4),
  ('Hương Thủy', 'huong-thuy', 'Hương Thủy', 6000000, 20000000, '🏞️', true, 5),
  ('An Vân Dương', 'an-van-duong', 'Hương Thủy', 10000000, 30000000, '🏙️', true, 6);

-- ─── PROJECTS TABLE ────────────────────────────────────────

CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(200) NOT NULL,
  slug VARCHAR(200) UNIQUE NOT NULL,
  developer VARCHAR(200),
  area_id UUID REFERENCES areas(id),
  address TEXT NOT NULL,
  description TEXT,
  content TEXT, -- Rich HTML content
  status project_status NOT NULL DEFAULT 'dang-mo-ban',
  property_types property_type[],
  total_units INTEGER,
  price_from BIGINT,
  price_to BIGINT,
  area_from INTEGER, -- m2
  area_to INTEGER,
  commission_rate DECIMAL(5,2), -- % commission
  
  -- Media
  hero_image TEXT,
  gallery_images TEXT[], -- array of URLs
  video_url TEXT,
  
  -- Location
  latitude DECIMAL(10, 7),
  longitude DECIMAL(10, 7),
  
  -- SEO
  meta_title VARCHAR(200),
  meta_description VARCHAR(400),
  og_image TEXT,
  
  -- Utilities
  utilities TEXT[], -- array of utility names
  
  -- Status
  is_featured BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  published_at TIMESTAMPTZ
);

-- Seed projects
INSERT INTO projects (name, slug, developer, address, description, status, price_from, total_units, hero_image, is_featured) VALUES
  ('An Cựu Galleria', 'an-cuu-galleria', 'TTC Land', 'An Cựu, TP. Huế', 'Dự án căn hộ cao cấp An Cựu Galleria tại vị trí đắc địa trung tâm Huế.', 'dang-mo-ban', 2800000000, 280, '/images/apartment.png', true),
  ('Eco Garden Huế', 'eco-garden-hue', 'Nam Long Group', 'Hương Thủy, Huế', 'Khu đô thị xanh sinh thái với shophouse và nhà phố.', 'sap-mo-ban', 3500000000, 150, '/images/shophouse.png', true),
  ('Royal Park An Vân Dương', 'royal-park', 'Kosy Group', 'An Vân Dương, Huế', 'Khu đô thị Royal Park với đất nền và nhà phố cao cấp.', 'dang-mo-ban', 1200000000, 400, '/images/land.png', true),
  ('KĐT An Vân Dương', 'kdt-an-van-duong', 'Cộng Đồng Huế', 'Hương Thủy, Huế', 'Khu đô thị mới An Vân Dương với đất nền pháp lý sạch.', 'dang-mo-ban', 800000000, 600, '/images/land.png', false);

-- ─── PROPERTIES TABLE ──────────────────────────────────────

CREATE TABLE properties (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Basic info
  title VARCHAR(400) NOT NULL,
  slug VARCHAR(400) UNIQUE NOT NULL,
  description TEXT,
  content TEXT, -- Rich HTML content
  property_type property_type NOT NULL,
  status property_status NOT NULL DEFAULT 'available',
  
  -- Location
  area_id UUID REFERENCES areas(id),
  project_id UUID REFERENCES projects(id),
  address TEXT NOT NULL,
  street VARCHAR(200),
  ward VARCHAR(100),
  district VARCHAR(100),
  city VARCHAR(100) DEFAULT 'Huế',
  latitude DECIMAL(10, 7),
  longitude DECIMAL(10, 7),
  
  -- Specs
  price BIGINT NOT NULL, -- VND
  price_per_m2 BIGINT,
  area DECIMAL(10, 2) NOT NULL, -- m2 (total)
  area_floor DECIMAL(10, 2), -- m2 (floor area)
  frontage DECIMAL(5, 2), -- mét mặt tiền
  depth DECIMAL(5, 2), -- chiều sâu
  floors INTEGER,
  bedrooms INTEGER,
  bathrooms INTEGER,
  direction direction,
  legal_status legal_status DEFAULT 'so-do',
  
  -- Features
  has_garage BOOLEAN DEFAULT false,
  has_garden BOOLEAN DEFAULT false,
  has_pool BOOLEAN DEFAULT false,
  is_corner BOOLEAN DEFAULT false,
  is_alley BOOLEAN DEFAULT false,
  
  -- Media
  thumbnail TEXT,
  gallery_images TEXT[],
  video_url TEXT,
  virtual_tour_url TEXT,
  
  -- SEO
  meta_title VARCHAR(200),
  meta_description VARCHAR(400),
  og_image TEXT,
  
  -- Tracking
  view_count INTEGER DEFAULT 0,
  lead_count INTEGER DEFAULT 0,
  favorite_count INTEGER DEFAULT 0,
  
  -- Status flags
  is_featured BOOLEAN DEFAULT false,
  is_hot BOOLEAN DEFAULT false,
  is_new BOOLEAN DEFAULT true,
  is_active BOOLEAN DEFAULT true,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  published_at TIMESTAMPTZ,
  sold_at TIMESTAMPTZ,
  
  -- Full-text search
  search_vector TSVECTOR
);

-- GIN index for full-text search
CREATE INDEX properties_search_idx ON properties USING GIN(search_vector);
CREATE INDEX properties_type_idx ON properties(property_type);
CREATE INDEX properties_status_idx ON properties(status);
CREATE INDEX properties_area_idx ON properties(area_id);
CREATE INDEX properties_price_idx ON properties(price);
CREATE INDEX properties_area_size_idx ON properties(area);
CREATE INDEX properties_featured_idx ON properties(is_featured, is_active, published_at DESC);

-- Auto-update search vector
CREATE OR REPLACE FUNCTION update_property_search_vector()
RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector := 
    setweight(to_tsvector('simple', COALESCE(NEW.title, '')), 'A') ||
    setweight(to_tsvector('simple', COALESCE(NEW.address, '')), 'B') ||
    setweight(to_tsvector('simple', COALESCE(NEW.description, '')), 'C');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER property_search_vector_update
  BEFORE INSERT OR UPDATE ON properties
  FOR EACH ROW EXECUTE FUNCTION update_property_search_vector();

-- Auto-update timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER properties_updated_at BEFORE UPDATE ON properties
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Seed sample properties
INSERT INTO properties (title, slug, property_type, address, area, frontage, floors, price, price_per_m2, direction, legal_status, is_featured, is_hot, thumbnail) VALUES
  ('Shophouse 3 tầng mặt tiền Trần Phú – Trung tâm An Cựu', 'shophouse-tran-phu-an-cuu', 'shophouse', 'Đường Trần Phú, An Cựu, TP. Huế', 85, 5.0, 3, 6800000000, 80000000, 'dong-nam', 'so-do', true, true, '/images/shophouse.png'),
  ('Đất nền phân lô KĐT An Vân Dương – Pháp lý hoàn chỉnh', 'dat-nen-an-van-duong', 'dat-nen', 'KĐT An Vân Dương, Hương Thủy, Huế', 120, 6.0, NULL, 1920000000, 16000000, 'dong', 'so-do', true, false, '/images/land.png'),
  ('Căn hộ An Cựu Galleria 2PN – View Sông Hương', 'can-ho-an-cuu-galleria-2pn', 'can-ho', 'An Cựu Galleria, TP. Huế', 72, NULL, NULL, 2850000000, 39600000, 'bac', 'hop-dong', true, true, '/images/apartment.png'),
  ('Shophouse Vỹ Dạ – Mặt Tiền Sông Hương', 'shophouse-vy-da-song-huong', 'shophouse', 'Vỹ Dạ, TP. Huế', 110, 6.0, 3, 8500000000, 77300000, 'dong', 'so-do', false, false, '/images/shophouse.png'),
  ('Đất nền An Cựu – Sổ Đỏ Chính Chủ', 'dat-nen-an-cuu-so-do', 'dat-nen', 'An Cựu, TP. Huế', 100, 6.0, NULL, 2400000000, 24000000, 'nam', 'so-do', false, false, '/images/land.png'),
  ('Nhà Phố Vỹ Dạ 3 Tầng – Cách Sông Hương 200m', 'nha-pho-vy-da-3-tang', 'nha-pho', 'Vỹ Dạ, TP. Huế', 95, 5.0, 3, 4600000000, 48400000, 'tay', 'so-do', false, false, '/images/shophouse.png');

-- ─── LEADS TABLE ───────────────────────────────────────────

CREATE TABLE leads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Contact info
  name VARCHAR(200) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  email VARCHAR(200),
  
  -- Intent
  need VARCHAR(100), -- mua, ban, tu-van, phap-ly
  note TEXT,
  budget BIGINT,
  area_interest VARCHAR(200),
  property_type property_type,
  
  -- Source
  source lead_source DEFAULT 'website',
  utm_source VARCHAR(100),
  utm_medium VARCHAR(100),
  utm_campaign VARCHAR(100),
  page_url TEXT,
  
  -- Related
  property_id UUID REFERENCES properties(id),
  project_id UUID REFERENCES projects(id),
  
  -- Status
  status lead_status DEFAULT 'new',
  assigned_to VARCHAR(200),
  notes TEXT,
  
  -- Tracking
  ip_address INET,
  user_agent TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  contacted_at TIMESTAMPTZ,
  closed_at TIMESTAMPTZ
);

CREATE INDEX leads_status_idx ON leads(status);
CREATE INDEX leads_source_idx ON leads(source);
CREATE INDEX leads_created_idx ON leads(created_at DESC);
CREATE INDEX leads_phone_idx ON leads(phone);

CREATE TRIGGER leads_updated_at BEFORE UPDATE ON leads
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ─── BLOG POSTS TABLE ──────────────────────────────────────

CREATE TABLE blog_posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title VARCHAR(400) NOT NULL,
  slug VARCHAR(400) UNIQUE NOT NULL,
  excerpt TEXT,
  content TEXT NOT NULL,
  category blog_category NOT NULL DEFAULT 'kien-thuc-dau-tu',
  tags TEXT[],
  author VARCHAR(200) DEFAULT 'An Cựu Galleria Huế',
  
  -- Media
  thumbnail TEXT,
  og_image TEXT,
  
  -- SEO
  meta_title VARCHAR(200),
  meta_description VARCHAR(400),
  canonical_url TEXT,
  
  -- Tracking
  view_count INTEGER DEFAULT 0,
  reading_time INTEGER, -- minutes
  
  -- Status
  is_featured BOOLEAN DEFAULT false,
  is_published BOOLEAN DEFAULT false,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  published_at TIMESTAMPTZ,
  
  -- Full-text search
  search_vector TSVECTOR
);

CREATE INDEX blog_posts_slug_idx ON blog_posts(slug);
CREATE INDEX blog_posts_category_idx ON blog_posts(category);
CREATE INDEX blog_posts_published_idx ON blog_posts(is_published, published_at DESC);
CREATE INDEX blog_posts_search_idx ON blog_posts USING GIN(search_vector);

-- Seed blog posts
INSERT INTO blog_posts (title, slug, excerpt, category, is_published, published_at, reading_time, is_featured) VALUES
  ('5 Lưu Ý Khi Mua Đất Nền Tại Huế Không Phải Ai Cũng Biết', '5-luu-y-khi-mua-dat-nen-hue', 'Trước khi quyết định mua đất nền tại Huế, bạn cần nắm rõ 5 điều này để tránh rủi ro pháp lý và tài chính.', 'kien-thuc-dau-tu', true, NOW() - INTERVAL '5 days', 8, true),
  ('Phân Tích Dự Án An Cựu Galleria 2025 – Có Nên Đầu Tư?', 'phan-tich-du-an-an-cuu-galleria-2025', 'Review toàn diện dự án An Cựu Galleria: vị trí, tiện ích, giá bán và tiềm năng sinh lời.', 'phan-tich-du-an', true, NOW() - INTERVAL '10 days', 12, true),
  ('Giá Đất Huế Tăng Mạnh Q1/2025 – Nguyên Nhân Và Dự Báo', 'gia-dat-hue-tang-manh-q1-2025', 'Thị trường bất động sản Huế ghi nhận mức tăng giá đất ấn tượng trong Q1/2025. Cùng phân tích nguyên nhân và xu hướng sắp tới.', 'thi-truong-hue', true, NOW() - INTERVAL '15 days', 6, false),
  ('Hướng Dẫn Chi Tiết Thủ Tục Mua Bán Nhà Đất Tại Huế 2025', 'huong-dan-thu-tuc-mua-ban-nha-dat-hue-2025', 'Quy trình mua bán nhà đất tại Huế từ A đến Z – từ kiểm tra pháp lý đến công chứng và đăng bộ.', 'phap-ly', true, NOW() - INTERVAL '20 days', 15, false),
  ('Top 5 Khu Vực Đầu Tư Bất Động Sản Tiềm Năng Nhất Huế 2025', 'top-5-khu-vuc-dau-tu-bat-dong-san-hue-2025', 'Các khu vực bất động sản Huế đang có tốc độ tăng giá tốt nhất và tiềm năng phát triển cao nhất trong năm 2025.', 'thi-truong-hue', true, NOW() - INTERVAL '25 days', 10, false),
  ('Kinh Nghiệm Đầu Tư Bất Động Sản Lần Đầu – Sai Lầm Cần Tránh', 'kinh-nghiem-dau-tu-bds-lan-dau', 'Những sai lầm phổ biến mà người mua nhà lần đầu thường mắc phải và cách để tránh rủi ro không đáng có.', 'kien-thuc-dau-tu', true, NOW() - INTERVAL '30 days', 9, false);

-- ─── TESTIMONIALS TABLE ────────────────────────────────────

CREATE TABLE testimonials (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_name VARCHAR(200) NOT NULL,
  customer_title VARCHAR(200),
  customer_avatar TEXT,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5) DEFAULT 5,
  content TEXT NOT NULL,
  property_type VARCHAR(100),
  transaction_date DATE,
  is_featured BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed testimonials
INSERT INTO testimonials (customer_name, customer_title, rating, content, property_type, is_featured) VALUES
  ('Chị Thanh Huyền', 'Mua Shophouse An Cựu – 2024', 5, 'Anh tư vấn rất nhiệt tình, thông tin pháp lý rõ ràng từng điều khoản. Tôi đã mua được shophouse mặt tiền An Cựu đúng như ý muốn, giá hợp lý. Rất tin tưởng và sẽ giới thiệu cho bạn bè.', 'Shophouse', true),
  ('Anh Minh Khoa', 'Mua Đất Nền An Vân Dương – 2024', 5, 'Quy trình tư vấn bài bản, không áp lực. Tìm hiểu kỹ nhu cầu của gia đình tôi rồi mới giới thiệu đất nền phù hợp. Hỗ trợ thủ tục pháp lý từ đầu đến cuối, rất chuyên nghiệp.', 'Đất Nền', true),
  ('Chị Linh Chi', 'Mua Căn Hộ An Cựu Galleria – 2023', 5, 'Tìm kiếm căn hộ An Cựu Galleria gần 3 tháng, nhờ được tư vấn chi tiết về giá thị trường mà tôi quyết định đặt mua ngay. Đến nay đã tăng 15% sau 8 tháng.', 'Căn Hộ', true);

-- ─── FAQS TABLE ────────────────────────────────────────────

CREATE TABLE faqs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  category VARCHAR(100),
  page VARCHAR(100), -- which page to show on
  project_id UUID REFERENCES projects(id),
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed FAQs
INSERT INTO faqs (question, answer, page, sort_order) VALUES
  ('Thủ tục mua bất động sản tại Huế cần những gì?', 'Để mua bất động sản tại Huế, bạn cần: CMND/CCCD còn hiệu lực, hộ khẩu, giấy tờ hôn nhân (nếu có). Về phía bất động sản cần kiểm tra: Sổ đỏ/Sổ hồng, quy hoạch, giấy phép xây dựng. Chúng tôi hỗ trợ kiểm tra pháp lý miễn phí và đồng hành toàn bộ quy trình ký kết hợp đồng.', 'home', 1),
  ('Giá đất tại An Cựu Huế hiện nay bao nhiêu?', 'Giá đất tại khu vực An Cựu, TP. Huế năm 2025 dao động từ 40 – 120 triệu/m² tùy vị trí và mặt tiền đường. Đất mặt tiền đường lớn như Trần Phú, Hùng Vương có giá 80 – 120 triệu/m². Đất hẻm và khu dân cư dao động 40 – 60 triệu/m².', 'home', 2),
  ('An Cựu Galleria có những loại hình nào và giá bao nhiêu?', 'An Cựu Galleria Huế cung cấp 3 loại hình: Căn hộ 1-3 phòng ngủ (65-120m², từ 2,8 tỷ), Shophouse thương mại tầng 1 (từ 5 tỷ), và Penthouse cao cấp (từ 8 tỷ). Dự án có bể bơi, gym, công viên nội khu và đang được hỗ trợ vay ngân hàng đến 70%.', 'home', 3),
  ('Có thể vay ngân hàng mua bất động sản tại Huế không?', 'Có, hầu hết các ngân hàng tại Huế đều hỗ trợ vay mua bất động sản với lãi suất ưu đãi 6-9%/năm (2 năm đầu), vay đến 70-80% giá trị tài sản, thời hạn 15-25 năm.', 'home', 4),
  ('Khu vực nào ở Huế có tiềm năng đầu tư bất động sản tốt nhất 2025?', 'Năm 2025, các khu vực tiềm năng nhất tại Huế gồm: An Vân Dương (hạ tầng mới, giá còn thấp), An Cựu City (trung tâm, thanh khoản cao), Thủy Dương – Hương Thủy (gần KCN), Vỹ Dạ (ven sông Hương, lifestyle cao cấp).', 'home', 5);

-- ─── AREA PRICE HISTORY ────────────────────────────────────

CREATE TABLE area_price_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  area_id UUID REFERENCES areas(id) NOT NULL,
  year INTEGER NOT NULL,
  quarter INTEGER CHECK (quarter >= 1 AND quarter <= 4),
  month INTEGER CHECK (month >= 1 AND month <= 12),
  price_from BIGINT,
  price_to BIGINT,
  avg_price BIGINT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── AREA STREET PRICES ────────────────────────────────────

CREATE TABLE area_street_prices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  area_id UUID REFERENCES areas(id) NOT NULL,
  street_name VARCHAR(200) NOT NULL,
  street_type VARCHAR(50), -- duong-lon, hem, ngo
  price_from BIGINT NOT NULL,
  price_to BIGINT NOT NULL,
  unit VARCHAR(20) DEFAULT 'VND/m2',
  updated_at DATE NOT NULL DEFAULT CURRENT_DATE,
  notes TEXT
);

-- Seed An Cựu street prices
INSERT INTO area_street_prices (area_id, street_name, price_from, price_to) 
SELECT id, 'Đường Trần Phú', 85000000, 120000000 FROM areas WHERE slug = 'an-cuu';
INSERT INTO area_street_prices (area_id, street_name, price_from, price_to) 
SELECT id, 'Đường Hùng Vương', 70000000, 100000000 FROM areas WHERE slug = 'an-cuu';
INSERT INTO area_street_prices (area_id, street_name, price_from, price_to) 
SELECT id, 'Đường An Dương Vương', 60000000, 85000000 FROM areas WHERE slug = 'an-cuu';
INSERT INTO area_street_prices (area_id, street_name, price_from, price_to) 
SELECT id, 'Đường Bùi Thị Xuân', 50000000, 70000000 FROM areas WHERE slug = 'an-cuu';
INSERT INTO area_street_prices (area_id, street_name, price_from, price_to) 
SELECT id, 'KDC An Cựu City', 40000000, 60000000 FROM areas WHERE slug = 'an-cuu';

-- ─── MEDIA TABLE ───────────────────────────────────────────

CREATE TABLE media (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  filename VARCHAR(400) NOT NULL,
  original_name VARCHAR(400),
  file_path TEXT NOT NULL,
  file_size INTEGER,
  mime_type VARCHAR(100),
  width INTEGER,
  height INTEGER,
  alt_text TEXT,
  caption TEXT,
  
  -- Relations
  property_id UUID REFERENCES properties(id),
  project_id UUID REFERENCES projects(id),
  blog_post_id UUID REFERENCES blog_posts(id),
  
  uploaded_by VARCHAR(200),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── SITE SETTINGS TABLE ───────────────────────────────────

CREATE TABLE site_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key VARCHAR(100) UNIQUE NOT NULL,
  value TEXT,
  type VARCHAR(50) DEFAULT 'string', -- string, number, boolean, json
  description TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed settings
INSERT INTO site_settings (key, value, type, description) VALUES
  ('site_name', 'An Cựu Galleria Huế', 'string', 'Tên website'),
  ('site_tagline', 'Bất Động Sản Cao Cấp Tại Huế', 'string', 'Slogan'),
  ('hotline', '0907272001', 'string', 'Số điện thoại chính'),
  ('zalo_phone', '0907272001', 'string', 'Số Zalo'),
  ('facebook_url', 'https://www.facebook.com/ancuugalleriahue', 'string', 'Facebook page URL'),
  ('address', 'An Cựu, TP. Huế, Thừa Thiên Huế', 'string', 'Địa chỉ văn phòng'),
  ('working_hours', '08:00 – 20:00, 7 ngày/tuần', 'string', 'Giờ làm việc'),
  ('google_analytics_id', '', 'string', 'Google Analytics 4 Measurement ID'),
  ('facebook_pixel_id', '', 'string', 'Facebook Pixel ID'),
  ('popup_delay_seconds', '30', 'number', 'Số giây trước khi hiện popup'),
  ('featured_properties_count', '6', 'number', 'Số BDS nổi bật trên trang chủ'),
  ('featured_projects_count', '4', 'number', 'Số dự án nổi bật trên trang chủ');

-- ─── ROW LEVEL SECURITY ────────────────────────────────────

-- Enable RLS
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE blog_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;

-- Public read access for published content
CREATE POLICY "Public properties are viewable by everyone" ON properties
  FOR SELECT USING (is_active = true AND status != 'draft');

CREATE POLICY "Public projects are viewable by everyone" ON projects
  FOR SELECT USING (is_active = true);

CREATE POLICY "Published posts are viewable by everyone" ON blog_posts
  FOR SELECT USING (is_published = true);

-- Anyone can insert leads (form submissions)
CREATE POLICY "Anyone can submit leads" ON leads
  FOR INSERT WITH CHECK (true);

-- Only authenticated users can manage
CREATE POLICY "Authenticated users manage properties" ON properties
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users manage leads" ON leads
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users manage projects" ON projects
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users manage blog" ON blog_posts
  FOR ALL USING (auth.role() = 'authenticated');

-- ─── VIEWS ─────────────────────────────────────────────────

-- Public properties view (only active, published)
CREATE VIEW public_properties AS
SELECT 
  p.*,
  a.name as area_name,
  a.slug as area_slug,
  a.district as area_district,
  pr.name as project_name,
  pr.slug as project_slug
FROM properties p
LEFT JOIN areas a ON p.area_id = a.id
LEFT JOIN projects pr ON p.project_id = pr.id
WHERE p.is_active = true AND p.status != 'draft';

-- Featured properties view
CREATE VIEW featured_properties AS
SELECT * FROM public_properties
WHERE is_featured = true OR is_hot = true
ORDER BY is_hot DESC, is_featured DESC, published_at DESC
LIMIT 12;

-- ─── FUNCTIONS ─────────────────────────────────────────────

-- Full-text search function
CREATE OR REPLACE FUNCTION search_properties(
  search_query TEXT,
  p_type property_type DEFAULT NULL,
  p_area_id UUID DEFAULT NULL,
  p_price_min BIGINT DEFAULT NULL,
  p_price_max BIGINT DEFAULT NULL,
  p_area_min DECIMAL DEFAULT NULL,
  p_area_max DECIMAL DEFAULT NULL,
  p_direction direction DEFAULT NULL,
  p_legal legal_status DEFAULT NULL,
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE(property_data JSONB, total_count BIGINT) AS $$
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT p.*, COUNT(*) OVER() as total
    FROM public_properties p
    WHERE
      (search_query IS NULL OR p.search_vector @@ plainto_tsquery('simple', search_query))
      AND (p_type IS NULL OR p.property_type = p_type)
      AND (p_area_id IS NULL OR p.area_id = p_area_id)
      AND (p_price_min IS NULL OR p.price >= p_price_min)
      AND (p_price_max IS NULL OR p.price <= p_price_max)
      AND (p_area_min IS NULL OR p.area >= p_area_min)
      AND (p_area_max IS NULL OR p.area <= p_area_max)
      AND (p_direction IS NULL OR p.direction = p_direction)
      AND (p_legal IS NULL OR p.legal_status = p_legal)
    ORDER BY is_featured DESC, is_hot DESC, published_at DESC
    LIMIT p_limit OFFSET p_offset
  )
  SELECT to_jsonb(f.*) - 'total', f.total
  FROM filtered f;
END;
$$ LANGUAGE plpgsql;

-- Increment view count
CREATE OR REPLACE FUNCTION increment_property_views(p_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE properties SET view_count = view_count + 1 WHERE id = p_id;
END;
$$ LANGUAGE plpgsql;

-- ─── STORAGE BUCKETS (Supabase) ────────────────────────────
-- Run these in Supabase Dashboard > Storage
-- CREATE BUCKET 'property-images' (public: true)
-- CREATE BUCKET 'project-images' (public: true)
-- CREATE BUCKET 'blog-images' (public: true)
-- CREATE BUCKET 'agent-media' (public: true)
