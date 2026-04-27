import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../models/note.dart';

class FileHelper {
  static final FileHelper _instance = FileHelper._internal();
  FileHelper._internal();
  factory FileHelper() => _instance;

  // Mendapatkan direktori notes dan memastikan keberadaannya
  Future<Directory> _getNotesDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final notesDir = Directory(join(docsDir.path, 'notes'));
    if (!await notesDir.exists()) {
      await notesDir.create(recursive: true);
    }
    return notesDir;
  }

  // Menghasilkan ID unik berbasis stempel waktu
  String generateNoteId() {
    return 'note_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Menyimpan catatan untuk fungsi tambah maupun ubah
  Future<void> saveNote(String noteId, String title, String content) async {
    final notesDir = await _getNotesDirectory();
    final noteDir = Directory(join(notesDir.path, noteId));
    if (!await noteDir.exists()) {
      await noteDir.create(recursive: true);
    }
    final file = File(join(noteDir.path, 'content.txt'));
    // Menyimpan judul pada baris pertama dan isi pada baris berikutnya
    await file.writeAsString('$title\n$content');
  }

  // Membaca satu catatan berdasarkan identitas uniknya
  Future<Note?> readNote(String noteId) async {
    final notesDir = await _getNotesDirectory();
    final file = File(join(notesDir.path, noteId, 'content.txt'));
    if (!await file.exists()) return null;

    final rawContent = await file.readAsString();
    final lines = rawContent.split('\n');
    final title = lines.first;
    final content = lines.length > 1
        ? lines.sublist(1).join('\n')
        : '';

    int count = 0;
    for (int i = 1; i <= 3; i++) {
      if (await File(join(notesDir.path, noteId, 'image_$i.jpg')).exists()) {
        count++;
      }
    }

    return Note(
      id: noteId,
      title: title,
      content: content,
      imageCount: count,
    );
  }

  // Memindai seluruh catatan yang tersimpan di penyimpanan
  Future<List<Note>> getAllNotes() async {
    final notesDir = await _getNotesDirectory();
    final List<String> noteIds = [];

    await for (final entity in notesDir.list()) {
      if (entity is Directory) {
        noteIds.add(entity.path.split(Platform.pathSeparator).last);
      }
    }

    // Mengurutkan ID dari yang terbaru
    noteIds.sort((a, b) => b.compareTo(a));

    final List<Note> notes = [];
    for (final id in noteIds) {
      final note = await readNote(id);
      if (note != null) notes.add(note);
    }
    return notes;
  }

  // Melakukan kompresi dan menyimpan gambar ke folder catatan
  Future<void> saveNoteImage(String noteId, int index, String sourcePath) async {
    final notesDir = await _getNotesDirectory();
    final noteDir = Directory(join(notesDir.path, noteId));
    if (!await noteDir.exists()) {
      await noteDir.create(recursive: true);
    }

    final originalBytes = await File(sourcePath).readAsBytes();

    final compressedBytes = await FlutterImageCompress.compressWithList(
      originalBytes,
      quality: 70,
      minWidth: 1080,
      minHeight: 1080,
      format: CompressFormat.jpeg,
    );

    final imageFile = File(join(noteDir.path, 'image_$index.jpg'));
    await imageFile.writeAsBytes(compressedBytes);
  }

  // Mengambil referensi berkas gambar catatan
  Future<File?> getNoteImageFile(String noteId, int index) async {
    final notesDir = await _getNotesDirectory();
    final imageFile = File(join(notesDir.path, noteId, 'image_$index.jpg'));
    if (!await imageFile.exists()) return null;
    return imageFile;
  }

  // Menghapus direktori catatan secara permanen
  Future<void> deleteNote(String noteId) async {
    final notesDir = await _getNotesDirectory();
    final noteDir = Directory(join(notesDir.path, noteId));
    if (await noteDir.exists()) {
      await noteDir.delete(recursive: true);
    }
  }

  Future<void> deleteNoteImage(String noteId, int index) async {
    final notesDir = await _getNotesDirectory();
    final imageFile = File(join(notesDir.path, noteId, 'image_$index.jpg'));
    if (await imageFile.exists()) {
      await imageFile.delete();
    }
  }

}