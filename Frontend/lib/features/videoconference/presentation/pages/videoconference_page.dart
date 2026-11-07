import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_providers.dart';
import '../../../../core/widgets/smart_loader.dart';
import '../../application/videoconference_providers.dart';
import '../widgets/schedule_session_dialog.dart';
import '../widgets/video_session_card.dart';

part '../widgets/videoconference_page_state.dart';
part '../widgets/videoconference_state_schedule.dart';
part '../widgets/videoconference_state_build.dart';
part '../widgets/videoconference_state_herobanner.dart';
part '../widgets/videoconference_state_heroheader.dart';
part '../widgets/videoconference_state_featurechips.dart';
part '../widgets/videoconference_state_controlstoolbar.dart';
part '../widgets/videoconference_state_searchbar.dart';
part '../widgets/videoconference_state_segmentedtabs.dart';
part '../widgets/videoconference_tab_session_list.dart';

class VideoconferencePage extends ConsumerStatefulWidget {
  const VideoconferencePage({super.key});

  @override
  ConsumerState<VideoconferencePage> createState() =>
      _VideoconferencePageState();
}
