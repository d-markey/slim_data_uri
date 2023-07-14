import 'dart:math';
import 'dart:typed_data';

import 'package:slim_data_uri/slim_data_uri.dart';

const kib = 1024;
const mib = kib * kib;

final rnd = Random().nextInt;

void main() {
  runBenchmark('Uri parsing', Uri.parse, SlimDataUri.parse);

  Uint8List dartContentAsBytes(String contentText) =>
      Uri.parse(contentText).data!.contentAsBytes();

  Uint8List slimContentAsBytes(String contentText) =>
      SlimDataUri.parse(contentText).data.contentAsBytes();

  runBenchmark('Byte content', dartContentAsBytes, slimContentAsBytes);
}

String fmt(double value) => value.toStringAsFixed(3);

void runBenchmark(String label, void Function(String) dartParser,
    void Function(String) slimParser) {
  var dart = Duration.zero;
  var slim = Duration.zero;
  var totalBytes = 0;

  for (var i = 0; i < 5; i++) {
    // initialize data
    final count = (15 + rnd(10)) * mib; // 20 +/- 5 MiB
    print('[$label] #$i: initializing $count bytes...');
    final bytes = Uint8List(count);
    for (var i = 0; i < count; i++) {
      bytes[i] = rnd(256);
    }
    final contentText = 'data:,${percentEncode(bytes)}';

    if (i == 0) {
      //dry run
      print('[$label] #$i: dry run...');
      benchmark(contentText, dartParser);
      benchmark(contentText, slimParser);
    } else {
      totalBytes += count;
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

  print('''

$label - GRAND TOTAL:
  * Total bytes = $totalBytes
  * Dart Uri = $dart --> ${fmt((totalBytes / kib) / dart.inMicroseconds)} KiB/µs
  * SlimDataUri = $slim --> ${fmt((totalBytes / kib) / slim.inMicroseconds)} KiB/µs
  * ratio = ${fmt(dart.inMilliseconds / slim.inMilliseconds)}
''');
}

Duration benchmark(String contentText, void Function(String) parser) {
  final sw = Stopwatch()..start();
  parser(contentText);
  return sw.elapsed;
}
