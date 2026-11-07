import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/error/failure_localization.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../views/web_verify_email_view.dart';
import '../widgets/auth_screen_scaffold.dart';
import '../widgets/auth_top_bar.dart';
import '../widgets/numeric_keypad.dart';
import '../widgets/otp_display_boxes.dart';

part '../widgets/verify_email_page_state.dart';

class VerifyEmailPage extends ConsumerStatefulWidget {
  final String? email;
  const VerifyEmailPage({super.key, this.email});

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}
