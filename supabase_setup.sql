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

-- Inisialisasi data pos terpadu awal (Berita, Pengumuman, Agenda, Akademik, Layanan, PPID)
INSERT INTO public.posts (category, title, content, image_url, file_url, file_name, event_date, author_name)
SELECT d.category, d.title, d.content, d.image_url, d.file_url, d.file_name, d.event_date::date, d.author_name
FROM (VALUES
  ('berita', 'Siswa SMPN 71 Kota Bandung Raih Medali Emas Olimpiade Sains Nasional Tingkat Kota', 'Tim Olimpiade IPA dan Matematika SMPN 71 Kota Bandung berhasil menorehkan prestasi membanggakan pada ajang OSN tingkat Kota Bandung tahun ini melalui pembinaan intensif.', 'https://images.unsplash.com/photo-1523240795612-9a054b0db644?auto=format&fit=crop&w=800&q=80', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'Piagam_Penghargaan_OSN_2026.pdf', '2026-05-10', 'Humas SMPN 71'),
  ('berita', 'Peluncuran Program Kelas Digital Cerdas & Fasilitas Laboratorium Modern Terpadu', 'SMPN 71 Bandung meresmikan integrasi modul pembelajaran digital interaktif dan 40 unit PC modern untuk mendukung akselerasi Kurikulum Nasional berbasis teknologi.', 'https://images.unsplash.com/photo-1581092921461-eab62e97a780?auto=format&fit=crop&w=800&q=80', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'Modul_Kelas_Digital_71.pdf', '2026-05-18', 'Tim Kurikulum'),
  ('berita', 'SMPN 71 Bandung Sabet Juara Umum Pasanggiri Seni Budaya Tradisional Sunda', 'Kontingen ekstrakurikuler seni tari Jaipong dan rampak angklung SMPN 71 berhasil mempertahankan gelar Juara Umum pada festival seni pelajar se-Kota Bandung.', 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?auto=format&fit=crop&w=800&q=80', '', '', '2026-05-25', 'Pembina Kesiswaan'),
  ('pengumuman', 'Jadwal Pelaksanaan Sistem Penerimaan Murid Baru (SPMB) Tahun Ajaran 2026/2027', 'Pendaftaran SPMB SMPN 71 Kota Bandung dibuka untuk Jalur Zonasi, Afirmasi, Prestasi, dan Perpindahan Tugas Orang Tua. Pastikan seluruh berkas persyaratan telah dipindai.', 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?auto=format&fit=crop&w=800&q=80', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'Juknis_SPMB_SMPN71_2026.pdf', '2026-06-01', 'Panitia SPMB'),
  ('pengumuman', 'Edaran Pelaksanaan Asesmen Sumatif Akhir Jenjang & Program Pengayaan Terpadu', 'Seluruh peserta didik kelas VII, VIII, dan IX diwajibkan mempersiapkan perangkat asesmen mandiri serta mematuhi tata tertib asesmen yang telah ditetapkan pihak sekolah.', 'https://images.unsplash.com/photo-1509062522246-3755977927d7?auto=format&fit=crop&w=800&q=80', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'Jadwal_Asesmen_Akhir_Jenjang.pdf', '2026-06-08', 'Wakasek Kurikulum'),
  ('pengumuman', 'Undangan Sosialisasi Parenting & Pertemuan Komite Sekolah Semester Genap', 'Mengundang seluruh orang tua/wali murid untuk menghadiri pemaparan evaluasi hasil belajar, pembinaan karakter ramah anak, dan transparansi program sekolah.', 'https://images.unsplash.com/photo-1529390079861-591de354faf5?auto=format&fit=crop&w=800&q=80', '', '', '2026-06-15', 'Humas & Komite'),
  ('agenda', 'Gelar Karya Projek Penguatan Profil Pelajar Pancasila (P5) & Pentas Seni Siswa', 'Kegiatan pameran produk kewirausahaan daur ulang, kuliner tradisional Sunda, dan apresiasi seni siswa kelas VII, VIII, dan IX di lapangan utama sekolah.', 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?auto=format&fit=crop&w=800&q=80', '', '', '2026-06-20', 'Tim Fasilitator P5'),
  ('agenda', 'Latihan Dasar Kepemimpinan Siswa (LDKS) & Musyawarah Besar Pengurus OSIS 71', 'Pembekalan kepemimpinan, manajemen organisasi siswa, kedisiplinan, dan perumusan kalender kerja OSIS SMPN 71 Kota Bandung periode 2026/2027.', 'https://images.unsplash.com/photo-1577896851231-70ef18881754?auto=format&fit=crop&w=800&q=80', '', '', '2026-06-27', 'Pembina OSIS'),
  ('agenda', 'Pekan Literasi Digital & Bedah Buku Karya Siswa di Graha Literasi SMPN 71', 'Festival literasi tahunan sekolah menghadirkan bedah buku antologi puisi karya siswa, lokakarya penulisan kreatif, serta penghargaan duta baca sekolah.', 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?auto=format&fit=crop&w=800&q=80', '', '', '2026-07-04', 'Koordinator Literasi'),
  ('akademik', 'Implementasi Kurikulum Nasional & Modul Pembelajaran Digital Terpadu', 'SMPN 71 Kota Bandung menerapkan pembelajaran terdiferensiasi dengan dukungan Google Workspace for Education, Laboratorium Komputer, dan Klinik Numerasi-Literasi.', 'https://images.unsplash.com/photo-1509062522246-3755977927d7?auto=format&fit=crop&w=800&q=80', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'Panduan_Kurikulum_Merdeka_71.pdf', '2026-05-02', 'Tim Kurikulum'),
  ('layanan_siswa', 'Layanan Bimbingan Konseling (BK) Ramah Anak & Pembinaan 12 Ekstrakurikuler', 'Tersedia layanan konseling minat bakat, pencegahan perundungan (Roots Indonesia), serta 12 cabang ekstrakurikuler unggulan seperti Pramuka, Paskibra, Futsal, Robotik, dan Angklung.', 'https://images.unsplash.com/photo-1529390079861-591de354faf5?auto=format&fit=crop&w=800&q=80', '', '', '2026-05-05', 'Koordinator Kesiswaan'),
  ('ppid', 'Laporan Realisasi Penggunaan Dana BOS Reguler & Standar Pelayanan Publik', 'Dokumen informasi publik berkala terkait transparansi anggaran sekolah, RKAS, serta standar operasional prosedur layanan pendidikan gratis tanpa pungutan.', 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?auto=format&fit=crop&w=800&q=80', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'Laporan_Realisasi_BOS_Reguler_2026.pdf', '2026-04-28', 'Pejabat PPID Sekolah')
) AS d(category, title, content, image_url, file_url, file_name, event_date, author_name)
WHERE NOT EXISTS (SELECT 1 FROM public.posts LIMIT 1);

-- Inisialisasi data galeri foto, fasilitas, video & TikTok sekolah
INSERT INTO public.facilities_gallery (item_type, title, description, media_url, condition_or_tag)
SELECT d.item_type, d.title, d.description, d.media_url, d.condition_or_tag
FROM (VALUES
  ('fasilitas', 'Laboratorium Sains & Komputer Terpadu', 'Dilengkapi 40 unit PC modern, jaringan fiber optik cepat, dan alat praktikum IPA berstandar nasional.', 'https://images.unsplash.com/photo-1581092921461-eab62e97a780?auto=format&fit=crop&w=800&q=80', 'Kondisi Sangat Baik'),
  ('fasilitas', 'Perpustakaan Digital Graha Literasi 71', 'Ruang baca berpendingin udara dengan koleksi ribuan buku fisik dan e-book digital Kurikulum Nasional.', 'https://images.unsplash.com/photo-1521587760476-6c12a4b040da?auto=format&fit=crop&w=800&q=80', 'Fasilitas Unggulan'),
  ('foto', 'Upacara Peringatan Hari Pendidikan Nasional & Apresiasi Siswa Berprestasi', 'Penyerahan piala kejuaraan tingkat Kota Bandung oleh Kepala Sekolah di lapangan utama sekolah.', 'https://images.unsplash.com/photo-1577896851231-70ef18881754?auto=format&fit=crop&w=800&q=80', 'Kegiatan Sekolah'),
  ('foto', 'Pentas Apresiasi Seni Budaya & Kolosal Musik Tradisional Angklung', 'Dokumentasi harmoni angklung kolosal dan tarian daerah Sunda yang dibawakan murid kelas VII & VIII.', 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?auto=format&fit=crop&w=800&q=80', 'Dokumentasi Ekskul'),
  ('video', 'Video Profil Resmi SMP Negeri 71 Kota Bandung', 'Mengenal lebih dekat budaya akademik, fasilitas modern, dan kegiatan siswa SMPN 71 Kota Bandung.', 'https://www.youtube.com/embed/ScMzIvxBSi4', 'Video Profil YouTube'),
  ('tiktok', 'Keseruan Pentas Seni & Kreativitas Ekskul Siswa SMPN 71', 'Kompilasi momen seru dan dokumentasi reels/video pendek siswa di TikTok resmi.', 'https://www.tiktok.com/@smpn71bandung', 'Video TikTok Resmi'),
  ('gdrive', 'Dokumentasi Album Foto Resolusi Tinggi (Google Drive)', 'Akses folder Google Drive resmi untuk mengunduh arsip foto kegiatan sekolah kualitas asli.', 'https://drive.google.com/drive/folders/1SMPN71BandungDokumentasiResmi', 'Google Drive Sekolah')
) AS d(item_type, title, description, media_url, condition_or_tag)
WHERE NOT EXISTS (SELECT 1 FROM public.facilities_gallery LIMIT 1);

-- Inisialisasi data direktori GTK awal
INSERT INTO public.staff_directory (full_name, nip, position, subject, photo_url, category)
SELECT d.full_name, d.nip, d.position, d.subject, d.photo_url, d.category
FROM (VALUES
  ('Dra. Hj. Ratna Ningsih, M.M.Pd.', '197204121998022001', 'Wakil Kepala Sekolah Bidang Kurikulum', 'Matematika', 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=500&q=80', 'Pendidik'),
  ('Dedi Kusnandar, S.AP.', '198108192009011004', 'Kepala Urusan Tata Usaha', 'Administrasi Kepegawaian & Sarpras', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=500&q=80', 'Tenaga Kependidikan')
) AS d(full_name, nip, position, subject, photo_url, category)
WHERE NOT EXISTS (SELECT 1 FROM public.staff_directory LIMIT 1);

-- ============================================================================
-- SINKRONISASI REALTIME SUPABASE DUA ARAH (INSTANT MULTI-DEVICE SYNC)
-- Mengaktifkan replikasi websocket realtime agar perubahan data langsung tampil
-- tanpa perlu reload halaman di komputer, laptop, tablet, dan smartphone
-- ============================================================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    BEGIN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.school_settings;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.posts;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.staff_directory;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.facilities_gallery;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.spmb_registrations;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.public_complaints;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.school_users;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
  END IF;
END $$;
