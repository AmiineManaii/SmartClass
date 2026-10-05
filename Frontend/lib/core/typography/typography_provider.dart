import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'typography_config.dart';

final typographyRepositoryProvider = Provider<TypographyRepository>((ref) {
  return TypographyRepository();
});

final typographyConfigProvider = StateNotifierProvider<TypographyConfigNotifier, AsyncValue<TypographyConfig>>((ref) {
  return TypographyConfigNotifier(ref.read(typographyRepositoryProvider));
});

class TypographyConfigNotifier extends StateNotifier<AsyncValue<TypographyConfig>> {
  final TypographyRepository _repository;
  
  TypographyConfigNotifier(this._repository) : super(const AsyncValue.loading()) {
    _load();
  }
  
  Future<void> _load() async {
    try {
      final config = await _repository.load();
      state = AsyncValue.data(config);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> updateFontFamily(FontFamilyOption fontFamily) async {
    final current = state.value;
    if (current == null) return;
    
    final newConfig = current.copyWith(fontFamily: fontFamily);
    await _saveAndUpdate(newConfig);
  }
  
  Future<void> updateFontSize(FontSizeOption fontSize) async {
    final current = state.value;
    if (current == null) return;
    
    final newConfig = current.copyWith(fontSize: fontSize);
    await _saveAndUpdate(newConfig);
  }
  
  Future<void> updateTextScale(double scale) async {
    final current = state.value;
    if (current == null) return;
    
    final newConfig = current.copyWith(textScaleFactor: scale.clamp(0.85, 1.5));
    await _saveAndUpdate(newConfig);
  }
  
  Future<void> _saveAndUpdate(TypographyConfig config) async {
    state = AsyncValue.data(config);
    await _repository.save(config);
  }
  
  Future<void> reset() async {
    const defaultConfig = TypographyConfig();
    state = AsyncValue.data(defaultConfig);
    await _repository.reset();
  }
}

final appTextStylesProvider = Provider<AppTextStyles>((ref) {
  final config = ref.watch(typographyConfigProvider).value ?? const TypographyConfig();
  return AppTextStyles(config);
});