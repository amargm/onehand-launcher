import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/launcher_service.dart';
import 'context_settings_provider.dart';

/// Single source of truth for wired / Bluetooth headphone connection state.
///
/// Polling is gated on the "Headphones" toggle in Settings → Context indicators.
/// When that toggle is OFF the timer is stopped and state is forced to false
/// so the context shell stays hidden regardless of what is physically connected.
final headphoneProvider = StateNotifierProvider<HeadphoneNotifier, bool>((ref) {
  // Read the initial value of the headphone setting.
  final initiallyEnabled = ref
      .read(contextItemsProvider)
      .contains(ContextItemType.headphone);
  final notifier = HeadphoneNotifier(enabled: initiallyEnabled);

  // React to settings changes without recreating the notifier (avoids a
  // state reset / timer restart on every unrelated settings change).
  ref.listen<Set<ContextItemType>>(contextItemsProvider, (_, next) {
    notifier.setEnabled(next.contains(ContextItemType.headphone));
  });

  return notifier;
});

class HeadphoneNotifier extends StateNotifier<bool> {
  HeadphoneNotifier({required bool enabled}) : super(false) {
    _enabled = enabled;
    if (enabled) _startPolling();
  }

  bool _enabled = false;
  Timer? _timer;

  /// Called when the Settings toggle changes.
  void setEnabled(bool enabled) {
    if (enabled == _enabled) return;
    _enabled = enabled;
    if (enabled) {
      _startPolling();
    } else {
      _stopPolling();
      // Immediately hide the context shell.
      if (mounted) state = false;
    }
  }

  void _startPolling() {
    _poll(); // immediate first check
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    try {
      final connected = await LauncherService.isHeadphoneConnected();
      // Only mutate state (and trigger rebuilds) when value actually changes.
      if (mounted && connected != state) state = connected;
    } catch (_) {
      // Benign: emulator or audio service unavailable — keep current state.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
