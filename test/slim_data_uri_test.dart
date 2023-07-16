import 'dart:convert';

import 'package:slim_data_uri/slim_data_uri.dart';
import 'package:test/test.dart';

void main() {
  final base64 = base64Encode(bytes);
  final percent = percentEncode(bytes);

  group('Base64 encoded', () {
    test('Build with payload', () {
      final slimUri =
          SlimDataUri.base64(base64, mimeType: 'application/x-test');
      expect(
        slimUri.toString(),
        equals('data:application/x-test;base64,$base64'),
      );
      expect(slimUri.path, equals('application/x-test;base64,$base64'));
      expect(slimUri.scheme, equals('data'));
      expect(slimUri.data.isBase64, isTrue);
      expect(slimUri.data.mimeType, equals('application/x-test'));
      expect(slimUri.data.contentAsBytes(), equals(bytes));
    });

    test('Parse', () {
      final slimUri = SlimDataUri.parse('data:;base64,$base64');
      expect(slimUri.toString(), equals('data:;base64,$base64'));
      expect(slimUri.path, equals(';base64,$base64'));
      expect(slimUri.scheme, equals('data'));
      expect(slimUri.data.isBase64, isTrue);
      expect(slimUri.data.mimeType, equals('application/octet-stream'));
      expect(slimUri.data.contentAsBytes(), equals(bytes));
    });

    test('Parse - no safety check', () {
      final malicious = 'DUMMY"/><script>alert("attack!");</script>';
      final slimUri = SlimDataUri.parse('data:;base64,$malicious');
      expect(slimUri.toString(), equals('data:;base64,$malicious'));
      expect(slimUri.path, equals(';base64,$malicious'));
      expect(slimUri.scheme, equals('data'));
      expect(slimUri.isSafeContent, isFalse);
      expect(slimUri.data.isBase64, isTrue);
      expect(slimUri.data.mimeType, equals('application/octet-stream'));
      expect(slimUri.data.contentAsBytes, throwsA(isA<Exception>()));
    });

    test('Parse - with safety check', () {
      final malicious = 'DUMMY"/><script>alert("attack!");</script>';
      expect(
          () => SlimDataUri.parse('data:;base64,$malicious', safetyCheck: true),
          throwsA(isA<Exception>()));
    });

    test('Parse - safe yet invalid payload', () {
      final invalid = 'A=B';
      final slimUri =
          SlimDataUri.parse('data:;base64,$invalid', safetyCheck: true);
      expect(slimUri.isSafeContent, isTrue);
      expect(slimUri.data.contentAsBytes, throwsA(isA<Exception>()));
    });

    test('Dart Uri --> SlimDataUri', () {
      final uri = Uri.parse('data:application/x-test;base64,$base64');
      final slimUri = SlimDataUri.parse(uri.toString());
      expect(slimUri.toString(), equals(uri.toString()));
      expect(slimUri.path, equals(uri.path));
      expect(slimUri.scheme, equals(uri.scheme));
      expect(slimUri.data.isBase64, uri.data!.isBase64);
      expect(slimUri.data.mimeType, uri.data!.mimeType);
      expect(slimUri.data.contentAsBytes(), equals(uri.data!.contentAsBytes()));
    });

    test('Dart Uri --> SlimDataUri with params', () {
      final uri =
          Uri.parse('data:application/x-test;param=value;base64,$base64');
      final slimUri = SlimDataUri.parse(uri.toString());
      expect(slimUri.toString(), equals(uri.toString()));
      expect(slimUri.path, equals(uri.path));
      expect(slimUri.scheme, equals(uri.scheme));
      expect(slimUri.data.isBase64, uri.data!.isBase64);
      expect(slimUri.data.mimeType, uri.data!.mimeType);
      expect(slimUri.data.parameters, equals(uri.data!.parameters));
      expect(slimUri.data.contentAsBytes(), equals(uri.data!.contentAsBytes()));
    });

    test('SlimDataUri --> Dart Uri', () {
      final slimUri =
          SlimDataUri.parse('data:application/x-test;base64,$base64');
      final uri = Uri.parse(slimUri.toString());
      expect(slimUri.toString(), equals(uri.toString()));
      expect(slimUri.path, equals(uri.path));
      expect(slimUri.scheme, equals(uri.scheme));
      expect(slimUri.data.isBase64, uri.data!.isBase64);
      expect(slimUri.data.mimeType, uri.data!.mimeType);
      expect(slimUri.data.contentAsBytes(), equals(uri.data!.contentAsBytes()));
    });

    group('Performance', () {
      test('parse', () {
        var dart = Duration.zero, slim = Duration.zero;
        final uri = 'data:;base64,${base64 * 10000}';
        final sw = Stopwatch();
        for (var i = 0; i < 10; i++) {
          sw.reset();
          sw.start();
          SlimDataUri.parse(uri);
          slim += sw.elapsed;

          sw.reset();
          sw.start();
          Uri.parse(uri);
          dart += sw.elapsed;
        }
        expect(slim.inMicroseconds, lessThan(dart.inMicroseconds));
        expect(dart.inMicroseconds / slim.inMicroseconds, greaterThan(20));
      });

      test('contentAsBytes', () {
        var dart = Duration.zero, slim = Duration.zero;
        final uri = 'data:;base64,${base64 * 10000}';
        final slimData = SlimDataUri.parse(uri).data;
        final uriData = Uri.parse(uri).data!;
        final sw = Stopwatch();
        for (var i = 0; i < 10; i++) {
          sw.reset();
          sw.start();
          slimData.contentAsBytes();
          slim += sw.elapsed;

          sw.reset();
          sw.start();
          uriData.contentAsBytes();
          dart += sw.elapsed;
        }
        reportPerf(slim, dart);
      });
    });
  });

  group('Percent encoded', () {
    test('Build with payload', () {
      final slimUri =
          SlimDataUri.percent(percent, mimeType: 'application/x-test');
      expect(
        slimUri.toString(),
        equals('data:application/x-test,$percent'),
      );
      expect(slimUri.path, equals('application/x-test,$percent'));
      expect(slimUri.scheme, equals('data'));
      expect(slimUri.data.isBase64, isFalse);
      expect(slimUri.data.mimeType, equals('application/x-test'));
      expect(slimUri.data.contentAsBytes(), equals(bytes));
    });

    test('Parse', () {
      final slimUri = SlimDataUri.parse('data:,$percent');
      expect(slimUri.toString(), equals('data:,$percent'));
      expect(slimUri.path, equals(',$percent'));
      expect(slimUri.scheme, equals('data'));
      expect(slimUri.data.isBase64, isFalse);
      expect(slimUri.data.mimeType, equals('application/octet-stream'));
      expect(slimUri.data.contentAsBytes(), equals(bytes));
    });

    test('Parse - no safety check', () {
      final malicious = 'DUMMY"/><script>alert("attack!");</script>';
      final slimUri = SlimDataUri.parse('data:,$malicious');
      expect(slimUri.toString(), equals('data:,$malicious'));
      expect(slimUri.path, equals(',$malicious'));
      expect(slimUri.scheme, equals('data'));
      expect(slimUri.isSafeContent, isFalse);
      expect(slimUri.data.isBase64, isFalse);
      expect(slimUri.data.mimeType, equals('application/octet-stream'));
      expect(slimUri.data.contentAsBytes, throwsA(isA<Exception>()));
    });

    test('Parse - with safety check', () {
      final malicious = 'DUMMY"/><script>alert("attack!");</script>';
      expect(() => SlimDataUri.parse('data:,$malicious', safetyCheck: true),
          throwsA(isA<Exception>()));
    });

    test('Parse - safe yet invalid payload', () {
      final invalid = '%%';
      final slimUri = SlimDataUri.parse('data:,$invalid', safetyCheck: true);
      expect(slimUri.isSafeContent, isTrue);
      expect(slimUri.data.contentAsBytes, throwsA(isA<Exception>()));
    });

    test('Dart Uri --> SlimDataUri', () {
      final uri = Uri.parse('data:application/x-test,$percent');
      final slimUri = SlimDataUri.parse(uri.toString());
      expect(slimUri.toString(), equals(uri.toString()));
      expect(slimUri.path, equals(uri.path));
      expect(slimUri.scheme, equals(uri.scheme));
      expect(slimUri.data.isBase64, uri.data!.isBase64);
      expect(slimUri.data.mimeType, uri.data!.mimeType);
      expect(slimUri.data.contentAsBytes(), equals(uri.data!.contentAsBytes()));
    });

    test('Dart Uri --> SlimDataUri with parameters', () {
      final uri = Uri.parse('data:application/x-test;param=value,$percent');
      final slimUri = SlimDataUri.parse(uri.toString());
      expect(slimUri.toString(), equals(uri.toString()));
      expect(slimUri.path, equals(uri.path));
      expect(slimUri.scheme, equals(uri.scheme));
      expect(slimUri.data.isBase64, uri.data!.isBase64);
      expect(slimUri.data.mimeType, uri.data!.mimeType);
      expect(slimUri.data.parameters, equals(uri.data!.parameters));
      expect(slimUri.data.contentAsBytes(), equals(uri.data!.contentAsBytes()));
    });

    test('SlimDataUri --> Dart Uri', () {
      final slimUri = SlimDataUri.parse('data:application/x-test,$percent');
      final uri = Uri.parse(slimUri.toString());
      expect(slimUri.toString(), equals(uri.toString()));
      expect(slimUri.path, equals(uri.path));
      expect(slimUri.scheme, equals(uri.scheme));
      expect(slimUri.data.isBase64, uri.data!.isBase64);
      expect(slimUri.data.mimeType, uri.data!.mimeType);
      expect(slimUri.data.contentAsBytes(), equals(uri.data!.contentAsBytes()));
    });

    group('Performance', () {
      test('parse', () {
        var dart = Duration.zero, slim = Duration.zero;
        final uri = 'data:,${percent * 10000}';
        final sw = Stopwatch();
        for (var i = 0; i < 10; i++) {
          sw.reset();
          sw.start();
          SlimDataUri.parse(uri);
          slim += sw.elapsed;

          sw.reset();
          sw.start();
          Uri.parse(uri);
          dart += sw.elapsed;
        }
        expect(slim.inMicroseconds, lessThan(dart.inMicroseconds));
        expect(dart.inMicroseconds / slim.inMicroseconds, greaterThan(20));
      });

      test('contentAsBytes', () {
        var dart = Duration.zero, slim = Duration.zero;
        final uri = 'data:,${percent * 10000}';
        final slimData = SlimDataUri.parse(uri).data;
        final uriData = Uri.parse(uri).data!;
        final sw = Stopwatch();
        for (var i = 0; i < 10; i++) {
          sw.reset();
          sw.start();
          slimData.contentAsBytes();
          slim += sw.elapsed;

          sw.reset();
          sw.start();
          uriData.contentAsBytes();
          dart += sw.elapsed;
        }
        reportPerf(slim, dart);
      });
    });
  });
}

void reportPerf(Duration baseLine, Duration contender) {
  print(
      '- perf ratio = ${contender.inMicroseconds} µs vs ${baseLine.inMicroseconds} µs =  ${(contender.inMicroseconds / baseLine.inMicroseconds).toStringAsFixed(2)}');
}

final bytes = [
  0x01,
  0x02,
  0x00,
  0x0D,
  0x41,
  0x61,
  0x0A,
  0x7F,
  0x80,
  0x81,
  0x97,
  0xA0,
  0xFF,
  0x20, // space
  0x21, // !
  0x22, // "
  0x23, // #
  0x24, // $
  0x25, // %
  0x26, // &
  0x27, // '
  0x28, // (
  0x29, // )
  0x2A, // *
  0x2B, // +
  0x2C, // ,
  0x2F, // /
  0x3A, // :
  0x3B, // ;
  0x3D, // =
  0x3F, // ?
  0x40, // @
  0x5B, // [
  0x5D, // ]
  0xCA,
  0xFE,
];
