part of '../pages/videoconference_page.dart';
extension on _VideoconferencePageState {
  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _searchQuery.isNotEmpty
              ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF122675))
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0)),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 19,
            color: _searchQuery.isNotEmpty
                ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF122675))
                : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => updateState(() => _searchQuery = val.trim()),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: const InputDecoration(
                hintText: 'Rechercher une s├®ance, mati├¿re ou enseignant...',
                hintStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  color: Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                updateState(() => _searchQuery = '');
              },
              child: const Icon(Icons.cancel_rounded,
                  size: 17, color: Color(0xFF94A3B8)),
            ),
        ],
      ),
    );
  }

}
