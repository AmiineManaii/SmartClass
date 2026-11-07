part of '../pages/videoconference_page.dart';
extension on _VideoconferencePageState {
  Widget _buildControlsToolbar(BuildContext context, bool isDark, bool isWide) {
    if (isWide) {
      return Row(
        children: [
          // Segmented Tabs on Left
          Expanded(
            flex: 3,
            child: _buildSegmentedTabs(context, isDark, isWide: true),
          ),
          const SizedBox(width: 16),
          // Search Bar & Refresh on Right
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Row(
              children: [
                Expanded(child: _buildSearchBar(context, isDark)),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.all(10),
                  ),
                  tooltip: 'Actualiser la liste',
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  onPressed: () {
                    final key = _tabController.index == 0
                        ? 'live'
                        : (_tabController.index == 1 ? 'scheduled' : 'past');
                    ref.read(videoSessionsProvider(key).notifier).refresh();
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Mobile vertical stack
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchBar(context, isDark),
        const SizedBox(height: 8),
        _buildSegmentedTabs(context, isDark, isWide: false),
      ],
    );
  }

}
