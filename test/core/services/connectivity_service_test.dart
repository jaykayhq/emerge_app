import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:emerge_app/core/services/connectivity_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isConnectedProvider returns true when wifi is available', () async {
    final controller = StreamController<List<ConnectivityResult>>();
    final container = ProviderContainer(
      overrides: [
        connectivityStreamProvider.overrideWith((ref) => controller.stream),
      ],
    );

    final completer = Completer<void>();
    container.listen(
      connectivityStreamProvider,
      (previous, next) {
        if (next is AsyncData) {
          completer.complete();
        }
      },
      fireImmediately: true,
    );

    controller.add([ConnectivityResult.wifi]);
    await completer.future;
    
    final isConnected = container.read(isConnectedProvider);
    expect(isConnected, true);
    
    await controller.close();
  });

  test('isConnectedProvider returns false when no connection is available', () async {
    final controller = StreamController<List<ConnectivityResult>>();
    final container = ProviderContainer(
      overrides: [
        connectivityStreamProvider.overrideWith((ref) => controller.stream),
      ],
    );

    final completer = Completer<void>();
    container.listen(
      connectivityStreamProvider,
      (previous, next) {
        if (next is AsyncData) {
          completer.complete();
        }
      },
      fireImmediately: true,
    );

    controller.add([ConnectivityResult.none]);
    await completer.future;
    
    final isConnected = container.read(isConnectedProvider);
    expect(isConnected, false);
    
    await controller.close();
  });
}
