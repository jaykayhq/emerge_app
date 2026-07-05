// Web barrel — re‑exports all drift types needed by providers outside the
// drift module.  Only compiled when `dart.library.io` is NOT available (web).
// Uses `drift/wasm.dart` for WASM-backed SQLite instead of `drift/native.dart`.
export 'package:drift/drift.dart';
export 'package:drift/wasm.dart';
export 'app_database.dart';
export 'daos/user_stats_dao.dart';
export 'daos/habits_dao.dart';
export 'daos/habit_completions_dao.dart';
export 'daos/challenge_progress_dao.dart';
export 'daos/tribe_stats_dao.dart';
export 'daos/leaderboard_entries_dao.dart';
export 'daos/mutation_queue_dao.dart';
export 'daos/tribe_activity_dao.dart';
export 'daos/narrator_notes_dao.dart';
export 'daos/pulse_feed_dao.dart';
