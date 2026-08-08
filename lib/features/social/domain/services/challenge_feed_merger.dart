import 'package:emerge_app/features/social/domain/models/challenge.dart';

/// Merges server-published challenges ahead of the static catalog, de-duping
/// by id. Server entries win on collision so server rotation is authoritative.
List<Challenge> mergeChallengeSources({
  required List<Challenge> server,
  required List<Challenge> catalog,
}) {
  final byId = <String, Challenge>{};
  for (final c in server) {
    if (c.id.isNotEmpty) byId[c.id] = c;
  }
  for (final c in catalog) {
    byId.putIfAbsent(c.id, () => c);
  }
  return byId.values.toList();
}
