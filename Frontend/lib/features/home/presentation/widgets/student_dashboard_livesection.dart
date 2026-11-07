part of '../widgets/student_dashboard_view.dart';
class _LiveSection extends StatelessWidget {
  final TodayLiveSession? session;
  final VoidCallback onJoin;

  const _LiveSection({required this.session, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final live = session;
    if (live == null) return const SizedBox.shrink();
    if (live.videoSession != null) {
      final phase = phaseOf(
        live.videoSession!,
        DateTime.now(),
        serverOffset: live.serverOffset,
      );
      if (phase == SessionPhase.ended ||
          phase == SessionPhase.canceled ||
          live.videoSession!.status == VideoSessionStatus.completed ||
          live.videoSession!.status == VideoSessionStatus.canceled) {
        return const SizedBox.shrink();
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudentImminentLiveCard(
          session: live,
          onJoin: () {
            if (live.videoSession != null) {
              context.push('/videoconference/${live.videoSession!.id}/lobby');
            } else {
              onJoin();
            }
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

/// Student's real classes (`GET /api/v1/groups/mine`) rendered as animated
/// 3D course cards. Title = class name, tags = department/level/status.
/// No mock data: an empty list shows the honest empty state.
