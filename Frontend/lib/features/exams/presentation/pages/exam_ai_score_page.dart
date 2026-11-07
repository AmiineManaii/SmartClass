import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/extensions.dart';

part '../widgets/exam_ai_score_page_state.dart';
part '../widgets/exam_ai_score_filtertab.dart';
part '../widgets/exam_ai_score_kpimetriccard.dart';
part '../widgets/exam_ai_score_questionbreakdowncard.dart';
part '../widgets/exam_ai_score_remediationcarditem.dart';
part '../widgets/exam_ai_score_scoreringpainter.dart';

class ExamAiScorePage extends StatefulWidget {
  final String examTitle;
  final String courseContext;

  const ExamAiScorePage({
    super.key,
    this.examTitle = 'Examen Continu : Complexité & Structures Arborescentes',
    this.courseContext = 'Licence 3 Informatique • Algorithmique Avancée',
  });

  @override
  State<ExamAiScorePage> createState() => _ExamAiScorePageState();
}
