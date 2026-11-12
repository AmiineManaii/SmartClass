import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/widgets/smart_toast.dart';

enum NotesViewMode { split, editorOnly, previewOnly }

class TeacherReviewOverviewTab extends StatefulWidget {
  final TextEditingController titleCtrl;
  final TextEditingController shortSummaryCtrl;
  final TextEditingController detailedSummaryCtrl;
  final TextEditingController markdownCtrl;
  final bool isBusy;
  final ValueChanged<String> onRegenerateSection;

  const TeacherReviewOverviewTab({
    super.key,
    required this.titleCtrl,
    required this.shortSummaryCtrl,
    required this.detailedSummaryCtrl,
    required this.markdownCtrl,
    required this.isBusy,
    required this.onRegenerateSection,
  });

  @override
  State<TeacherReviewOverviewTab> createState() => _TeacherReviewOverviewTabState();
}

class _TeacherReviewOverviewTabState extends State<TeacherReviewOverviewTab> {
  NotesViewMode _viewMode = NotesViewMode.split;

  void _insertMarkdownSyntax(String prefix, String suffix) {
    final text = widget.markdownCtrl.text;
    final selection = widget.markdownCtrl.selection;
    if (!selection.isValid) {
      widget.markdownCtrl.text = '$text$prefix$suffix';
      return;
    }
    final selectedText = text.substring(selection.start, selection.end);
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '$prefix$selectedText$suffix',
    );
    widget.markdownCtrl.text = newText;
    widget.markdownCtrl.selection = TextSelection.collapsed(
      offset: selection.start + prefix.length + selectedText.length,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 1100;
    final effectiveMode = (!isWide && _viewMode == NotesViewMode.split)
        ? NotesViewMode.editorOnly
        : _viewMode;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _buildExecutiveSummaryCard(isDark),
        const SizedBox(height: 16),
        _buildMarkdownStudio(isDark, isWide, effectiveMode),
      ],
    );
  }

  Widget _buildExecutiveSummaryCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF6366F1).withValues(alpha: 0.35)
              : const Color(0xFF93C5FD),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.12 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'SYNTHÈSE EXÉCUTIVE IA',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF818CF8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '• Résumé automatique condensé',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.content_copy_rounded, size: 16),
                    tooltip: 'Copier la synthèse',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.detailedSummaryCtrl.text));
                      SmartToast.info(context, 'Synthèse copiée dans le presse-papier');
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                    label: const Text('Régénérer Synthèse', style: TextStyle(fontSize: 11.5)),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: widget.isBusy ? null : () => widget.onRegenerateSection('summary'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.titleCtrl,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: _inputDecor(
              label: 'Titre de la leçon / séance',
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: widget.detailedSummaryCtrl,
            maxLines: 4,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
            ),
            decoration: _inputDecor(
              label: 'Synthèse générale du cours (Executive Summary)',
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdownStudio(bool isDark, bool isWide, NotesViewMode mode) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.article_rounded, size: 18, color: Color(0xFF3B82F6)),
                    SizedBox(width: 8),
                    Text(
                      'Notes de cours structurées (Markdown)',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155).withValues(alpha: 0.6) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildModeBtn('Éditeur', Icons.edit_note_rounded, mode == NotesViewMode.editorOnly,
                          () => setState(() => _viewMode = NotesViewMode.editorOnly)),
                      if (isWide) ...[
                        const SizedBox(width: 2),
                        _buildModeBtn('Côte à côte', Icons.vertical_split_rounded, mode == NotesViewMode.split,
                            () => setState(() => _viewMode = NotesViewMode.split)),
                      ],
                      const SizedBox(width: 2),
                      _buildModeBtn('Aperçu', Icons.visibility_rounded, mode == NotesViewMode.previewOnly,
                          () => setState(() => _viewMode = NotesViewMode.previewOnly)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F1728) : const Color(0xFFF8FAFC),
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                _buildFormatBtn(Icons.format_bold_rounded, 'Gras', () => _insertMarkdownSyntax('**', '**')),
                _buildFormatBtn(Icons.format_italic_rounded, 'Italique', () => _insertMarkdownSyntax('*', '*')),
                _buildFormatBtn(Icons.title_rounded, 'Titre', () => _insertMarkdownSyntax('### ', '')),
                _buildFormatBtn(Icons.format_list_bulleted_rounded, 'Liste', () => _insertMarkdownSyntax('- ', '')),
                _buildFormatBtn(Icons.code_rounded, 'Code', () => _insertMarkdownSyntax('```\n', '\n```')),
                _buildFormatBtn(Icons.format_quote_rounded, 'Citation', () => _insertMarkdownSyntax('> ', '')),
                const Spacer(),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: const Text('Régénérer Notes', style: TextStyle(fontSize: 11.5)),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: widget.isBusy ? null : () => widget.onRegenerateSection('structuredNotes'),
                ),
              ],
            ),
          ),
          if (mode == NotesViewMode.split)
            SizedBox(
              height: 480,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      color: isDark ? const Color(0xFF090D18) : const Color(0xFFFAFAFA),
                      padding: const EdgeInsets.all(14),
                      child: TextField(
                        controller: widget.markdownCtrl,
                        maxLines: null,
                        expands: true,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, height: 1.45),
                        decoration: const InputDecoration(
                          hintText: 'Rédigez ou éditez les notes en Markdown...',
                          border: InputBorder.none,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: Container(
                      color: isDark ? const Color(0xFF101726) : Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        child: MarkdownBody(
                          data: widget.markdownCtrl.text.isNotEmpty ? widget.markdownCtrl.text : '*Aucune note rédigée*',
                          selectable: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (mode == NotesViewMode.editorOnly)
            Container(
              color: isDark ? const Color(0xFF090D18) : const Color(0xFFFAFAFA),
              padding: const EdgeInsets.all(14),
              constraints: const BoxConstraints(minHeight: 320),
              child: TextField(
                controller: widget.markdownCtrl,
                maxLines: 18,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.45),
                decoration: const InputDecoration(
                  hintText: 'Rédigez ou éditez les notes en Markdown...',
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              ),
            )
          else
            Container(
              color: isDark ? const Color(0xFF101726) : Colors.white,
              padding: const EdgeInsets.all(18),
              constraints: const BoxConstraints(minHeight: 320),
              child: MarkdownBody(
                data: widget.markdownCtrl.text.isNotEmpty ? widget.markdownCtrl.text : '*Aucune note rédigée*',
                selectable: true,
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecor({required String label, required bool isDark}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 12,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF0D1424) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155).withValues(alpha: 0.6) : const Color(0xFFE2E8F0),
        ),
      ),
    );
  }

  Widget _buildModeBtn(String title, IconData icon, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF94A3B8)),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatBtn(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        ),
      ),
    );
  }
}
