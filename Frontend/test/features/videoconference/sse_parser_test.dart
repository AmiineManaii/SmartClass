import 'package:flutter_test/flutter_test.dart';
import 'package:smartclass/core/network/sse_client.dart';

void main() {
  group('SseParser', () {
    late SseParser parser;

    setUp(() {
      parser = SseParser();
    });

    test('ignores comments such as ping frames', () {
      expect(parser.processLine(': ping'), isNull);
      expect(parser.processLine(': keepalive'), isNull);
    });

    test('parses single line data event', () {
      expect(parser.processLine('event: session.started'), isNull);
      expect(parser.processLine('data: {"sessionId":"123"}'), isNull);
      final msg = parser.processLine('');
      expect(msg, isNotNull);
      expect(msg!.event, 'session.started');
      expect(msg.data, '{"sessionId":"123"}');
      expect(msg.jsonMap?['sessionId'], '123');
    });

    test('concatenates multi-line data frames', () {
      expect(parser.processLine('data: line 1'), isNull);
      expect(parser.processLine('data: line 2'), isNull);
      final msg = parser.processLine('');
      expect(msg, isNotNull);
      expect(msg!.data, 'line 1\nline 2');
    });

    test('handles id field', () {
      expect(parser.processLine('id: 42'), isNull);
      expect(parser.processLine('data: payload'), isNull);
      final msg = parser.processLine('');
      expect(msg, isNotNull);
      expect(msg!.id, '42');
      expect(msg.data, 'payload');
    });

    test('resets buffer between consecutive messages', () {
      parser.processLine('event: evt1');
      parser.processLine('data: {"count":1}');
      final msg1 = parser.processLine('');
      expect(msg1?.event, 'evt1');

      parser.processLine('data: {"count":2}');
      final msg2 = parser.processLine('');
      expect(msg2?.event, isNull);
      expect(msg2?.jsonMap?['count'], 2);
    });
  });
}
