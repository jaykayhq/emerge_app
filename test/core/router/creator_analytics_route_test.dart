// test/core/router/creator_analytics_route_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:emerge_app/core/router/creator_routes.dart';

void main() {
  test('creator dashboard shell has an analytics branch', () {
    final routes = creatorRoutes;
    final shell = routes.whereType<StatefulShellRoute>().first;
    final paths = shell.branches
        .expand((b) => b.routes)
        .whereType<GoRoute>()
        .map((r) => r.path)
        .toList();
    expect(paths, contains('/creator/dashboard/analytics'));
  });
}
