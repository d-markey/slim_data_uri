import 'dart:convert';
import 'dart:typed_data';

import '_uint8_buffer.dart';

/// A codec for percent-encoding.
///
/// Encoding: all bytes <= 0x20 or >= 0x7F will be percent encoded, as well as reserved
/// characters (any of: `% <: / ? # [ ] @ ! $ & ' ( ) * + , ; =`). Other bytes are encoded
/// as US-ASCII characters.
class PercentCodec extends Codec<List<int>, String> {
  const PercentCodec();

  @override
  Converter<String, Uint8List> get decoder => const _PercentDecoder();

  @override
  Converter<List<int>, String> get encoder => const _PercentEncoder();

  @override
  Uint8List decode(String encoded) => decoder.convert(encoded);
}

Iterable<int> percentDecodeBytes(String input) =>
    (const _PercentDecoder()).decode(input);

Uint8List percentDecode(String input) => (const PercentCodec()).decode(input);

String percentEncode(List<int> input) => (const PercentCodec()).encode(input);

// private implementation

class _PercentEncoder extends Converter<List<int>, String> {
  const _PercentEncoder();

  @override
  String convert(List<int> input) => String.fromCharCodes(encode(input));

  static Iterable<int> encode(List<int> input) sync* {
    var pos = 0;
    final len = input.length;
    while (pos < len) {
      final ch = input[pos++];
      if (ch <= 0x20 || ch >= 0x7F || _reserved.contains(ch)) {
        yield _percent;
        yield _hex((ch & 0xF0) >> 4);
        yield _hex(ch & 0x0F);
      } else {
        yield ch;
      }
    }
  }

  static int _hex(int byte) {
    if (0 <= byte && byte <= 9) return _0 + byte;
    if (0x0A <= byte && byte <= 0x0F) return _A + byte - 0x0A;
    throw Exception('Invalid hex digit $byte');
  }
}

class _PercentDecoder extends Converter<String, Uint8List> {
  const _PercentDecoder();

  @override
  @override
  Uint8List convert(String input) {
    final buffer = Uint8Buffer(input.length ~/ 2);

    var pos = 0;
    final len = input.length;
    while (pos < len) {
      var ch = input.codeUnitAt(pos++);
      if (ch == _percent) {
        ch = (_hex(input.codeUnitAt(pos++)) << 4) |
            _hex(input.codeUnitAt(pos++));
      } else if (_reserved.contains(ch)) {
        throw Exception('Invalid character ${String.fromCharCode(ch)}');
      }
      buffer.writeByte(ch);
    }
    return buffer.toList();
  }

  Iterable<int> decode(String input) sync* {
    var pos = 0;
    final len = input.length;
    while (pos < len) {
      var ch = input.codeUnitAt(pos++);
      if (ch == _percent) {
        ch = (_hex(input.codeUnitAt(pos++)) << 4) |
            _hex(input.codeUnitAt(pos++));
      } else if (_reserved.contains(ch)) {
        throw Exception('Invalid character ${String.fromCharCode(ch)}');
      }
      yield ch;
    }
  }

  static int _hex(int ch) {
    if (_0 <= ch && ch <= _9) return ch - _0;
    if (_a <= ch && ch <= _f) return 10 + ch - _a;
    if (_A <= ch && ch <= _F) return 10 + ch - _A;
    throw Exception('Invalid hex digit ${String.fromCharCode(ch)}');
  }
}

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

const _reserved = {
  0x20, // space
  0x21, // !
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
};
