import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/launcher_service.dart';
import 'context_settings_provider.dart';

/// Single source of truth for wired / Bluetooth headphone connection state.
///
/// Backed by a native BroadcastReceiver via EventChannel — zero battery cost
/// when nothing changes, instant response on plug/unplug/BT connect.
/// The 2-second polling timer is removed entirely.
///
/// Gated on the "Headphones" toggle in Settings → Context indicators.
/// When OFF: stream cancelled, state forced false immediately.
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
    if (enabled) _subscribe();
  }

  bool _enabled = false;
  StreamSubscription<bool>? _sub;

  /// Called when the Settings "Headphones" toggle changes.
  void setEnabled(bool enabled) {
    if (enabled == _enabled) return;
    _enabled = enabled;
    if (enabled) {
      _subscribe();
    } else {
      _unsubscribe();
      if (mounted) state = false;
    }
  }

  void _subscribe() {
    _sub?.cancel();
    _sub = LauncherService.headphoneEvents.listen(
      (connected) {
        if (mounted && connected != state) state = connected;
      },
      onError: (_) {
        // BroadcastReceiver unavailable (emulator / restricted env) — silent.
      },
    );
    // Safety-net: directly query current state via MethodChannel in case the
    // EventChannel's initial push is dropped on first subscription.
    // This is observed specifically for Bluetooth — USB/wired always fires
    // instantly via ACTION_HEADSET_PLUG so the stream event arrives reliably.
    LauncherService.isHeadphoneConnected().then((connected) {
      if (mounted && connected != state) state = connected;
    });
  }

  void _unsubscribe() {
    _sub?.cancel();
    _sub = null;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
