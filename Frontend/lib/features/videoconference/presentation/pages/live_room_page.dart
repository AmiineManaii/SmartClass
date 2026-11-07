import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_button.dart';
import '../../application/live_room_controller.dart';
import '../../domain/entities/room_connection_state.dart';
import '../views/mobile_live_room_view.dart';
import '../views/web_live_room_view.dart';
import '../widgets/hand_raise_notice_overlay.dart';
import '../widgets/live_room_connecting_overlay.dart';

part '../widgets/live_room_page_state.dart';

class LiveRoomPage extends ConsumerStatefulWidget {
  final String sessionId;
  final bool? initialMic;
  final bool? initialCamera;

  const LiveRoomPage({
    super.key,
    required this.sessionId,
    this.initialMic,
    this.initialCamera,
  });

  @override
  ConsumerState<LiveRoomPage> createState() => _LiveRoomPageState();
}
