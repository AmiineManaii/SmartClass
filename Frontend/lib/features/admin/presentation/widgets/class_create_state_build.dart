part of '../pages/class_create_page.dart';
extension on _ClassCreatePageState {
  Widget _buildPage(BuildContext context) {
    final theme = Theme.of(context);
    final departmentsAsync = ref.watch(adminDepartmentsProvider);
    final teachersAsync = ref.watch(adminTeachersProvider(null));

    if (_isEdit) {
      final detailAsync =
          ref.watch(adminClassDetailProvider(widget.editClassId!));
      return detailAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.tr('something_went_wrong'),
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(
                      adminClassDetailProvider(widget.editClassId!)),
                  child: Text(context.tr('retry')),
                ),
              ],
            ),
          ),
        ),
        data: (detail) {
          if (detail == null) {
            return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () => context.pop(),
                ),
              ),
              body: Center(child: Text(context.tr('empty_state'))),
            );
          }
          _prefill(detail);
          return _buildView(context, departmentsAsync, teachersAsync);
        },
      );
    }
    return _buildView(context, departmentsAsync, teachersAsync);
  }

}

