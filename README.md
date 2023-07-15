# slim_data_uri

A drop-in, lightweight replacement for "data:" Uri.

Example:

```dart
final dataUri = parseUri('data:audio/mpeg;base64,....');
print(dataUri.runtimeType); // SlimDataUri

final uri = parseUri('http://www.google.com');
print(uri.runtimeType); // Uri
```

## Rationale

This package provides function `Uri parseUri(String uri)` as a replacement to Dart's `Uri.parse(String uri)`. It returns an instance of `SlimDataUri` for URIs with a `data:` scheme, and falls back to Dart's `Uri.parse()` for other schemes.

Contrary to Dart's `Uri` implementation, `SlimDataUri` does not parse the data payload, thus yielding much better performance for large data payloads.

The `example` folder provides a benchmark:

```
dart run example/main.dart
```

Sample output (base64 benchmark):

```
[Uri parsing] #0: initializing 16777216 bytes...
[Uri parsing] #0: dry run...
[Uri parsing] #1: initializing 16777216 bytes...
[Uri parsing]  * Dart Uri: 0:00:00.215011
[Uri parsing]  * SlimDataUri: 0:00:00.000016
[Uri parsing] #2: initializing 17825792 bytes...
[Uri parsing]  * Dart Uri: 0:00:00.167898
[Uri parsing]  * SlimDataUri: 0:00:00.000015
[Uri parsing] #3: initializing 23068672 bytes...
[Uri parsing]  * Dart Uri: 0:00:00.280060
[Uri parsing]  * SlimDataUri: 0:00:00.000013
[Uri parsing] #4: initializing 16777216 bytes...
[Uri parsing]  * Dart Uri: 0:00:00.138297
[Uri parsing]  * SlimDataUri: 0:00:00.000009

Uri parsing - GRAND TOTAL:
  * Total bytes = 74448896
  * Dart Uri = 0:00:00.801266 --> 0.091 KiB/µs
  * SlimDataUri = 0:00:00.000053 --> 1371.774 KiB/µs
  * ratio = Infinity

[Byte content] #0: initializing 16777216 bytes...
[Byte content] #0: dry run...
[Byte content] #1: initializing 22020096 bytes...
[Byte content]  * Dart Uri: 0:00:00.313630
[Byte content]  * SlimDataUri: 0:00:00.129395
[Byte content] #2: initializing 23068672 bytes...
[Byte content]  * Dart Uri: 0:00:00.348454
[Byte content]  * SlimDataUri: 0:00:00.152085
[Byte content] #3: initializing 18874368 bytes...
[Byte content]  * Dart Uri: 0:00:00.258945
[Byte content]  * SlimDataUri: 0:00:00.114646
[Byte content] #4: initializing 19922944 bytes...
[Byte content]  * Dart Uri: 0:00:00.334124
[Byte content]  * SlimDataUri: 0:00:00.125372

Byte content - GRAND TOTAL:
  * Total bytes = 83886080
  * Dart Uri = 0:00:01.255153 --> 0.065 KiB/µs
  * SlimDataUri = 0:00:00.521498 --> 0.157 KiB/µs
  * ratio = 2.409
```

## Important Note

Because `SlimDataUri` does not parse the data payload, any input provided to `parseUri` or `SlimDataUri.parse`, `SlimDataUri.base64` or `SlimDataUri.percent` must be checked and sanitized beforehand. Failure to do so may result in malicious users providing invalid data that has ben crafted to conduct eg. Cross-Site Scripting (XSS) attacks. For instance, if your program receives base64 or percent-encoded data, it should check that the input is well-formed before using `SlimDataUri`. Alternatively, user input can be systematically base64 or percent-encoded by your code to guarantee safety.
