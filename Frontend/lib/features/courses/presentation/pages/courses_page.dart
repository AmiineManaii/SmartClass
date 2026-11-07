import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../application/providers/courses_provider.dart';
import '../../application/providers/course_generation_job_provider.dart';
import '../../domain/entities/generated_course.dart';
import '../widgets/course_card.dart';
import '../widgets/error_state.dart';
import '../widgets/generated_course_card.dart';
import '../widgets/generated_list.dart';
import '../widgets/running_job_banner.dart';
import '../widgets/staggered_list_item.dart';
import '../widgets/subject_detail_card.dart';

part '../widgets/courses_page_state.dart';

/// "Cours & Ressources" pour le professeur et l'étudiant.
class CoursesPage extends ConsumerStatefulWidget {
  const CoursesPage({super.key});

  @override
  ConsumerState<CoursesPage> createState() => _CoursesPageState();
}
