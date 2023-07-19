import 'dart:typed_data';

import 'package:meta/meta.dart';

import '_uint8_buffer.dart';

String encode(List<int> input) {
  final len = input.length, buffer = Uint8Buffer(initialCapacity: len);
  final block = Uint8List.fromList([_percent, 0, 0]);
  var pos = 0, ch = 0;
  while (pos < len) {
    ch = _check(input[pos++]);
    if (ch >= 0x7F || isReserved(ch)) {
      block[1] = _encodeHex[(ch >> 4) & 0x0F];
      block[2] = _encodeHex[ch & 0x0F];
      buffer.writeBytes(block);
    } else {
      buffer.writeByte(ch);
    }
  }

  return String.fromCharCodes(buffer.view());
}

Iterable<int> encodeBytes(List<int> input) sync* {
  final len = input.length;
  var pos = 0, ch = 0;
  while (pos < len) {
    ch = _check(input[pos++]);
    if (ch >= 0x7F || isReserved(ch)) {
      yield _percent;
      yield _encodeHex[(ch >> 4) & 0x0F];
      yield _encodeHex[ch & 0x0F];
    } else {
      yield ch;
    }
  }
}

Uint8List decode(String input) {
  final len = input.length, buffer = Uint8Buffer(initialCapacity: len ~/ 2);

  const size = 512;
  final block = Uint8List(size);

  var pos = 0, idx = 0, ch = 0;
  while (pos < len) {
    ch = input.codeUnitAt(pos++);
    if (ch == _percent) {
      block[idx++] = (_decodeHex(input.codeUnitAt(pos++)) << 4) |
          _decodeHex(input.codeUnitAt(pos++));
    } else if (isReserved(ch)) {
      throw Exception('Invalid percent-encoded payload');
    } else {
      block[idx++] = ch;
    }
    if (idx == size) {
      buffer.writeBytes(block);
      idx = 0;
    }
  }

  // flush
  if (idx > 0) {
    buffer.writeBytes(block.view(idx));
  }

  return buffer.view();
}

Iterable<int> decodeBytes(String input) sync* {
  final len = input.length;

  var pos = 0, ch = 0;
  while (pos < len) {
    ch = input.codeUnitAt(pos++);
    if (ch == _percent) {
      yield (_decodeHex(input.codeUnitAt(pos++)) << 4) |
          _decodeHex(input.codeUnitAt(pos++));
    } else if (isReserved(ch)) {
      throw Exception('Invalid percent-encoded payload');
    } else {
      yield ch;
    }
  }
}

@internal
bool isReserved(int codeUnit) => _reserved[codeUnit];

// constants & encoding/decoding tables

const _percent = 0x25; // %

const _a = 0x61; // a
const _f = _a + 5; // f

// ignore: constant_identifier_names
const _A = 0x41; // A
// ignore: constant_identifier_names
const _F = _A + 5; // F

// ignore: constant_identifier_names
const _0 = 0x30; // 0
// ignore: constant_identifier_names
const _9 = _0 + 9; // 9

final _encodeHex = Uint8List.fromList(
  Iterable.generate(10, (i) => _0 + i)
      .followedBy(Iterable.generate(6, (i) => _A + i))
      .toList(),
);

final _decoding = Iterable.generate(
  256,
  (ch) {
    if (_0 <= ch && ch <= _9) return ch - _0;
    if (_a <= ch && ch <= _f) return 10 + ch - _a;
    if (_A <= ch && ch <= _F) return 10 + ch - _A;
    return null;
  },
).toList();

int _decodeHex(int value) => (_decoding[value] != null)
    ? _decoding[value]!
    : throw Exception('Invalid percent-encoded payload');

final _reserved = Iterable.generate(
  256,
  (codeUnit) {
    if (codeUnit <= 0x2C) {
      // control characters + <space> ! " # $ % & ' ( ) * + ,
      return true;
    }
    switch (codeUnit) {
      case 0x2F:
        return true; // /
      case 0x3A:
        return true; // :
      case 0x3B:
        return true; // ;
      case 0x3D:
        return true; // =
      case 0x3F:
        return true; // ?
      case 0x40:
        return true; // @
      case 0x5B:
        return true; // [
      case 0x5C:
        return true; // \
      case 0x5D:
        return true; // ]
      default:
        return false;
    }
  },
).toList();

int _check(int value) => (0 <= value && value <= 0xFF)
    ? value
    : throw Exception('Not a byte: $value');

extension Uint8ListView on Uint8List {
  Uint8List view(int size) =>
      (size == length) ? this : Uint8List.sublistView(this, 0, size);
}
