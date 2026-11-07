import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/extensions.dart';
import 'exam_ai_score_page.dart';

part '../widgets/secure_exam_page_state.dart';

class SecureExamPage extends StatefulWidget {
  final String? examTitle;
  final String? courseContext;

  const SecureExamPage({super.key, this.examTitle, this.courseContext});

  @override
  State<SecureExamPage> createState() => _SecureExamPageState();
}
