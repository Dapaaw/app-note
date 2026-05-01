# Note-Taking App Flutter

Aplikasi pencatatan sederhana berbasis Flutter untuk kebutuhan tugas praktikum mobile.

Aplikasi ini memungkinkan pengguna membuat, mengedit, dan menghapus catatan dengan penyimpanan lokal berbasis file. Setiap catatan juga dapat memiliki lampiran gambar (maksimal 3 gambar) yang dikompresi agar penyimpanan lebih efisien.

## Fitur Utama

- Menampilkan daftar seluruh catatan.
- Menambah catatan baru.
- Mengedit catatan yang sudah ada.
- Menghapus catatan beserta lampiran gambar secara permanen.
- Menyimpan data catatan ke local storage (bukan database online).
- Lampiran gambar hingga 3 file per catatan.
- Kompresi gambar otomatis sebelum disimpan.

## Tampilan Aplikasi

Alur utama aplikasi:

1. Halaman daftar catatan.
2. Tombol tambah untuk membuat catatan baru.
3. Halaman editor untuk judul, isi, dan lampiran gambar.
4. Tombol simpan di AppBar.

> Opsional: tambahkan screenshot di folder `assets/screenshots/` lalu sisipkan ke README agar dokumentasi makin menarik.

## Teknologi yang Digunakan

- Flutter (Material 3)
- Dart
- Package:
	- `path_provider` untuk akses direktori dokumen aplikasi
	- `path` untuk manajemen path file/folder
	- `image_picker` untuk memilih gambar dari galeri
	- `flutter_image_compress` untuk kompresi gambar

## Struktur Folder Penting

```text
lib/
	main.dart
	helpers/
		file_helper.dart       # Operasi file: simpan, baca, hapus catatan & gambar
	models/
		note.dart              # Model data catatan
	screens/
		note_list_screen.dart  # Halaman daftar catatan
		note_editor_screen.dart# Halaman editor catatan
```

## Cara Menjalankan Proyek

### 1. Clone repository

```bash
git clone <url-repository>
cd flutter_application_1
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Jalankan aplikasi

```bash
flutter run
```

## Mekanisme Penyimpanan Data

Data catatan disimpan di direktori dokumen aplikasi dengan pola:

```text
notes/
	note_<timestamp>/
		content.txt
		image_1.jpg
		image_2.jpg
		image_3.jpg
```

Keterangan:

- `content.txt`: baris pertama adalah judul, baris berikutnya adalah isi catatan.
- File gambar bersifat opsional sesuai jumlah lampiran yang dipilih pengguna.

## Validasi dan Batasan

- Catatan tidak dapat disimpan jika judul dan isi sama-sama kosong.
- Maksimal 3 gambar per catatan.
- Jika gambar lama dihapus saat edit, file gambar terkait ikut dihapus dari penyimpanan.



