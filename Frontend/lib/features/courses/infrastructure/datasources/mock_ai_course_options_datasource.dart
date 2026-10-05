class AiSuggestionChip {
  final String id;
  final String icon;
  final String labelKey;

  const AiSuggestionChip({
    required this.id,
    required this.icon,
    required this.labelKey,
  });
}

class MockAiCourseOptionsDataSource {
  const MockAiCourseOptionsDataSource();

  List<String> subjects() => const [
        'Informatique & Algorithmique',
        'Bases de données',
        'Mathématiques',
        'Physique',
      ];

  List<String> levels() => const [
        'Licence 1 (Découverte)',
        'Licence 2 (Intermédiaire)',
        'Licence 3 (Intermédiaire / Avancé)',
        'Master 1 (Avancé)',
      ];

  List<AiSuggestionChip> suggestionChips() => const [
        AiSuggestionChip(id: 'plan', icon: 'format_list_numbered', labelKey: 'chip_detailed_plan'),
        AiSuggestionChip(id: 'quiz', icon: 'quiz', labelKey: 'chip_quiz'),
        AiSuggestionChip(id: 'exercises', icon: 'code_blocks', labelKey: 'chip_exercises'),
        AiSuggestionChip(id: 'cases', icon: 'cases', labelKey: 'chip_cases'),
      ];
}
