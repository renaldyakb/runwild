enum ReleaseNoteKind { heading, bullet, paragraph }

typedef ReleaseNote = ({ReleaseNoteKind kind, String text});

/// Converts the supported release-note Markdown subset into display blocks.
List<ReleaseNote> parseReleaseNotes(String markdown) {
  final notes = <ReleaseNote>[];
  var inCode = false;
  for (final raw in markdown.split('\n')) {
    var line = raw.trim();
    if (line.startsWith('```')) {
      inCode = !inCode;
      continue;
    }
    if (inCode || line.isEmpty || RegExp(r'^[-*_]{3,}$').hasMatch(line)) {
      continue;
    }
    final heading = RegExp(r'^#{1,6}\s+');
    final bullet = RegExp(r'^(?:[-*+]\s+|\d+[.)]\s+)');
    final kind = heading.hasMatch(line)
        ? ReleaseNoteKind.heading
        : bullet.hasMatch(line)
        ? ReleaseNoteKind.bullet
        : ReleaseNoteKind.paragraph;
    line = line.replaceFirst(heading, '').replaceFirst(bullet, '');
    line = line.replaceAllMapped(
      RegExp(r'!?\[([^\]]+)\]\([^)]*\)'),
      (match) => match.group(1) ?? '',
    );
    line = line.replaceAll(RegExp(r'[`*_]'), '').trim();
    if (line.isNotEmpty) notes.add((kind: kind, text: line));
  }
  return List.unmodifiable(notes);
}
