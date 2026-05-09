import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/launcher_service.dart';
import 'context_apps_provider.dart';

/// Single source of truth for wired / Bluetooth headphone connection state.
///
/// Driven by the native EventChannel (BroadcastReceiver) so state updates are
/// instant on plug/unplug — no polling cost. The stream pushes the current
/// state on subscribe, so no separate initial query is needed.
///
/// Gated on whether the user has configured at least one headphone app in
/// Settings → Context & Shell. If the list is empty the subscription is
/// cancelled and state is forced false.
final headphoneProvider = StateNotifierProvider<HeadphoneNotifier, bool>((ref) {
  final initiallyEnabled = ref.read(contextShellAppsProvider).isNotEmpty;
  final notifier = HeadphoneNotifier(enabled: initiallyEnabled);

  ref.listen<List<String>>(contextShellAppsProvider, (_, next) {
    notifier.setEnabled(next.isNotEmpty);
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

  /// Called when the user adds or removes all headphone apps.
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
    _unsubscribe();
    _sub = LauncherService.headphoneEvents.listen((connected) {
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
