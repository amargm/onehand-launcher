import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/launcher_service.dart';
import 'context_settings_provider.dart';

/// Single source of truth for wired / Bluetooth headphone connection state.
///
/// Uses a 3-second polling timer — the EventChannel / BroadcastReceiver
/// approach failed to reliably detect Bluetooth state changes on some devices.
/// Polling is simple, predictable, and the battery cost is negligible
/// (one lightweight AudioManager query every 3 seconds, only while the
///  launcher is in the foreground and the feature is enabled).
///
/// Gated on the "Headphones" toggle in Settings → Context indicators.
/// When OFF: timer cancelled, state forced false immediately.
final headphoneProvider = StateNotifierProvider<HeadphoneNotifier, bool>((ref) {
  final initiallyEnabled = ref
      .read(contextItemsProvider)
      .contains(ContextItemType.headphone);
  final notifier = HeadphoneNotifier(enabled: initiallyEnabled);

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

  static const _pollInterval = Duration(seconds: 3);

  bool _enabled = false;
  Timer? _timer;

  /// Called when the Settings "Headphones" toggle changes.
  void setEnabled(bool enabled) {
    if (enabled == _enabled) return;
    _enabled = enabled;
    if (enabled) {
      _startPolling();
    } else {
      _stopPolling();
      if (mounted) state = false;
    }
  }

  void _startPolling() {
    _stopPolling();
    // Query immediately so state is correct at once, then repeat.
    _poll();
    _timer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    final connected = await LauncherService.isHeadphoneConnected();
    if (mounted && connected != state) state = connected;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
