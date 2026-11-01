-- ============================================================================
-- SKEMA DATABASE & ROW LEVEL SECURITY (RLS) SUPABASE
-- WEBSITE RESMI SMP NEGERI 71 KOTA BANDUNG (MULTI-ROLE CMS)
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. TABEL PENGATURAN PROFIL, MEDIA SOSIAL & STATISTIK SEKOLAH
CREATE TABLE IF NOT EXISTS public.school_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_name TEXT NOT NULL DEFAULT 'SMP Negeri 71 Kota Bandung',
  logo_url TEXT DEFAULT '',
  hero_bg_url TEXT DEFAULT '',
  highlight_1 TEXT DEFAULT 'Terakreditasi A Unggul',
  highlight_2 TEXT DEFAULT 'Kelas Digital Cerdas',
  highlight_3 TEXT DEFAULT 'Sekolah Ramah Anak',
  principal_name TEXT NOT NULL DEFAULT 'Kepala SMP Negeri 71 Kota Bandung',
  principal_photo TEXT,
  principal_welcome TEXT,
  short_profile TEXT,
  vision TEXT,
  mission TEXT,
  stat_students INTEGER DEFAULT 0,
  stat_teachers INTEGER DEFAULT 0,
  stat_classes INTEGER DEFAULT 0,
  stat_achievements INTEGER DEFAULT 0,
  address TEXT,
  phone TEXT,
  email TEXT,
  maps_url TEXT,
  instagram_url TEXT DEFAULT 'https://www.instagram.com/smpn71bandung',
  youtube_url TEXT DEFAULT 'https://www.youtube.com/@smpn71bandung',
  tiktok_url TEXT DEFAULT 'https://www.tiktok.com/@smpn71bandung',
  music_config JSONB DEFAULT '{"enabled":true,"default_volume":25,"loop":true,"tracks":[{"id":"track-default-1","title":"Harmoni Instrumental Pendidikan SMPN 71 Bandung","source_type":"synth","source_url":"synth://educational-inspiration","target_page":"semua","is_primary":true}]}'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Migrasi aman jika tabel school_settings sudah dibuat sebelumnya
ALTER TABLE public.school_settings ADD COLUMN IF NOT EXISTS logo_url TEXT DEFAULT '';
ALTER TABLE public.school_settings ADD COLUMN IF NOT EXISTS hero_bg_url TEXT DEFAULT '';
ALTER TABLE public.school_settings ADD COLUMN IF NOT EXISTS highlight_1 TEXT DEFAULT 'Terakreditasi A Unggul';
ALTER TABLE public.school_settings ADD COLUMN IF NOT EXISTS highlight_2 TEXT DEFAULT 'Kelas Digital Cerdas';
ALTER TABLE public.school_settings ADD COLUMN IF NOT EXISTS highlight_3 TEXT DEFAULT 'Sekolah Ramah Anak';
ALTER TABLE public.school_settings ADD COLUMN IF NOT EXISTS instagram_url TEXT DEFAULT 'https://www.instagram.com/smpn71bandung';
ALTER TABLE public.school_settings ADD COLUMN IF NOT EXISTS youtube_url TEXT DEFAULT 'https://www.youtube.com/@smpn71bandung';
ALTER TABLE public.school_settings ADD COLUMN IF NOT EXISTS tiktok_url TEXT DEFAULT 'https://www.tiktok.com/@smpn71bandung';
ALTER TABLE public.school_settings ADD COLUMN IF NOT EXISTS music_config JSONB DEFAULT '{"enabled":true,"default_volume":25,"loop":true,"tracks":[{"id":"track-default-1","title":"Harmoni Instrumental Pendidikan SMPN 71 Bandung","source_type":"synth","source_url":"synth://educational-inspiration","target_page":"semua","is_primary":true}]}'::jsonb;

-- 2. TABEL AKUN PENGGUNA MULTI-ROLE (NON-AUTH / HYBRID LOGIN)
CREATE TABLE IF NOT EXISTS public.school_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('kepsek', 'operator', 'guru', 'spmb', 'humas')),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. TABEL POSTINGAN TERPADU (BERITA, PENGUMUMAN, AGENDA, AKADEMIK, LAYANAN SISWA, PPID)
CREATE TABLE IF NOT EXISTS public.posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category TEXT NOT NULL CHECK (category IN ('berita', 'pengumuman', 'agenda', 'akademik', 'layanan_siswa', 'ppid')),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  image_url TEXT,
  file_url TEXT DEFAULT '',
  file_name TEXT DEFAULT '',
  event_date DATE DEFAULT CURRENT_DATE,
  author_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Migrasi kolom file_url dan file_name untuk lampiran dokumen PDF
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS file_url TEXT DEFAULT '';
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS file_name TEXT DEFAULT '';

