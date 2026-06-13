import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../models/note.dart';

class FileHelper {
  static final FileHelper _instance = FileHelper._internal();
  static const String _metadataPrefix = '__meta__|';
  FileHelper._internal();
  factory FileHelper() => _instance;

  String _encodeMetadata({
    required bool isPinned,
    required bool isArchived,
    required List<String> tags,
  }) {
    final metadataParts = <String>[
      'pinned=${isPinned ? 1 : 0}',
      'archived=${isArchived ? 1 : 0}',
    ];
    if (tags.isNotEmpty) {
      final encodedTags = tags.map(Uri.encodeComponent).join(',');
      metadataParts.add('tags=$encodedTags');
    }
    return '$_metadataPrefix${metadataParts.join('|')}';
  }

  List<String> _decodeTags(String rawTags) {
    if (rawTags.trim().isEmpty) return const [];
    return rawTags
        .split(',')
        .map((tag) => Uri.decodeComponent(tag).trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

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
  Future<void> saveNote(
    String noteId,
    String title,
    String content, {
    bool isPinned = false,
    bool isArchived = false,
    List<String> tags = const [],
  }) async {
    final notesDir = await _getNotesDirectory();
    final noteDir = Directory(join(notesDir.path, noteId));
    if (!await noteDir.exists()) {
      await noteDir.create(recursive: true);
    }
    final file = File(join(noteDir.path, 'content.txt'));
    final metadataLine = _encodeMetadata(
      isPinned: isPinned,
      isArchived: isArchived,
      tags: tags,
    );
    await file.writeAsString('$metadataLine\n$title\n$content');
  }

  // Membaca satu catatan berdasarkan identitas uniknya
  Future<Note?> readNote(String noteId) async {
    final notesDir = await _getNotesDirectory();
    final file = File(join(notesDir.path, noteId, 'content.txt'));
    if (!await file.exists()) return null;

    final rawContent = await file.readAsString();
    final lines = rawContent.split('\n');

    bool isPinned = false;
    bool isArchived = false;
    List<String> tags = const [];
    int titleIndex = 0;
    if (lines.isNotEmpty && lines.first.startsWith(_metadataPrefix)) {
      final metadata = lines.first.substring(_metadataPrefix.length);
      final parts = metadata.split('|');
      for (final part in parts) {
        final keyValue = part.split('=');
        if (keyValue.length != 2) continue;
        final key = keyValue[0];
        final value = keyValue[1];
        if (key == 'pinned') {
          isPinned = value == '1';
        } else if (key == 'archived') {
          isArchived = value == '1';
        } else if (key == 'tags') {
          tags = _decodeTags(value);
        }
      }
      titleIndex = 1;
    }

    final title = lines.length > titleIndex ? lines[titleIndex] : '';
    final content = lines.length > titleIndex + 1
        ? lines.sublist(titleIndex + 1).join('\n')
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
      isPinned: isPinned,
      isArchived: isArchived,
      tags: tags,
    );
  }

  // Memindai seluruh catatan yang tersimpan di penyimpanan
  Future<List<Note>> getAllNotes({bool includeArchived = false}) async {
    final notesDir = await _getNotesDirectory();
    final List<String> noteIds = [];

    await for (final entity in notesDir.list()) {
      if (entity is Directory) {
        noteIds.add(entity.path.split(Platform.pathSeparator).last);
      }
    }

    final List<Note> notes = [];
    for (final id in noteIds) {
      final note = await readNote(id);
      if (note == null) continue;
      if (!includeArchived && note.isArchived) continue;
      notes.add(note);
    }

    notes.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.id.compareTo(a.id);
    });

    return notes;
  }

  Future<void> setNotePinned(String noteId, bool isPinned) async {
    final note = await readNote(noteId);
    if (note == null) return;
    await saveNote(
      noteId,
      note.title,
      note.content,
      isPinned: isPinned,
      isArchived: note.isArchived,
      tags: note.tags,
    );
  }

  Future<void> setNoteArchived(String noteId, bool isArchived) async {
    final note = await readNote(noteId);
    if (note == null) return;
    await saveNote(
      noteId,
      note.title,
      note.content,
      isPinned: note.isPinned,
      isArchived: isArchived,
      tags: note.tags,
    );
  }

  Future<void> setNoteTags(String noteId, List<String> tags) async {
    final note = await readNote(noteId);
    if (note == null) return;
    await saveNote(
      noteId,
      note.title,
      note.content,
      isPinned: note.isPinned,
      isArchived: note.isArchived,
      tags: tags,
    );
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