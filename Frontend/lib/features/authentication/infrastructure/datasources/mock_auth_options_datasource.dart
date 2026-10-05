class AuthInterestOption {
  final String id;
  final String emoji;
  final String labelKey;

  const AuthInterestOption({
    required this.id,
    required this.emoji,
    required this.labelKey,
  });
}

class MockAuthOptionsDataSource {
  const MockAuthOptionsDataSource();

  List<String> institutions() => const [
        'Université Paris-Saclay',
        'Sorbonne Université',
        'Université Lyon 1',
        'Université de Montréal',
        'EPFL Lausanne',
      ];

  List<String> studyLevels() => const [
        'Licence 1 - Informatique',
        'Licence 3 - Informatique',
        'Master 1 - Informatique & Data Science',
        'Master 2 - Intelligence Artificielle',
        'Doctorat - Informatique',
      ];

  List<AuthInterestOption> interests() => const [
        AuthInterestOption(id: 'maths', emoji: '📐', labelKey: 'interest_maths'),
        AuthInterestOption(id: 'info', emoji: '💻', labelKey: 'interest_info'),
        AuthInterestOption(id: 'physics', emoji: '⚡', labelKey: 'interest_physics'),
        AuthInterestOption(id: 'bio', emoji: '🧬', labelKey: 'interest_bio'),
        AuthInterestOption(id: 'eco', emoji: '📈', labelKey: 'interest_eco'),
        AuthInterestOption(id: 'ai', emoji: '🤖', labelKey: 'interest_ai'),
        AuthInterestOption(id: 'lang', emoji: '🌍', labelKey: 'interest_lang'),
        AuthInterestOption(id: 'chem', emoji: '🧪', labelKey: 'interest_chem'),
      ];

  Map<String, Map<String, String>> interestLabels() => const {
        'interest_maths': {'fr': 'Mathématiques', 'en': 'Mathematics'},
        'interest_info': {'fr': 'Informatique', 'en': 'Computer Science'},
        'interest_physics': {'fr': 'Physique', 'en': 'Physics'},
        'interest_bio': {'fr': 'Biologie', 'en': 'Biology'},
        'interest_eco': {'fr': 'Économie & Gestion', 'en': 'Economics & Management'},
        'interest_ai': {'fr': 'Intelligence Artificielle', 'en': 'Artificial Intelligence'},
        'interest_lang': {'fr': 'Langues & Lettres', 'en': 'Languages & Literature'},
        'interest_chem': {'fr': 'Chimie', 'en': 'Chemistry'},
      };
}
