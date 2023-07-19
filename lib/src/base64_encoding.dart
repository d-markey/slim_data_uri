import 'dart:typed_data';

import 'package:meta/meta.dart';

String encode(List<int> input, {bool padding = true}) =>
    _encode(input, _encoding, padding: padding);

String urlEncode(List<int> input, {bool padding = true}) =>
    _encode(input, _urlEncoding, padding: padding);

Iterable<int> encodeBytes(List<int> input) => _encodeBytes(input, _encoding);

Iterable<int> urlEncodeBytes(List<int> input) =>
    _encodeBytes(input, _urlEncoding);

String _encode(List<int> input, Uint8List encoding, {bool padding = true}) {
  var pos = 0, idx = 0, len = input.length, i = 0;
  final lastBytes = len % 3;
  len -= lastBytes;

  var size = (4 * len ~/ 3);
  if (lastBytes > 0) {
    size += padding ? 4 : (lastBytes + 1);
  }
  final bytes = Uint8List(size);

  // process full blocks of 3 bytes
  while (pos < len) {
    i = (_check(input[pos++]) << 16) |
        (_check(input[pos++]) << 8) |
        _check(input[pos++]);
    bytes[idx++] = encoding[(i >> 18) & 0x3F];
    bytes[idx++] = encoding[(i >> 12) & 0x3F];
    bytes[idx++] = encoding[(i >> 6) & 0x3F];
    bytes[idx++] = encoding[i & 0x3F];
  }

  // process 1 or 2 remaining bytes
  switch (lastBytes) {
    case 1:
      i = _check(input[pos]) << 16;
      bytes[idx++] = encoding[(i >> 18) & 0x3F];
      bytes[idx++] = encoding[(i >> 12) & 0x3F];
      if (padding) {
        bytes[idx++] = _equals;
        bytes[idx++] = _equals;
      }
      break;
    case 2:
      i = (_check(input[pos]) << 16) | (_check(input[pos + 1]) << 8);
      bytes[idx++] = encoding[(i >> 18) & 0x3F];
      bytes[idx++] = encoding[(i >> 12) & 0x3F];
      bytes[idx++] = encoding[(i >> 6) & 0x3F];
      if (padding) {
        bytes[idx++] = _equals;
      }
      break;
  }

  return String.fromCharCodes(bytes);
}

Iterable<int> _encodeBytes(List<int> input, Uint8List encoding,
    {bool padding = true}) sync* {
  var pos = 0, len = input.length, i = 0;
  final lastBytes = len % 3;
  len -= lastBytes;

  // process full blocks of 3 bytes
  while (pos < len) {
    i = (_check(input[pos++]) << 16) |
        (_check(input[pos++]) << 8) |
        _check(input[pos++]);
    yield encoding[(i >> 18) & 0x3F];
    yield encoding[(i >> 12) & 0x3F];
    yield encoding[(i >> 6) & 0x3F];
    yield encoding[i & 0x3F];
  }

  // process 1 or 2 remaining bytes
  switch (lastBytes) {
    case 1:
      i = _check(input[pos]) << 16;
      yield encoding[(i >> 18) & 0x3F];
      yield encoding[(i >> 12) & 0x3F];
      if (padding) {
        yield _equals;
        yield _equals;
      }
      break;
    case 2:
      i = (_check(input[pos]) << 16) | (_check(input[pos + 1]) << 8);
      yield encoding[(i >> 18) & 0x3F];
      yield encoding[(i >> 12) & 0x3F];
      yield encoding[(i >> 6) & 0x3F];
      if (padding) {
        yield _equals;
      }
      break;
  }
}

