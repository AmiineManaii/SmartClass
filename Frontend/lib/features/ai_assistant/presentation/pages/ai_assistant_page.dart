import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/extensions.dart';
import '../../../../core/theme/app_theme.dart';

/// Page du Tuteur IA Interactif SmartClass, alignée sur la maquette Stitch
/// screen `07906fe145374de184b839701ca0862a`.
class AiAssistantPage extends ConsumerStatefulWidget {
  const AiAssistantPage({super.key});

  @override
  ConsumerState<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends ConsumerState<AiAssistantPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isGenerating = false;
  String _selectedCourse = 'Algèbre Linéaire & Espaces Vectoriels';
  String _selectedChapter = 'Chapitre 3 : Théorème du Rang & Dimension';

  final List<String> _quickPrompts = [
    'Donne-moi un exemple concret 💡',
    'Générer un QCM d\'entraînement ⚡',
    'Résume le théorème en 3 points 📝',
    'Formule du Théorème du Rang 📐',
  ];

  @override
  void initState() {
    super.initState();
    // Message d'introduction pédagogique inspiré de la maquette Stitch
    _messages.add(
      _ChatMessage(
        text:
            'Bonjour ! Je suis votre Tuteur IA personnel SmartClass, synchronisé avec vos cours de L3 Informatique. Vous étudiez actuellement **$_selectedChapter** avec le Pr. Amine.\n\nPosez-moi vos questions, demandez des éclaircissements, ou générez des exercices d\'entraînement !',
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        stepTitle: 'Tuteur Connecté',
        hasFormula: false,
      ),
    );

    // Exemple de question/réponse initiale comme dans Stitch
    _messages.add(
      _ChatMessage(
        text:
            'Peux-tu m\'expliquer simplement la différence entre le Noyau Ker(f) et l\'Image Im(f) d\'une application linéaire ? Et le lien avec le Théorème du Rang ?',
        isUser: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
    );

    _messages.add(
      _ChatMessage(
        text:
            'Bonjour Salma ! Voici une explication claire et intuitive :\n\n'
            '• **Le Noyau (Ker(f))** : C\'est l\'ensemble de tous les vecteurs x envoyés sur le vecteur nul 0. En clair : tout ce que f « écrase » à zéro. Si Ker(f) = {0}, la fonction est injective.\n\n'
            '• **L\'Image (Im(f))** : C\'est l\'ensemble des vecteurs réellement atteints par f. Elle mesure l\'étendue effective de la transformation.\n\n'
            '• **Le Théorème du Rang (Rank-Nullity Theorem)** :\n'
            'C\'est un principe fondamental de conservation de la dimension :',
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        stepTitle: 'Explication pas-à-pas',
        hasFormula: true,
        formulaText: 'dim(E) = dim(Ker(f)) + rg(f)',
        ruleHighlight:
            'Toute dimension perdue dans le noyau est soustraite de l\'image finale ! rg(f) = dim(Im(f)).',
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? presetText]) async {
    final text = presetText ?? _controller.text.trim();
    if (text.isEmpty || _isGenerating) return;

    setState(() {
      _messages.add(
        _ChatMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isGenerating = true;
      if (presetText == null) {
        _controller.clear();
      }
    });

    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;

    final response = _generateTutorResponse(text);

    setState(() {
      _messages.add(response);
      _isGenerating = false;
    });

    _scrollToBottom();
  }

  _ChatMessage _generateTutorResponse(String query) {
    final lower = query.toLowerCase();

    if (lower.contains('exemple')) {
      return _ChatMessage(
        text:
            'Considérons la projection orthogonale f sur le plan (Oxy) dans R³ :\n\n'
            '• Tout vecteur (0, 0, z) est projeté sur (0, 0, 0), donc **Ker(f) est la droite (Oz)** (dimension 1).\n'
            '• Les images couvrent exactement le plan (Oxy), donc **rg(f) = 2**.\n'
            '• Vérification du Théorème du Rang : dim(R³) = 3 = 1 + 2. L\'égalité est parfaitement vérifiée !',
        isUser: false,
        timestamp: DateTime.now(),
        stepTitle: 'Exemple Visuel 3D',
        hasFormula: true,
        formulaText: 'dim(R³) = dim(Ker(f)) + rg(f)  <=>  3 = 1 + 2',
      );
    }

    if (lower.contains('qcm') || lower.contains('quiz')) {
      return _ChatMessage(
        text:
            'Voici un QCM express pour valider votre compréhension :\n\n'
            '**Question :** Soit f: R⁴ -> R³ une application linéaire. Si dim(Ker(f)) = 1, quel est le rang de f ?\n\n'
            'A) rg(f) = 1\n'
            'B) rg(f) = 2\n'
            'C) rg(f) = 3 (Surjective)\n'
            'D) rg(f) = 4',
        isUser: false,
        timestamp: DateTime.now(),
        stepTitle: 'Quiz d\'Entraînement ⚡',
        hasFormula: true,
        formulaText: 'dim(E) = 4  =>  rg(f) = 4 - 1 = 3',
        ruleHighlight: 'Réponse C ! f est donc surjective car rg(f) = dim(R³) = 3.',
      );
    }

    if (lower.contains('résum') || lower.contains('3 points')) {
      return _ChatMessage(
        text:
            'Voici la synthèse en 3 points essentiels :\n\n'
            '1. **Équilibre des dimensions** : La dimension de l\'espace de départ se répartit entre ce qui disparaît (Ker) et ce qui subsiste (Im).\n'
            '2. **Injectivité immédiate** : f est injective si et seulement si Ker(f) = {0}, soit dim(Ker(f)) = 0.\n'
            '3. **Surjectivité immédiate** : f est surjective si et seulement si rg(f) = dim(F).',
        isUser: false,
        timestamp: DateTime.now(),
        stepTitle: 'Synthèse en 3 Points',
        hasFormula: true,
        formulaText: 'f injective <=> Ker(f) = {0}   |   f surjective <=> rg(f) = dim(F)',
      );
    }

    if (lower.contains('formule') || lower.contains('rang')) {
      return _ChatMessage(
        text:
            'Le **Théorème du Rang** s\'applique à toute application linéaire f: E -> F avec E de dimension finie.\n\n'
            'Formule fondamentale :',
        isUser: false,
        timestamp: DateTime.now(),
        stepTitle: 'Formule Fondamentale',
        hasFormula: true,
        formulaText: 'dim(E) = dim(Ker(f)) + rg(f)',
        ruleHighlight: 'Attention au piège : c\'est toujours la dimension de l\'espace de DÉPART E !',
      );
    }

    return _ChatMessage(
      text:
          'Excellente réflexion ! Pour approfondir ce point sur **$_selectedChapter**, souhaitez-vous :\n'
          '1. Un exemple géométrique appliqué ?\n'
          '2. Un exercice de type partiel universitaire ?\n'
          '3. Une fiche récapitulative des pièges à éviter ?',
      isUser: false,
      timestamp: DateTime.now(),
      stepTitle: 'Assistance Personnalisée',
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showChangeCourseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.swap_horiz_rounded, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Changer de module'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CourseSelectTile(
              title: 'Algèbre Linéaire & Espaces Vectoriels',
              instructor: 'Prof. Amine',
              isSelected: _selectedCourse.contains('Algèbre'),
              onTap: () {
                setState(() {
                  _selectedCourse = 'Algèbre Linéaire & Espaces Vectoriels';
                  _selectedChapter = 'Chapitre 3 : Théorème du Rang & Dimension';
                });
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
            _CourseSelectTile(
              title: 'Algorithmique & Structures de Données',
              instructor: 'Prof. Bennani',
              isSelected: _selectedCourse.contains('Algorithmique'),
              onTap: () {
                setState(() {
                  _selectedCourse = 'Algorithmique Avancée';
                  _selectedChapter = 'Chapitre 2 : Arbres Binaires et Graphes';
                });
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
            _CourseSelectTile(
              title: 'Bases de Données & SQL Avancé',
              instructor: 'Prof. El Alami',
              isSelected: _selectedCourse.contains('Bases de Données'),
              onTap: () {
                setState(() {
                  _selectedCourse = 'Bases de Données & SQL';
                  _selectedChapter = 'Chapitre 4 : Normalisation & Formes Normales';
                });
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = context.screenWidth >= 1024;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF83F8CD), Color(0xFF8197FF)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF002116),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Tuteur IA Interactif',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'SmartClass Pedagogical AI • Aligné Université',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF83F8CD).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF0F9D78).withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 3, backgroundColor: Color(0xFF0F9D78)),
                SizedBox(width: 6),
                Text(
                  'En ligne',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003627),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Effacer la conversation',
            onPressed: () => _confirmClearHistory(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Banner de contexte du cours connecté
          _buildCourseContextBar(context),

          // Main Workspace
          Expanded(
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Colonne Principale : Chat Conversationnel (65%)
                      Expanded(
                        flex: 7,
                        child: _buildChatColumn(context),
                      ),
                      // Séparateur vertical
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: AppTheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                      // Colonne Droite Desktop : Fiches & Formules de Référence (35%)
                      Expanded(
                        flex: 5,
                        child: _buildDesktopReferenceRail(context),
                      ),
                    ],
                  )
                : _buildChatColumn(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseContextBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.menu_book_rounded,
              color: AppTheme.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _selectedCourse,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryFixed,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Aligné L3',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSecondaryFixed,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  _selectedChapter,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _showChangeCourseDialog(context),
            icon: const Icon(Icons.swap_horiz_rounded, size: 16),
            label: const Text('Changer'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatColumn(BuildContext context) {
    return Column(
      children: [
        // Message timeline
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: _messages.length + (_isGenerating ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length) {
                return _buildTypingIndicator(context);
              }
              return _buildRichMessage(context, _messages[index]);
            },
          ),
        ),

        // Quick prompt chips
        Container(
          height: 40,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _quickPrompts.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              return ActionChip(
                backgroundColor: AppTheme.surfaceContainerLowest,
                side: BorderSide(
                  color: AppTheme.outlineVariant.withValues(alpha: 0.4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                label: Text(
                  _quickPrompts[i],
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => _sendMessage(_quickPrompts[i]),
              );
            },
          ),
        ),

        // Input Area
        _buildInputBar(context),
      ],
    );
  }

  Widget _buildRichMessage(BuildContext context, _ChatMessage message) {
    final isUser = message.isUser;

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.timestamp.formatTime(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.done_all_rounded,
                    size: 14,
                    color: Color(0xFF83F8CD),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Tutor Message (Stitch Design)
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 32),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(
            color: AppTheme.outlineVariant.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tutor header badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryFixed,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.smart_toy_rounded,
                        color: AppTheme.primary,
                        size: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Tuteur IA SmartClass',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                if (message.stepTitle != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryFixed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message.stepTitle!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSecondaryFixed,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Text
            Text(
              message.text,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: AppTheme.onSurface,
              ),
            ),

            // Highlighted Formula Box if present
            if (message.hasFormula && message.formulaText != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      message.formulaText!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (message.ruleHighlight != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        message.ruleHighlight!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Action strip (Stitch design)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _TutorActionButton(
                      icon: Icons.volume_up_rounded,
                      label: 'Écouter',
                      onTap: () {
                        context.showInfoToast('Lecture vocale du tuteur en cours...');
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.content_copy_rounded, size: 16),
                      tooltip: 'Copier',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: message.text));
                        context.showSuccessToast('Explication copiée dans le presse-papier');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.thumb_up_outlined, size: 16),
                      tooltip: 'Explication claire',
                      onPressed: () {},
                    ),
                  ],
                ),
                const Text(
                  'Précision académique 99%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopReferenceRail(BuildContext context) {
    return Container(
      color: AppTheme.surfaceContainerLowest,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.style_rounded, color: AppTheme.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Fiches & Notions Clés',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.tertiaryFixed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Chapitre 3',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onTertiaryFixed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Reference cards list
          Expanded(
            child: ListView(
              children: [
                _ReferenceItemCard(
                  title: 'Théorème du Rang (Rank-Nullity)',
                  subtitle: 'dim(E) = dim(Ker(f)) + rg(f)',
                  badge: 'Incontournable',
                  badgeColor: Colors.amber,
                  description:
                      'La dimension de l\'espace de départ est la somme de la dimension du noyau et du rang de l\'application.',
                  onAskTutor: () => _sendMessage(
                    'Peux-tu me donner la démonstration du Théorème du Rang ?',
                  ),
                ),
                const SizedBox(height: 12),
                _ReferenceItemCard(
                  title: 'Injectivité & Noyau',
                  subtitle: 'f injective <=> Ker(f) = {0}',
                  badge: 'Propriété',
                  badgeColor: AppTheme.secondary,
                  description:
                      'Une application linéaire est injective si et seulement si son noyau est réduit au vecteur nul.',
                  onAskTutor: () => _sendMessage(
                    'Comment prouver concrètement qu\'un noyau est réduit à {0} ?',
                  ),
                ),
                const SizedBox(height: 12),
                _ReferenceItemCard(
                  title: 'Surjectivité & Image',
                  subtitle: 'f surjective <=> rg(f) = dim(F)',
                  badge: 'Propriété',
                  badgeColor: const Color(0xFF0F9D78),
                  description:
                      'f est surjective si le rang égale la dimension de l\'espace d\'arrivée F.',
                  onAskTutor: () => _sendMessage(
                    'Donne-moi un exemple d\'application non surjective.',
                  ),
                ),
                const SizedBox(height: 16),

                // Shortcut Banner to AI Quiz
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2D3E8C), Color(0xFF122675)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Envie de vous tester ?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Générez un QCM personnalisé de 5 questions sur ce chapitre.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => context.push('/ai-quiz'),
                        icon: const Icon(Icons.quiz_rounded, size: 16),
                        label: const Text('Lancer le Quiz ⚡'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: AppTheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.mic_none_rounded,
                color: AppTheme.onSurfaceVariant,
              ),
              tooltip: 'Dictée vocale',
              onPressed: () {
                context.showInfoToast('Microphone activé pour la dictée vocale');
              },
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Posez une question sur le cours au tuteur...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: AppTheme.outline.withValues(alpha: 0.8),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.attach_file_rounded, size: 20),
                      color: AppTheme.outline,
                      tooltip: 'Joindre un exercice ou formule',
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                onPressed: _isGenerating ? null : () => _sendMessage(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.smart_toy_rounded,
              color: AppTheme.primary,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Le tuteur IA rédige une explication...',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Effacer la conversation'),
        content: const Text(
          'Voulez-vous réinitialiser cette séance d\'étude avec le tuteur ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(
                  _ChatMessage(
                    text:
                        'Historique réinitialisé. Je suis prêt pour votre prochaine question sur **$_selectedCourse** !',
                    isUser: false,
                    timestamp: DateTime.now(),
                  ),
                );
              });
              Navigator.pop(ctx);
            },
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
  }
}

class _TutorActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TutorActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseSelectTile extends StatelessWidget {
  final String title;
  final String instructor;
  final bool isSelected;
  final VoidCallback onTap;

  const _CourseSelectTile({
    required this.title,
    required this.instructor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.08)
              : AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? AppTheme.primary : AppTheme.outline,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    instructor,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferenceItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final String description;
  final VoidCallback onAskTutor;

  const _ReferenceItemCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.description,
    required this.onAskTutor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onAskTutor,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Demander au Tuteur',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondary,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded,
                      size: 12, color: AppTheme.secondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? stepTitle;
  final bool hasFormula;
  final String? formulaText;
  final String? ruleHighlight;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.stepTitle,
    this.hasFormula = false,
    this.formulaText,
    this.ruleHighlight,
  });
}