import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/launcher_service.dart';

/// Single source of truth for wired / Bluetooth headphone connection state.
///
/// Previously every widget that cared about headphones (ContextSection,
/// _ContextMiniRow) kept its own 5-second Timer and its own platform-channel
/// call. This provider replaces all of them with one shared polling timer so
/// the audio-device query runs exactly once every 5 s regardless of how many
/// widgets watch this provider.
final headphoneProvider = StateNotifierProvider<HeadphoneNotifier, bool>(
  (_) => HeadphoneNotifier(),
);

class HeadphoneNotifier extends StateNotifier<bool> {
  HeadphoneNotifier() : super(false) {
    _poll();
    // Poll every 2 s instead of 5 s so wired/USB plug-in is detected promptly.
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  late final Timer _timer;

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
    _timer.cancel();
    super.dispose();
  }
}