-- 4. TABEL DIREKTORI GURU DAN TENAGA KEPENDIDIKAN (GTK)
CREATE TABLE IF NOT EXISTS public.staff_directory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name TEXT NOT NULL,
  nip TEXT,
  position TEXT NOT NULL,
  subject TEXT,
  photo_url TEXT,
  category TEXT NOT NULL CHECK (category IN ('Pendidik', 'Tenaga Kependidikan')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. TABEL FASILITAS SEKOLAH & GALERI FOTO/VIDEO/TIKTOK/GOOGLE DRIVE
CREATE TABLE IF NOT EXISTS public.facilities_gallery (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_type TEXT NOT NULL CHECK (item_type IN ('fasilitas', 'foto', 'video', 'tiktok', 'gdrive')),
  title TEXT NOT NULL,
  description TEXT,
  media_url TEXT NOT NULL,
  condition_or_tag TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Migrasi constraint item_type fasilitas_gallery agar mendukung link TikTok dan Google Drive
ALTER TABLE public.facilities_gallery DROP CONSTRAINT IF EXISTS facilities_gallery_item_type_check;
DO $$ 
BEGIN
  BEGIN
    ALTER TABLE public.facilities_gallery ADD CONSTRAINT facilities_gallery_item_type_check 
      CHECK (item_type IN ('fasilitas', 'foto', 'video', 'tiktok', 'gdrive'));
  EXCEPTION
    WHEN duplicate_object THEN NULL;
  END;
END $$;

-- 6. TABEL PENDAFTARAN SPMB (SISTEM PENERIMAAN MURID BARU)
CREATE TABLE IF NOT EXISTS public.spmb_registrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reg_number TEXT UNIQUE NOT NULL,
  nisn TEXT NOT NULL,
  full_name TEXT NOT NULL,
  origin_school TEXT NOT NULL,
  track TEXT NOT NULL CHECK (track IN ('Zonasi', 'Afirmasi', 'Prestasi', 'Mutasi')),
  parent_phone TEXT NOT NULL,
  average_score NUMERIC(5,2) DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'Menunggu Verifikasi' CHECK (status IN ('Menunggu Verifikasi', 'Diterima', 'Cadangan', 'Ditolak')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. TABEL KONTAK, PENGADUAN MASYARAKAT & PERMOHONAN PPID
CREATE TABLE IF NOT EXISTS public.public_complaints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_name TEXT NOT NULL,
  sender_contact TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('Pengaduan', 'Saran', 'Permohonan PPID')),
  message TEXT NOT NULL,
  response TEXT,
  status TEXT NOT NULL DEFAULT 'Baru' CHECK (status IN ('Baru', 'Diproses', 'Selesai')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- AKTIVASI ROW LEVEL SECURITY (RLS) & KEBIJAKAN AKSES HYBRID
-- ============================================================================

ALTER TABLE public.school_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.school_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_directory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.facilities_gallery ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.spmb_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.public_complaints ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow Hybrid Full Access school_settings" ON public.school_settings;
CREATE POLICY "Allow Hybrid Full Access school_settings"
  ON public.school_settings FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Allow Hybrid Full Access school_users" ON public.school_users;
CREATE POLICY "Allow Hybrid Full Access school_users"
  ON public.school_users FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Allow Hybrid Full Access posts" ON public.posts;
CREATE POLICY "Allow Hybrid Full Access posts"
  ON public.posts FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Allow Hybrid Full Access staff_directory" ON public.staff_directory;
CREATE POLICY "Allow Hybrid Full Access staff_directory"
  ON public.staff_directory FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Allow Hybrid Full Access facilities_gallery" ON public.facilities_gallery;
CREATE POLICY "Allow Hybrid Full Access facilities_gallery"
  ON public.facilities_gallery FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Allow Hybrid Full Access spmb_registrations" ON public.spmb_registrations;
CREATE POLICY "Allow Hybrid Full Access spmb_registrations"
  ON public.spmb_registrations FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Allow Hybrid Full Access public_complaints" ON public.public_complaints;
CREATE POLICY "Allow Hybrid Full Access public_complaints"
  ON public.public_complaints FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- ============================================================================
-- INDEKS PERFORMA QUERY & TRIGGER OTOMATIS UPDATED_AT (TERBARU)
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_posts_category_created ON public.posts (category, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_staff_category ON public.staff_directory (category, created_at ASC);
CREATE INDEX IF NOT EXISTS idx_facilities_gallery_type ON public.facilities_gallery (item_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_spmb_nisn_reg ON public.spmb_registrations (nisn, reg_number);
CREATE INDEX IF NOT EXISTS idx_school_users_username ON public.school_users (username);

-- Fungsi & Trigger untuk memperbarui kolom updated_at secara otomatis pada school_settings
CREATE OR REPLACE FUNCTION public.update_school_settings_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_school_settings_timestamp ON public.school_settings;
CREATE TRIGGER trg_update_school_settings_timestamp
  BEFORE UPDATE ON public.school_settings
  FOR EACH ROW
  EXECUTE FUNCTION public.update_school_settings_timestamp();

-- Pastikan minimal terdapat 1 baris konfigurasi awal pada school_settings agar siap digunakan
INSERT INTO public.school_settings (
  school_name,
  highlight_1,
  highlight_2,
  highlight_3,
  principal_name,
  address,
  phone,
  email,
  maps_url,
  instagram_url,
  youtube_url,
  tiktok_url
)
SELECT
  'SMP Negeri 71 Kota Bandung',
  'Terakreditasi A Unggul',
  'Kelas Digital Cerdas',
  'Sekolah Ramah Anak',
  'Dr. H. Ahmad Suryana, M.Pd.',
  'Jl. Pendidikan Raya No. 71, Kota Bandung, Jawa Barat 40292',
  '(022) 7100071',
  'info@smpn71bandung.sch.id',
  'https://www.google.com/maps?q=SMP+Negeri+71+Kota+Bandung&output=embed',
  'https://www.instagram.com/smpn71bandung',
  'https://www.youtube.com/@smpn71bandung',
  'https://www.tiktok.com/@smpn71bandung'
WHERE NOT EXISTS (SELECT 1 FROM public.school_settings LIMIT 1);
