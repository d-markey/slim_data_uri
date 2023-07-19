import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:slim_data_uri/slim_data_uri.dart';

import 'package:slim_data_uri/base64_encoding.dart' as base64;
import 'package:slim_data_uri/percent_encoding.dart' as percent;

const kib = 1024;
const mib = kib * kib;

final rnd = Random().nextInt;

Uint8List generatePayload(int min, int max) {
  final count = (min + rnd(max - min)) * mib;
  final bytes = Uint8List(count);
  for (var i = 0; i < count; i++) {
    bytes[i] = rnd(256);
  }
  return bytes;
}

void main() {
  final bytes = generatePayload(20, 30); // 25 +/- 5 MiB
  final sw = Stopwatch()..start();

  var convert = Duration.zero, b64 = Duration.zero;

  for (var i = 0; i < 10; i++) {
    sw.reset();
    base64Encode(bytes);
    if (i > 0) {
      convert += sw.elapsed;
    }

    sw.reset();
    base64.encode(bytes);
    if (i > 0) {
      b64 += sw.elapsed;
    }
  }

  print(
      '[encode] $b64 vs $convert --> ${convert.inMicroseconds / b64.inMicroseconds}');

  final encoded = base64.encode(bytes);

  convert = Duration.zero;
  b64 = Duration.zero;

  for (var i = 0; i < 10; i++) {
    sw.reset();
    base64Decode(encoded);
    if (i > 0) {
      convert += sw.elapsed;
    }

    sw.reset();
    base64.decode(encoded);
    if (i > 0) {
      b64 += sw.elapsed;
    }
  }

  print(
      '[decode] $b64 vs $convert --> ${convert.inMicroseconds / b64.inMicroseconds}');

  runBenchmarkBase64('Uri parsing (base64)', Uri.parse, SlimDataUri.parse);
  runBenchmarkPercent('Uri parsing (percent)', Uri.parse, SlimDataUri.parse);

  Uint8List dartContentAsBytes(String contentText) =>
      Uri.parse(contentText).data!.contentAsBytes();

  Uint8List slimContentAsBytes(String contentText) =>
      SlimDataUri.parse(contentText).data.contentAsBytes();

  runBenchmarkBase64(
      'Byte content (base64)', dartContentAsBytes, slimContentAsBytes);
  runBenchmarkPercent(
      'Byte content (percent)', dartContentAsBytes, slimContentAsBytes);
}

String fmt(double value) => value.toStringAsFixed(3);

void runBenchmarkBase64(String label, void Function(String) dartParser,
    void Function(String) slimParser) {
  var dart = Duration.zero;
  var slim = Duration.zero;
  var totalBytes = 0;

  for (var i = 0; i < 5; i++) {
    // initialize data
    final bytes = generatePayload(20, 30); // 25 +/- 5 MiB
    print('[$label] #$i: initialized ${bytes.length} bytes...');
    final contentText = 'data:;base64,${base64.encode(bytes)}';

    if (i == 0) {
      //dry run
      print('[$label] #$i: dry run...');
      benchmark(contentText, dartParser);
      benchmark(contentText, slimParser);
    } else {
      totalBytes += bytes.length;
      // using Dart's Uri
      var dur = benchmark(contentText, dartParser);
      print('[$label]  * Dart Uri: $dur');
      dart += dur;
      // using SlimDataUri
      dur = benchmark(contentText, slimParser);
      print('[$label]  * SlimDataUri: $dur');
      slim += dur;
    }
  }

  print(
      '''

$label - GRAND TOTAL:
  * Total bytes = $totalBytes
  * Dart Uri = $dart --> ${fmt((totalBytes / kib) / dart.inMicroseconds)} KiB/µs
  * SlimDataUri = $slim --> ${fmt((totalBytes / kib) / slim.inMicroseconds)} KiB/µs
  * ratio = ${fmt(dart.inMicroseconds / slim.inMicroseconds)}
''');
}

void runBenchmarkPercent(String label, void Function(String) dartParser,
    void Function(String) slimParser) {
  var dart = Duration.zero;
  var slim = Duration.zero;
  var totalBytes = 0;

  for (var i = 0; i < 5; i++) {
    // initialize data
    final bytes = generatePayload(20, 30); // 25 +/- 5 MiB
    print('[$label] #$i: initialized ${bytes.length} bytes...');
    final contentText = 'data:,${percent.encode(bytes)}';

    if (i == 0) {
      //dry run
      print('[$label] #$i: dry run...');
      benchmark(contentText, dartParser);
      benchmark(contentText, slimParser);
    } else {
      totalBytes += bytes.length;
      // using Dart's Uri
      var dur = benchmark(contentText, dartParser);
      print('[$label]  * Dart Uri: $dur');
      dart += dur;
      // using SlimDataUri
      dur = benchmark(contentText, slimParser);
      print('[$label]  * SlimDataUri: $dur');
      slim += dur;
    }
  }

  print(
      '''

$label - GRAND TOTAL:
  * Total bytes = $totalBytes
  * Dart Uri = $dart --> ${fmt((totalBytes / kib) / dart.inMicroseconds)} KiB/µs
  * SlimDataUri = $slim --> ${fmt((totalBytes / kib) / slim.inMicroseconds)} KiB/µs
  * ratio = ${fmt(dart.inMicroseconds / slim.inMicroseconds)}
''');
}

Duration benchmark(String contentText, void Function(String) parser) {
  final sw = Stopwatch()..start();
  parser(contentText);
  return sw.elapsed;
}
