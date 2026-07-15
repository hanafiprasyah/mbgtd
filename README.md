# 📱 MBGTD Apps (Makan Bergizi Gratis Team Dashboard)

Aplikasi MBGTD Apps adalah sistem manajemen operasional relawan yang dirancang untuk mendukung program Makan Bergizi Gratis. Aplikasi ini mengintegrasikan fitur absensi berbasis QR, pengelolaan relawan, payroll berbasis snapshot + pool system, inventaris yayasan, serta reporting otomatis dalam format Excel.

---

## 🎯 Tujuan Aplikasi

- Mempermudah proses absensi relawan dengan QR Code
- Mengelola data relawan secara terstruktur (CRUD)
- Menghitung dan mendistribusikan gaji secara adil dengan sistem pool
- Menyediakan laporan otomatis (Excel)
- Mengelola inventaris yayasan
- Menyediakan panduan menu ahli gizi (Manual Book)

---

## ✨ Fitur Utama

### 📸 1. Absensi QR Code

- Scan QR untuk kehadiran relawan
- Mendukung:
  - Full Day
  - Half Day (0.5)
- Riwayat absensi harian tersimpan

---

### 👤 2. Manajemen Relawan (CRUD)

- Tambah, edit, hapus relawan
- Informasi yang dikelola:
  - Nama
  - Tim
  - Posisi
  - Status aktif/nonaktif

---

### 💰 3. Payroll System (Snapshot + Pool)

#### 🔹 Snapshot Harian

- Data kehadiran disimpan per hari
- Menghindari perubahan data historis

#### 🔹 Pool System

- Jika ada relawan tidak hadir / half-day:
  - Kekurangan akan dibagi ke tim
- Perhitungan berbasis:
  - Jumlah anggota tim
  - Base salary
  - Total kehadiran

#### Contoh:

Tanggal: 26 Mei 2026 Tim: Pencucian Total: 10 orang Hadir: 9 orang 1 orang half-day (0.5) Pool akan menghitung kekurangan dan dibagi ke anggota lain

---

### 📊 4. Report Excel

Export laporan otomatis berisi:

- Daftar kehadiran relawan
- Gaji per relawan
- Total gaji per tim
- Total keseluruhan gaji

Format file: .xlsx

---

### 📦 5. Manajemen Inventaris (CRUD)

Mengelola aset yayasan seperti:

- Alat masak
- Sendok & piring
- Kursi & meja
- Sandal anti-slip
- dll

Fitur:

- Tambah barang
- Edit stok
- Hapus data
- Tracking jumlah

---

### 🥗 6. Manual Book Ahli Gizi

Panduan menu makanan yang berisi:

- Nama menu
- Foto makanan
- Kandungan AKG (Angka Kecukupan Gizi)
- Catatan / referensi

---

## 🧠 Konsep Sistem

### 🔸 Attendance System

- QR-based scanning
- Status kehadiran fleksibel (1 / 0.5)

### 🔸 Payroll Engine

- Snapshot-based (immutable data)
- Pool redistribution system

## 🛠️ Teknologi (Stack)

- Frontend: Flutter (Material 3)
- Backend: Firebase / REST API
- Database: Firestore
- Export: Excel Generator

---

## 🚀 Future Improvements

- Dashboard analytics (grafik gaji & kehadiran)
- Role-based access (Admin, Staff, Nutritionist)
- Notifikasi absensi
- Integrasi AI untuk rekomendasi menu gizi
- Auto scheduling relawan

---

## 👨‍💻 Author

Developed by:
Mandora

---

## 📌 Catatan

Aplikasi ini dibuat untuk mendukung operasional program MBG di masing-masing dapur SPPG dengan efisiensi tinggi dan transparansi dalam pengelolaan relawan serta distribusi gaji.

---

> “Sistem yang baik bukan hanya mencatat, tapi memastikan keadilan terasa.”
