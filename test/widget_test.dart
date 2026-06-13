import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:flutter_application_1/helpers/file_helper.dart';
import 'package:flutter_application_1/main.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.tempPath);

  final String tempPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;
}

Future<void> _pumpForAsyncWork(WidgetTester tester, {int cycles = 8}) async {
  for (int i = 0; i < cycles; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late PathProviderPlatform originalPlatform;

  setUpAll(() {
    originalPlatform = PathProviderPlatform.instance;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('app_note_test_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  tearDownAll(() {
    PathProviderPlatform.instance = originalPlatform;
  });

  testWidgets('Membuka editor dari daftar catatan', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await _pumpForAsyncWork(tester);

    expect(find.text('Catatan'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Catatan Baru'), findsOneWidget);
  });

  testWidgets('Menyimpan catatan baru lalu tampil di daftar', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await _pumpForAsyncWork(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Belajar Flutter');
    await tester.enterText(fields.at(1), 'Target: naik level jadi expert.');
    await tester.enterText(fields.at(2), 'flutter, belajar');

    await tester.tap(find.byIcon(Icons.save));
    await _pumpForAsyncWork(tester, cycles: 12);

    expect(find.text('Belajar Flutter'), findsOneWidget);
  });

  testWidgets('Menampilkan validasi saat judul dan isi kosong', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await _pumpForAsyncWork(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.save));
    await tester.pump();

    expect(find.text('Judul atau isi catatan tidak boleh kosong.'), findsWidgets);
  });

  test('Tag tersimpan dan terbaca dari storage lokal', () async {
    final fileHelper = FileHelper();
    final noteId = fileHelper.generateNoteId();

    await fileHelper.saveNote(
      noteId,
      'Catatan Tag',
      'Isi catatan dengan tag.',
      tags: const ['flutter', 'belajar'],
    );

    final note = await fileHelper.readNote(noteId);
    expect(note, isNotNull);
    expect(note!.tags, containsAll(<String>['flutter', 'belajar']));
  });

  test('Catatan terarsip disembunyikan dari daftar utama', () async {
    final fileHelper = FileHelper();
    final noteId = fileHelper.generateNoteId();

    await fileHelper.saveNote(
      noteId,
      'Catatan Arsip',
      'Isi catatan arsip.',
      isArchived: true,
    );

    final activeNotes = await fileHelper.getAllNotes();
    final archivedNotes = await fileHelper.getAllNotes(includeArchived: true);

    expect(activeNotes.any((note) => note.id == noteId), isFalse);
    expect(archivedNotes.any((note) => note.id == noteId && note.isArchived), isTrue);
  });

}
