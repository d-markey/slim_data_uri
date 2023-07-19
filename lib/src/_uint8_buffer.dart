import 'dart:typed_data';

import 'package:meta/meta.dart';

abstract class Uint8Buffer {
  Uint8Buffer._(this.initialCapacity) : _bytes = _empty;

  factory Uint8Buffer({int? initialCapacity, bool secure = false}) => secure
      ? _Uint8SecureBuffer(
          initialCapacity:
              (initialCapacity ?? 0) <= _4Kib ? _4Kib : initialCapacity!)
      : _Uint8Buffer(
          initialCapacity:
              (initialCapacity ?? 0) <= _4Kib ? _4Kib : initialCapacity!);

  final int initialCapacity;

  Uint8List _bytes;
  int get capacity => _bytes.length;

  int _length = 0;
  int get length => _length;

  @mustCallSuper
  void clear() {
    _length = 0;
  }

  void _ensureCapacity(int length);

  void dispose() {
    clear();
    _bytes = _empty;
  }

  void writeByte(int byte) {
    _ensureCapacity(_length + 1);
    _bytes[_length++] = byte;
  }

  void writeBytes(List<int> bytes) {
    final len = bytes.length, total = _length + len;
    _ensureCapacity(total);
    _bytes.setRange(_length, total, bytes);
    _length = total;
  }

  Uint8List view() => Uint8List.sublistView(_bytes, 0, _length);
}

class _Uint8Buffer extends Uint8Buffer {
  _Uint8Buffer({required int initialCapacity}) : super._(initialCapacity);

  @override
  void _ensureCapacity(int length) {
    if (length > _bytes.length) {
      var capacity = _bytes.isEmpty ? initialCapacity : _bytes.length;
      while (capacity < length) {
        capacity += (capacity < _16Mib) ? capacity : _16Mib;
      }
      final buf = Uint8List(capacity);
      buf.setRange(0, _length, _bytes);
      _bytes = buf;
    }
  }
}

class _Uint8SecureBuffer extends Uint8Buffer {
  _Uint8SecureBuffer({required int initialCapacity}) : super._(initialCapacity);

  @override
  void clear() {
    _bytes.fillRange(0, _bytes.length, 0);
    super.clear();
  }

  @override
  void _ensureCapacity(int length) {
    if (length > _bytes.length) {
      var capacity = _bytes.isEmpty ? initialCapacity : _bytes.length;
      while (capacity < length) {
        capacity += (capacity < _16Mib) ? capacity : _16Mib;
      }
      final buf = Uint8List(capacity);
      buf.setRange(0, _length, _bytes);
      _bytes.fillRange(0, _bytes.length, 0);
      _bytes = buf;
    }
  }
}

final _empty = Uint8List(0);

const int _kib = 1024;
// ignore: constant_identifier_names
const int _4Kib = 4 * _kib;
// ignore: constant_identifier_names
const int _16Mib = 16 * _kib * _kib;
