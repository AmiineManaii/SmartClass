import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../courses/application/providers/courses_provider.dart';
import '../../../courses/domain/entities/course_entry.dart';
import '../../application/videoconference_providers.dart';
import '../../domain/entities/video_session.dart';

class ScheduleSessionDialog extends ConsumerStatefulWidget {
  final VideoSession? initialSession;
  final bool defaultLiveNow;

  const ScheduleSessionDialog({
    super.key,
    this.initialSession,
    this.defaultLiveNow = true,
  });

  static Future<String?> show(
    BuildContext context, {
    VideoSession? initialSession,
    bool defaultLiveNow = true,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final isTabletOrDesktop = screenSize.width >= 600;

    return showDialog<String>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final isDark = theme.brightness == Brightness.dark;

        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          elevation: 20,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isTabletOrDesktop ? 40 : 16,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTabletOrDesktop ? 600 : double.infinity,
              maxHeight: screenSize.height * 0.88,
            ),
            child: ScheduleSessionDialog(
              initialSession: initialSession,
              defaultLiveNow: defaultLiveNow,
            ),
          ),
        );
      },
    );
  }

  @override
  ConsumerState<ScheduleSessionDialog> createState() =>
      _ScheduleSessionDialogState();
}

class _ScheduleSessionDialogState
    extends ConsumerState<ScheduleSessionDialog> {
  final _formKey = GlobalKey<FormState>();

  late bool _isLiveNow;
  String? _selectedClassId;
  String? _selectedClassName;
  String? _selectedSubject;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  int _durationMinutes = 60;
  int _joinOpensMinutesBefore = 5;
  bool _chatEnabled = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final s = widget.initialSession;
    if (s != null) {
      _isLiveNow = s.status == VideoSessionStatus.inProgress;
      _selectedClassId = s.classGroupId;
      _selectedClassName = s.className;
      _selectedSubject = s.subject;
      _titleController = TextEditingController(text: s.title);
      _descriptionController = TextEditingController(text: s.description ?? '');
      _selectedDate = s.startsAt;
      _selectedTime = TimeOfDay.fromDateTime(s.startsAt);
      _durationMinutes = s.endsAt.difference(s.startsAt).inMinutes;
      if (![45, 60, 90, 120].contains(_durationMinutes)) {
        _durationMinutes = 60;
      }
      _joinOpensMinutesBefore = s.joinOpensMinutesBefore;
      _chatEnabled = s.chatEnabled;
    } else {
      _isLiveNow = widget.defaultLiveNow;
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      final now = DateTime.now().add(const Duration(hours: 1));
      _selectedDate = DateTime(now.year, now.month, now.day);
      _selectedTime = TimeOfDay(hour: now.hour, minute: 0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateAutoTitle() {
    if (widget.initialSession != null) return;
    if (_titleController.text.trim().isEmpty ||
        _titleController.text.contains(' - ')) {
      final subjectPart = _selectedSubject?.trim() ?? '';
      final classPart = _selectedClassName?.trim() ?? '';
      if (subjectPart.isNotEmpty && classPart.isNotEmpty) {
        _titleController.text = '$subjectPart - $classPart';
      } else if (subjectPart.isNotEmpty) {
        _titleController.text = subjectPart;
      }
    }
  }

  String _formatErrorMessage(dynamic error) {
    final str = error.toString();
    if (str.contains('422') || str.contains('VALIDATION_ERROR')) {
      return 'Veuillez vérifier les informations renseignées. Tous les champs obligatoires doivent être valides.';
    }
    if (str.contains('403') || str.contains('FORBIDDEN')) {
      return 'Vous n\'avez pas les droits nécessaires pour gérer les séances de cette classe.';
    }
    if (str.contains('401') || str.contains('UNAUTHORIZED')) {
      return 'Votre session a expiré. Veuillez vous reconnecter.';
    }
    if (str.contains('SocketException') ||
        str.contains('NetworkException') ||
        str.contains('Connection refused')) {
      return 'Impossible de contacter le serveur. Vérifiez votre connexion internet.';
    }
    final cleaned = str
        .replaceFirst('ApiException: ', '')
        .replaceFirst('Exception: ', '');
    return cleaned.isNotEmpty ? cleaned : 'Une erreur inattendue est survenue.';
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null) {
      setState(() => _errorMessage = context.tr('select_class'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final startsAt = _isLiveNow
        ? DateTime.now()
        : DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _selectedTime.hour,
            _selectedTime.minute,
          );
    final duration = _durationMinutes;
    final endsAt = startsAt.add(Duration(minutes: duration));

    try {
      final actions = ref.read(sessionActionsNotifierProvider.notifier);
      if (widget.initialSession != null) {
        await actions.updateSession(
          id: widget.initialSession!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          startsAt: startsAt,
          endsAt: endsAt,
          joinOpensMinutesBefore: _joinOpensMinutesBefore,
          chatEnabled: _chatEnabled,
        );
        if (mounted) {
          Navigator.of(context).pop('scheduled');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('update_success')),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      } else {
        await actions.createSession(
          classGroupId: _selectedClassId!,
          title: _titleController.text.trim(),
          subject: _selectedSubject?.trim(),
          description: _descriptionController.text.trim(),
          startsAt: startsAt,
          endsAt: endsAt,
          durationMinutes: duration,
          joinOpensMinutesBefore: _joinOpensMinutesBefore,
          chatEnabled: _chatEnabled,
          mode: _isLiveNow ? 'NOW' : 'SCHEDULED',
        );
        if (mounted) {
          Navigator.of(context).pop(_isLiveNow ? 'live' : 'scheduled');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isLiveNow
                  ? 'Séance en direct lancée avec succès !'
                  : context.tr('scheduling_success')),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _formatErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _buildInputDecoration({
    required BuildContext context,
    required bool isDark,
    required String hintText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        color: Color(0xFF94A3B8),
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      prefixIcon: prefixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF122675),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFEF4444),
          width: 1,
        ),
      ),
    );
  }

  Widget _buildModeTabs(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Live now tab
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _isLiveNow = true),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: _isLiveNow
                      ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _isLiveNow
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.sensors_rounded,
                          size: 19,
                          color: _isLiveNow
                              ? const Color(0xFFEF4444)
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                        if (_isLiveNow)
                          Positioned(
                            top: -2,
                            right: -3,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Direct instantané',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: _isLiveNow ? FontWeight.w700 : FontWeight.w500,
                          color: _isLiveNow
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Scheduled tab
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _isLiveNow = false),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  color: !_isLiveNow
                      ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !_isLiveNow
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 18,
                      color: !_isLiveNow
                          ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8))
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Programmer séance',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: !_isLiveNow ? FontWeight.w700 : FontWeight.w500,
                          color: !_isLiveNow
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeInfoBanner(BuildContext context, bool isDark) {
    if (_isLiveNow) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF064E3B).withValues(alpha: 0.3)
              : const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? const Color(0xFF059669).withValues(alpha: 0.4)
                : const Color(0xFFA7F3D0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF059669).withValues(alpha: 0.3)
                    : const Color(0xFFD1FAE5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Direct instantané',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFF6EE7B7)
                          : const Color(0xFF065F46),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'La salle sera active dès la création et immédiatement visible dans l\'onglet En direct.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      color: isDark
                          ? const Color(0xFFA7F3D0)
                          : const Color(0xFF047857),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E3A8A).withValues(alpha: 0.25)
              : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                : const Color(0xFFBFDBFE),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                    : const Color(0xFFDBEAFE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_available_rounded,
                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Séance planifiée',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFF93C5FD)
                          : const Color(0xFF1E40AF),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Définissez la date et l\'horaire. Les étudiants seront notifiés et verront la séance dans leur planning.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      color: isDark
                          ? const Color(0xFFBFDBFE)
                          : const Color(0xFF1D4ED8),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildErrorBanner(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF4444),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Information',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFFFCA5A5)
                        : const Color(0xFFB91C1C),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => setState(() => _errorMessage = null),
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding: EdgeInsets.all(2.0),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationPills(bool isDark) {
    return Row(
      children: [45, 60, 90, 120].map((mins) {
        final isSelected = _durationMinutes == mins;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: () => setState(() => _durationMinutes = mins),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF122675), Color(0xFF1E3A8A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected
                      ? null
                      : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF3B82F6)
                        : (isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0)),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF122675).withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$mins min',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF475569)),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEarlyAccessPills(bool isDark) {
    return Row(
      children: [5, 10, 15].map((mins) {
        final isSelected = _joinOpensMinutesBefore == mins;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => setState(() => _joinOpensMinutesBefore = mins),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF122675), Color(0xFF1E3A8A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected
                      ? null
                      : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF3B82F6)
                        : (isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0)),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$mins min avant',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF475569)),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChatSwitchCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 19,
              color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4338CA),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('chat_enabled_label'),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Autoriser les messages pendant la séance',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _chatEnabled,
            activeTrackColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF122675),
            onChanged: (v) => setState(() => _chatEnabled = v),
          ),
        ],
      ),
    );
  }

  Widget _buildClassField(
    BuildContext context,
    bool isDark,
    AsyncValue<List<CourseEntry>> classesAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('field_class'),
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        classesAsync.when(
          data: (classes) {
            final uniqueClasses = <String, CourseEntry>{};
            for (final c in classes) {
              if (c.id.isNotEmpty && !uniqueClasses.containsKey(c.id)) {
                uniqueClasses[c.id] = c;
              }
            }
            final classList = uniqueClasses.values.toList();

            if (classList.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.amber, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Aucune classe attribuée pour le moment.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              );
            }

            final selectedValue = uniqueClasses.containsKey(_selectedClassId)
                ? _selectedClassId
                : null;

            return DropdownButtonFormField<String>(
              initialValue: selectedValue,
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: _buildInputDecoration(
                context: context,
                isDark: isDark,
                hintText: context.tr('select_class'),
                prefixIcon: const Icon(Icons.school_rounded, size: 18),
              ),
              items: classList.map((c) {
                return DropdownMenuItem<String>(
                  value: c.id,
                  child: Text(
                    '${c.name} (${c.level})',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedClassId = val;
                  final found = uniqueClasses[val];
                  if (found != null) {
                    _selectedClassName = found.name;
                    if (found.subjects.isNotEmpty &&
                        _selectedSubject == null) {
                      _selectedSubject = found.subjects.first;
                    }
                    _updateAutoTitle();
                  }
                });
              },
              validator: (v) => v == null ? context.tr('select_class') : null,
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          ),
          error: (e, _) => Text(
            _formatErrorMessage(e),
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectField(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('field_subject'),
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: _selectedSubject,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: _buildInputDecoration(
            context: context,
            isDark: isDark,
            hintText: context.tr('field_subject'),
            prefixIcon: const Icon(Icons.book_rounded, size: 18),
          ),
          onChanged: (v) {
            _selectedSubject = v;
            _updateAutoTitle();
          },
        ),
      ],
    );
  }

  Widget _buildTitleField(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('field_title'),
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _titleController,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: _buildInputDecoration(
            context: context,
            isDark: isDark,
            hintText: context.tr('field_title_hint'),
            prefixIcon: const Icon(Icons.title_rounded, size: 18),
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? context.tr('field_title') : null,
        ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('field_date'),
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: _buildInputDecoration(
              context: context,
              isDark: isDark,
              hintText: 'Date',
              prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
            ),
            child: Text(
              '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('field_start_time'),
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: _selectedTime,
            );
            if (picked != null) {
              setState(() => _selectedTime = picked);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: _buildInputDecoration(
              context: context,
              isDark: isDark,
              hintText: 'Heure',
              prefixIcon: const Icon(Icons.access_time_rounded, size: 18),
            ),
            child: Text(
              '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStickyFooter(BuildContext context, bool isDark, bool isEditing) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
              ),
              foregroundColor: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: Text(
              context.tr('cancel'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _isLiveNow
                  ? const Color(0xFFEF4444)
                  : (isDark ? const Color(0xFF3B82F6) : const Color(0xFF122675)),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    isEditing
                        ? Icons.save_rounded
                        : (_isLiveNow ? Icons.sensors_rounded : Icons.calendar_month_rounded),
                    size: 18,
                  ),
            label: Text(
              isEditing
                  ? context.tr('save_changes')
                  : (_isLiveNow ? 'Lancer le direct' : 'Programmer la séance'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            onPressed: _isLoading ? null : _handleSubmit,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(myCoursesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.initialSession != null;
    final isTabletOrDesktop = MediaQuery.of(context).size.width >= 600;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Top Decorative Gradient Bar
        Container(
          height: 3.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isLiveNow
                  ? const [Color(0xFFEF4444), Color(0xFFF59E0B)]
                  : const [Color(0xFF3B82F6), Color(0xFF6366F1)],
            ),
          ),
        ),

        // 2. Fixed Header & Mode Tabs
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _isLiveNow
                          ? const Color(0xFFEF4444).withValues(alpha: isDark ? 0.25 : 0.12)
                          : const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.25 : 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isLiveNow
                            ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                            : const Color(0xFF3B82F6).withValues(alpha: 0.3),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isEditing
                          ? Icons.edit_calendar_rounded
                          : (_isLiveNow ? Icons.sensors_rounded : Icons.calendar_month_rounded),
                      color: _isLiveNow
                          ? const Color(0xFFEF4444)
                          : (isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8)),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing
                              ? context.tr('edit_session')
                              : (_isLiveNow ? 'Lancer un direct' : context.tr('schedule_session')),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isLiveNow
                              ? 'Diffusion vidéo en temps réel pour vos étudiants'
                              : 'Planifiez votre cours à l\'avance dans l\'agenda',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Fermer',
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF334155).withValues(alpha: 0.4)
                          : const Color(0xFFF1F5F9),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
              if (!isEditing) ...[
                const SizedBox(height: 14),
                _buildModeTabs(context, isDark),
              ],
            ],
          ),
        ),

        const Divider(height: 1, thickness: 1, color: Color(0x1F94A3B8)),

        // 3. Scrollable Form Body
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isEditing) ...[
                    _buildModeInfoBanner(context, isDark),
                  ],
                  if (_errorMessage != null)
                    _buildErrorBanner(_errorMessage!, isDark),

                  // Class & Subject
                  if (!isEditing && isTabletOrDesktop) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: _buildClassField(context, isDark, classesAsync),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 5,
                          child: _buildSubjectField(context, isDark),
                        ),
                      ],
                    ),
                  ] else ...[
                    if (!isEditing) ...[
                      _buildClassField(context, isDark, classesAsync),
                      const SizedBox(height: 14),
                      _buildSubjectField(context, isDark),
                    ] else ...[
                      _buildSubjectField(context, isDark),
                    ],
                  ],
                  const SizedBox(height: 14),

                  // Title field
                  _buildTitleField(context, isDark),
                  const SizedBox(height: 14),

                  // Date & Time (when scheduled)
                  if (!_isLiveNow) ...[
                    Row(
                      children: [
                        Expanded(child: _buildDateField(context, isDark)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTimeField(context, isDark)),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Duration Pills
                  Text(
                    context.tr('field_duration'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 7),
                  _buildDurationPills(isDark),
                  const SizedBox(height: 14),

                  // Early Access (when scheduled)
                  if (!_isLiveNow) ...[
                    Text(
                      context.tr('field_join_opens_before'),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 7),
                    _buildEarlyAccessPills(isDark),
                    const SizedBox(height: 14),
                  ],

                  // Chat Enabled Switch Card
                  _buildChatSwitchCard(isDark),
                  const SizedBox(height: 14),

                  // Description field
                  Text(
                    context.tr('field_description'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: _buildInputDecoration(
                      context: context,
                      isDark: isDark,
                      hintText: 'Note ou instructions pour les étudiants (facultatif)',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 4. Fixed Sticky Footer
        _buildStickyFooter(context, isDark, isEditing),
      ],
    );
  }
}
