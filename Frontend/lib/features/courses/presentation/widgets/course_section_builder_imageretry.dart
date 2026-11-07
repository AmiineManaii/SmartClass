part of '../pages/course_section_builder_page.dart';
class _ImageRetry {
  final bool regenerate;
  final String? query;

  const _ImageRetry.regenerate() : regenerate = true, query = null;

  const _ImageRetry.refine(this.query) : regenerate = false;
}

/// Shown when the web image search returns no candidate for a section.
/// Offers two honest escapes: regenerate the search as-is, or refine the
/// query (e.g. "diagramme base de données") and search again.
