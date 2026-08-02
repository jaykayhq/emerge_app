// Replit-style IDX web preview dev server for Flutter web.
//
// Every start is a FRESH build: it kills any stale `flutter run` for the
// target port (so the preview never hits an old server) and removes the
// incremental web build caches (so the first compile reflects the latest
// source). Then it stays resident and watches the project:
//
//   - lib/ + assets/ change  -> SIGUSR1 -> hot reload (live, no refresh)
//   - web/ or pubspec.yaml   -> SIGUSR2 -> hot restart (needs rebuild)
//
// Usage (from .idx/dev.nix): dart run tool/idx_dev_server.dart --port=$PORT
//
// Requires only dart:io — no external packages. Runs `flutter` from PATH.

import 'dart:async';
import 'dart:io';

const _pidFile = '/tmp/emerge_flutter_web.pid';

const _skipSegments = {'.dart_tool', 'build', '.git'};
const _watchRoots = ['lib', 'assets', 'web'];

const _debounce = Duration(milliseconds: 400);
const _restartDelay = Duration(seconds: 2);
const _minHealthyRun = Duration(seconds: 10);

Process? _flutter;
int _port = 0;
DateTime _startedAt = DateTime.now();

Future<void> main(List<String> args) async {
  for (final arg in args) {
    if (arg.startsWith('--port=')) {
      _port = int.parse(arg.substring('--port='.length));
    }
  }
  if (_port == 0) {
    stderr.writeln('USAGE: dart run tool/idx_dev_server.dart --port=NNNN');
    exit(2);
  }

  ProcessSignal.sigterm.watch().listen((_) async {
    await _killChild();
    exit(0);
  });
  ProcessSignal.sigint.watch().listen((_) async {
    await _killChild();
    exit(0);
  });

  // Fresh state: no stale server holding the port, no stale web artifacts.
  await _killStaleServer();
  _cleanIncrementalCaches();
  stdout.writeln('[dev-server] fresh build on port $_port');

  await _startFlutter();
  _watchSources();
}

Future<void> _killStaleServer() async {
  final pidFile = File(_pidFile);
  if (await pidFile.exists()) {
    final stale = int.tryParse((await pidFile.readAsString()).trim());
    if (stale != null) {
      try {
        Process.killPid(stale, ProcessSignal.sigterm);
        stdout.writeln('[dev-server] killed stale flutter run (pid $stale)');
      } catch (_) {
        // Already dead — the stale pid file is just leftover.
      }
    }
    try {
      await pidFile.delete();
    } catch (_) {}
  }
  try {
    final pkill = await Process.start('pkill', ['-f', '--', 'web-port=$_port'],
        mode: ProcessStartMode.normal);
    pkill.stdin.close();
    await pkill.exitCode;
  } catch (_) {
    // pkill not installed — the pid-file path above is the primary guard.
  }
}

void _cleanIncrementalCaches() {
  for (final path in ['build/web', '.dart_tool/flutter_build']) {
    final dir = Directory(path);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
      stdout.writeln('[dev-server] cleared stale cache: $path');
    }
  }
}

Future<void> _startFlutter() async {
  _startedAt = DateTime.now();
  final args = [
    'run',
    '-d',
    'web-server',
    '--web-port=$_port',
    '--web-hostname=0.0.0.0',
    '--hot',
    '--pid-file=$_pidFile',
  ];
  stdout.writeln('[dev-server] flutter ${args.join(' ')}');
  _flutter = await Process.start('flutter', args, mode: ProcessStartMode.normal);
  _flutter!.stdout.transform(const SystemEncoding().decoder).listen((line) {
    stdout.writeln(line.trimRight());
  });
  _flutter!.stderr.transform(const SystemEncoding().decoder).listen((line) {
    stderr.writeln(line.trimRight());
  });
  unawaited(_flutter!.exitCode.then((code) {
    stdout.writeln('[dev-server] flutter run exited with code $code');
    _flutter = null;
    // Crash-loop guard: a run that died instantly is a compile error — give
    // the fix time to land before hammering; a long-lived run was killed
    // externally, so come back quickly.
    final lived = DateTime.now().difference(_startedAt);
    final delay = lived > _minHealthyRun ? _restartDelay : _restartDelay * 3;
    Future.delayed(delay, () {
      stdout.writeln('[dev-server] restarting flutter run...');
      _startFlutter();
    });
  }));
}

void _watchSources() {
  final events = StreamController<FileSystemEvent>.broadcast();
  for (final root in _watchRoots) {
    final dir = Directory(root);
    if (dir.existsSync()) {
      dir.watch(
          recursive: true,
          events: FileSystemEvent.create |
              FileSystemEvent.modify |
              FileSystemEvent.delete).listen((event) {
        if (!_ignored(event.path)) {
          events.add(event);
        }
      });
    }
  }
  File('pubspec.yaml')
      .watch(events: FileSystemEvent.create | FileSystemEvent.modify)
      .listen((event) {
    if (!_ignored(event.path)) {
      events.add(event);
    }
  });

  var timer = Timer(_debounce, () {});
  var pubspecQueued = false;
  events.stream.listen((event) {
    if (!pubspecQueued && _isPubspec(event.path)) {
      pubspecQueued = true;
    }
    timer.cancel();
    timer = Timer(_debounce, () async {
      if (_flutter == null) return;
      final pidFile = File(_pidFile);
      if (!await pidFile.exists()) return;
      final pid = int.tryParse((await pidFile.readAsString()).trim());
      if (pid == null) return;
      try {
        if (pubspecQueued) {
          stdout.writeln('[dev-server] pubspec.yaml changed -> pub get + hot restart');
          final pubGet = await Process.start('flutter', ['pub', 'get']);
          await pubGet.exitCode;
          Process.killPid(pid, ProcessSignal.sigusr2);
          pubspecQueued = false;
        } else {
          stdout.writeln('[dev-server] change detected -> hot reload');
          Process.killPid(pid, ProcessSignal.sigusr1);
        }
      } catch (e) {
        stdout.writeln('[dev-server] reload trigger failed: $e');
      }
    });
  });
}

bool _ignored(String path) {
  final segments = path.replaceAll('\\', '/').split('/');
  return segments.any(_skipSegments.contains);
}

bool _isPubspec(String path) => path.endsWith('pubspec.yaml');

Future<void> _killChild() async {
  final child = _flutter;
  if (child != null) {
    child.kill(ProcessSignal.sigterm);
    await child.exitCode.timeout(const Duration(seconds: 5),
        onTimeout: () {
      child.kill(ProcessSignal.sigkill);
      return -1;
    });
  }
}
