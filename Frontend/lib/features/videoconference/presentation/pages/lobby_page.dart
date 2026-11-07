import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../../../../app/app_providers.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../application/videoconference_providers.dart';
import '../../domain/entities/session_event.dart';
import '../../domain/entities/session_phase.dart';
import '../../domain/entities/video_session.dart';
import '../widgets/session_phase_badge.dart';

part '../widgets/lobby_page_state.dart';

class LobbyPage extends ConsumerStatefulWidget {
  final String sessionId;

  const LobbyPage({super.key, required this.sessionId});

  @override
  ConsumerState<LobbyPage> createState() => _LobbyPageState();
}