Uint8List decode(String input) {
  var pos = 0, idx = 0, len = input.length, i = 0;

  // ignore padding characters
  while (len > 0 && input.codeUnitAt(len - 1) == _equals) {
    len--;
  }

  final diff = input.length - len;
  if (diff != 0 && diff != 1 && diff != 2) {
    throw Exception('Invalid base64 payload');
  }

  final lastChars = len % 4;
  len -= lastChars;

  final bytes = Uint8List(lastChars + (3 * len ~/ 4));

  // process full blocks of 4 bytes
  while (pos < len) {
    i = (_decode(input.codeUnitAt(pos++)) << 18) |
        (_decode(input.codeUnitAt(pos++)) << 12) |
        (_decode(input.codeUnitAt(pos++)) << 6) |
        _decode(input.codeUnitAt(pos++));
    bytes[idx++] = (i >> 16) & 0xFF;
    bytes[idx++] = (i >> 8) & 0xFF;
    bytes[idx++] = i & 0xFF;
  }

  // process remaining 2 or 3 bytes
  switch (lastChars) {
    case 2:
      i = (_decode(input.codeUnitAt(pos)) << 18) |
          (_decode(input.codeUnitAt(pos + 1)) << 12);
      bytes[idx] = (i >> 16) & 0xFF;
      bytes[idx + 1] = (i >> 8) & 0xFF;
      break;
    case 3:
      i = (_decode(input.codeUnitAt(pos)) << 18) |
          (_decode(input.codeUnitAt(pos + 1)) << 12) |
          (_decode(input.codeUnitAt(pos + 2)) << 6);
      bytes[idx] = (i >> 16) & 0xFF;
      bytes[idx + 1] = (i >> 8) & 0xFF;
      bytes[idx + 2] = i & 0xFF;
      break;
  }

  return bytes;
}

Iterable<int> decodeBytes(String input) sync* {
  var pos = 0, len = input.length, i = 0;

  // ignore padding characters
  while (len > 0 && input.codeUnitAt(len - 1) == _equals) {
    len--;
  }

  final diff = input.length - len;
  if (diff != 0 && diff != 1 && diff != 2) {
    throw Exception('Invalid base64 payload');
  }

  final lastChars = len % 4;
  len -= lastChars;

  // process full blocks of 4 bytes
  while (pos < len) {
    i = (_decode(input.codeUnitAt(pos++)) << 18) |
        (_decode(input.codeUnitAt(pos++)) << 12) |
        (_decode(input.codeUnitAt(pos++)) << 6) |
        _decode(input.codeUnitAt(pos++));
    yield (i >> 16) /*& 0xFF*/;
    yield (i >> 8) & 0xFF;
    yield i & 0xFF;
  }

  // process remaining 2 or 3 bytes
  switch (lastChars) {
    case 2:
      i = (_decode(input.codeUnitAt(pos)) << 18) |
          (_decode(input.codeUnitAt(pos + 1)) << 12);
      yield (i >> 16) & 0xFF;
      yield (i >> 8) & 0xFF;
      break;
    case 3:
      i = (_decode(input.codeUnitAt(pos)) << 18) |
          (_decode(input.codeUnitAt(pos + 1)) << 12) |
          (_decode(input.codeUnitAt(pos + 2)) << 6);
      yield (i >> 16) & 0xFF;
      yield (i >> 8) & 0xFF;
      yield i & 0xFF;
      break;
  }
}

@internal
bool isValid(int codeUnit) => _decoding[codeUnit] != null;

// constants & encoding/decoding tables

const _plus = 0x2B; // +
const _minus = 0x2D; // -
const _slash = 0x2F; // /
const _underscore = 0x5F; // _
const _equals = 0x3D; // =

const _a = 0x61; // a
const _z = _a + 25; // z

// ignore: constant_identifier_names
const _A = 0x41; // A
// ignore: constant_identifier_names
const _Z = _A + 25; // Z

// ignore: constant_identifier_names
const _0 = 0x30; // 0
// ignore: constant_identifier_names
const _9 = _0 + 9; // 9

final _encoding = Uint8List.fromList(
  Iterable.generate(26, (i) => _A + i)
      .followedBy(Iterable.generate(26, (i) => _a + i))
      .followedBy(Iterable.generate(10, (i) => _0 + i))
      .followedBy([_plus, _slash]).toList(),
);

final _urlEncoding = Uint8List.fromList(
  Iterable.generate(26, (i) => _A + i)
      .followedBy(Iterable.generate(26, (i) => _a + i))
      .followedBy(Iterable.generate(10, (i) => _0 + i))
      .followedBy([_minus, _underscore]).toList(),
);

final _decoding = Iterable.generate(
  256,
  (ch) {
    if (_A <= ch && ch <= _Z) return ch - _A;
    if (_a <= ch && ch <= _z) return 26 + ch - _a;
    if (_0 <= ch && ch <= _9) return 52 + ch - _0;
    if (ch == _plus || ch == _minus) return 62;
    if (ch == _slash || ch == _underscore) return 63;
    return null;
  },
).toList();

int _decode(int value) => (_decoding[value] != null)
    ? _decoding[value]!
    : throw Exception('Invalid base64 payload');

int _check(int value) => (0 <= value && value <= 0xFF)
    ? value
    : throw Exception('Not a byte: $value');
