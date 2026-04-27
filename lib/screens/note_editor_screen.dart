// lib/screens/note_editor_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/note.dart';
import '../helpers/file_helper.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  // Deklarasi variabel controller yang terlewat di kodemu sebelumnya
  final FileHelper _fileHelper = FileHelper();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isSaving = false;

  // UBAH 1: Gunakan Map untuk melacak 3 slot gambar (1, 2, dan 3)
  final Map<int, File?> _imageFiles = {1: null, 2: null, 3: null};
  final Map<int, bool> _hasExistingImages = {1: false, 2: false, 3: false};

  bool get _isEditMode => widget.note != null;
  String get _noteId => widget.note?.id ?? _fileHelper.generateNoteId();
  late final String _resolvedNoteId;

  @override
  void initState() {
    super.initState();
    _resolvedNoteId = _noteId;
    if (_isEditMode) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      // UBAH 2: Panggil fungsi pemuatan 3 gambar
      _loadExistingImages();
    }
  }

  // UBAH 3: Fungsi memuat ketiga slot gambar menggunakan perulangan
  Future<void> _loadExistingImages() async {
    for (int i = 1; i <= 3; i++) {
      final imageFile = await _fileHelper.getNoteImageFile(_resolvedNoteId, i);
      if (mounted && imageFile != null) {
        setState(() {
          _imageFiles[i] = imageFile;
          _hasExistingImages[i] = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // Memilih beberapa gambar sekaligus lalu mengisi slot kosong hingga maksimal 3
  Future<void> _pickImage() async {
    final emptySlots = <int>[];
    for (int i = 1; i <= 3; i++) {
      if (_imageFiles[i] == null) {
        emptySlots.add(i);
      }
    }

    if (emptySlots.isEmpty) return;

    final picker = ImagePicker();
    final pickedImages = await picker.pickMultiImage(
      imageQuality: 100,
    );

    if (!mounted || pickedImages.isEmpty) return;

    final filesToAttach = pickedImages.take(emptySlots.length).toList();
    setState(() {
      for (int i = 0; i < filesToAttach.length; i++) {
        _imageFiles[emptySlots[i]] = File(filesToAttach[i].path);
      }
    });
  }

  // UBAH 5: Menghapus gambar cukup dengan mengosongkan nilai indeksnya
  void _removeImage(int index) {
    setState(() {
      _imageFiles[index] = null;
    });
  }

  // UBAH 6: Perbarui logika simpan untuk mengecek 3 slot gambar
  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul atau isi catatan tidak boleh kosong.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Simpan teks catatan
      await _fileHelper.saveNote(
        _resolvedNoteId,
        _titleController.text.trim(),
        _contentController.text.trim(),
      );

      // Cek satu per satu slot 1, 2, dan 3
      for (int i = 1; i <= 3; i++) {
        final currentFile = _imageFiles[i];
        final hadExisting = _hasExistingImages[i]!;

        if (currentFile != null) {
          // Jika ada gambar baru di slot ini, simpan
          if (!currentFile.path.contains(_resolvedNoteId)) {
            await _fileHelper.saveNoteImage(_resolvedNoteId, i, currentFile.path);
          }
        } else if (hadExisting) {
          // Jika sebelumnya ada gambar, tapi sekarang dihapus user, hapus file aslinya
          await _fileHelper.deleteNoteImage(_resolvedNoteId, i);
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan catatan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // UBAH 7: Widget khusus untuk menampilkan gambar berjajar ke samping (horizontal)
  Widget _buildImageSection() {
    final currentImageCount = _imageFiles.values.where((f) => f != null).length;
    final imageWidgets = <Widget>[];

    // Rangkai gambar yang ada
    for (int i = 1; i <= 3; i++) {
      if (_imageFiles[i] != null) {
        imageWidgets.add(
          Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                width: 150,
                height: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_imageFiles[i]!, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                top: 4,
                right: 12,
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.8),
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeImage(i), // Hapus berdasarkan indeks
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }

    if (currentImageCount < 3) {
      imageWidgets.add(
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 150,
            height: 150,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_photo_alternate_outlined),
                const SizedBox(height: 8),
                Text(
                  'Tambah gambar lagi',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${3 - currentImageCount} tersisa',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lampiran gambar ($currentImageCount/3)',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal, // Agar bisa di-scroll ke samping
          child: Row(children: imageWidgets),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Catatan' : 'Catatan Baru'),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.save),
                  tooltip: 'Simpan',
                  onPressed: _saveNote,
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Judul catatan',
                border: InputBorder.none,
              ),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: 'Tulis catatanmu di sini...',
                border: InputBorder.none,
              ),
              maxLines: null,
              minLines: 8,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            
            // UBAH 8: Panggil tampilan susunan gambar di sini
            _buildImageSection(),
            
          ],
        ),
      ),
    );
  }
}