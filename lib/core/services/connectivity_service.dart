import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_service.g.dart';

@Riverpod(keepAlive: true)
Stream<List<ConnectivityResult>> connectivityStream(Ref ref) {
  return Connectivity().onConnectivityChanged;
}

@Riverpod(keepAlive: true)
bool isConnected(Ref ref) {
  final connectivitySync = ref.watch(connectivityStreamProvider);

  return connectivitySync.when(
    data: (results) {
      if (results.isEmpty) return false;
      return results.any(
        (result) =>
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet ||
            result == ConnectivityResult.vpn ||
            result == ConnectivityResult.other,
      );
    },
    loading: () =>
        true, // Assume connected during loading to avoid premature offline banners
    error: (_, _) => false,
  );
}
