// lib/screens/note_list_screen.dart
import 'package:flutter/material.dart';
import '../models/note.dart';
import '../helpers/file_helper.dart';
import 'note_editor_screen.dart';

class NoteListScreen extends StatefulWidget {
  const NoteListScreen({super.key});

  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  final FileHelper _fileHelper = FileHelper();
  List<Note> _notes = [];
  bool _isLoading = true;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  // Mengambil data catatan dari sistem berkas
  Future<void> _loadNotes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final notes = await _fileHelper.getAllNotes(includeArchived: _showArchived);
      if (!mounted) return;
      setState(() {
        _notes = notes;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notes = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _togglePin(Note note) async {
    await _fileHelper.setNotePinned(note.id, !note.isPinned);
    _loadNotes();
  }

  Future<void> _toggleArchive(Note note) async {
    await _fileHelper.setNoteArchived(note.id, !note.isArchived);
    _loadNotes();
  }

  Future<void> _toggleArchivedView() async {
    setState(() {
      _showArchived = !_showArchived;
    });
    await _loadNotes();
  }

  List<Widget> _buildTagChips(List<String> tags) {
    return tags
        .take(3)
        .map(
          (tag) => Chip(
            label: Text(tag),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: BorderSide(color: Colors.blue.shade200),
            backgroundColor: Colors.blue.shade50,
          ),
        )
        .toList();
  }

  // Navigasi ke halaman editor dan memperbarui daftar saat kembali
  Future<void> _navigateToEditor({Note? note}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(note: note),
      ),
    );
    _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan'),
        actions: [
          IconButton(
            tooltip: _showArchived ? 'Kembali ke catatan aktif' : 'Lihat arsip',
            icon: Icon(_showArchived ? Icons.note_alt : Icons.archive_outlined),
            onPressed: _toggleArchivedView,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada catatan.\nTekan + untuk membuat catatan baru.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: note.imageCount > 0
                            ? const Icon(Icons.image, color: Colors.blue)
                            : const Icon(Icons.article_outlined, color: Colors.grey),
                        title: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                note.title.isEmpty ? '(Tanpa judul)' : note.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (note.isPinned) ...[
                              const SizedBox(width: 8),
                              Chip(
                                avatar: Icon(
                                  Icons.push_pin,
                                  size: 14,
                                  color: Colors.amber.shade800,
                                ),
                                label: const Text('Favorit'),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: Colors.amber.shade100,
                                side: BorderSide(color: Colors.amber.shade200),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (note.tags.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _buildTagChips(note.tags),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              note.content.isEmpty ? '(Tidak ada isi)' : note.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: note.isPinned ? 'Lepas favorit' : 'Favoritkan',
                              icon: Icon(
                                note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                                color: note.isPinned ? Colors.amber : Colors.grey,
                              ),
                              onPressed: () => _togglePin(note),
                            ),
                            IconButton(
                              tooltip: _showArchived ? 'Pulihkan' : 'Arsipkan',
                              icon: Icon(
                                _showArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                                color: Colors.blueGrey,
                              ),
                              onPressed: () => _toggleArchive(note),
                            ),
                          ],
                        ),
                        onTap: () => _navigateToEditor(note: note),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showArchived ? null : () => _navigateToEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }
}