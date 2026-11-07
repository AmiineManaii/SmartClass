part of '../pages/groups_page.dart';
extension on _GroupsPageState {
  Widget _buildPage(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final role = user?.role?.toLowerCase() ?? 'student';
    final isTeacher = role == 'teacher';
    final isAdmin = role == 'admin';
    final isStudent = role == 'student';
    final isTeacherOrAdmin = isTeacher || isAdmin;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = context.screenWidth >= 1024;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myGroupsProvider);
            ref.invalidate(studentClassMembershipProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Hero Header Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isDesktop ? 32 : 16,
                    16,
                    isDesktop ? 32 : 16,
                    12,
                  ),
                  child: _buildHeroBanner(
                    context,
                    isTeacher: isTeacher,
                    isAdmin: isAdmin,
                    isTeacherOrAdmin: isTeacherOrAdmin,
                  ),
                ),
              ),

              // 2. Search & Filter Controls
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32 : 16,
                    vertical: 6,
                  ),
                  child: _buildSearchAndFilters(
                    context,
                    isTeacherOrAdmin: isTeacherOrAdmin,
                  ),
                ),
              ),

              // 3. Groups List / States
              _buildSliverContent(
                context,
                user: user,
                isTeacherOrAdmin: isTeacherOrAdmin,
                isStudent: isStudent,
                isAdmin: isAdmin,
                isDesktop: isDesktop,
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
