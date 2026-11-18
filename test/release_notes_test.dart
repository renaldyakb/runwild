import 'package:flutter_test/flutter_test.dart';
import 'package:runwild/domain/release_notes.dart';

void main() {
  test('Legacy Markdown is converted to headings and readable bullets', () {
    final notes = parseReleaseNotes(
      '### RUNWILD\r\n\n'
      'Versi dari `main`.\n#### Berkas instalasi\n'
      '- **`app-release.apk`**: [Unduh](https://example.org)\n',
    );
    expect(notes, [
      (kind: ReleaseNoteKind.heading, text: 'RUNWILD'),
      (kind: ReleaseNoteKind.paragraph, text: 'Versi dari main.'),
      (kind: ReleaseNoteKind.heading, text: 'Berkas instalasi'),
      (kind: ReleaseNoteKind.bullet, text: 'app-release.apk: Unduh'),
    ]);
  });

  test('Empty notes stay empty and fenced build commands are omitted', () {
    expect(parseReleaseNotes(' \n'), isEmpty);
    expect(parseReleaseNotes('```sh\nflutter build apk\n```\n---'), isEmpty);
    expect(
      parseReleaseNotes('1. Perbaikan versi').single.kind,
      ReleaseNoteKind.bullet,
    );
  });
}
