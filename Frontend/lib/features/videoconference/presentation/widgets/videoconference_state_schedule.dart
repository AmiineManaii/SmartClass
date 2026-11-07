part of '../pages/videoconference_page.dart';
extension on _VideoconferencePageState {
  Future<void> _openScheduleDialog({bool liveNow = false}) async {
    final result = await ScheduleSessionDialog.show(
      context,
      defaultLiveNow: liveNow,
    );
    if (result != null && mounted) {
      ref.read(videoSessionsProvider('live').notifier).refresh();
      ref.read(videoSessionsProvider('scheduled').notifier).refresh();
      ref.read(videoSessionsProvider('past').notifier).refresh();
      if (result == 'live') {
        _tabController.animateTo(0);
      } else if (result == 'scheduled') {
        _tabController.animateTo(1);
      }
    }
  }
}
