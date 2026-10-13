/// Derives a save title from generated Markdown: first `# ` heading,
/// else the teacher's subject/topic fallback (both capped at 80 chars).
String deriveCourseTitle(String content, {String? fallback}) {
  for (final line in content.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.startsWith('#')) {
      final title = trimmed.replaceAll(RegExp(r'^#+\s*'), '').trim();
      if (title.isNotEmpty) {
        return title.length > 80 ? '${title.substring(0, 80)}…' : title;
      }
    }
  }
  final fb = (fallback ?? '').trim();
  if (fb.isEmpty) return 'Sans titre';
  return fb.length > 80 ? '${fb.substring(0, 80)}…' : fb;
}
