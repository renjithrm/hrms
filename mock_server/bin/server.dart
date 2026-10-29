import 'dart:io';

import 'package:rebs_mock_server/rebs_mock_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

/// Starts the mock API on all interfaces so emulators and phones on the
/// same network can reach it. Port: `PORT` env var or 3001.
Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 3001;
  final api = MockApi();
  final handler =
      const Pipeline().addMiddleware(logRequests()).addHandler(api.handler);
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  stdout
    ..writeln('REBS mock API on http://localhost:${server.port}')
    ..writeln('Android emulator: http://10.0.2.2:${server.port}')
    ..writeln('Scenarios: '
        '${Scenario.values.map((s) => s.wireName).join(', ')}');
}
