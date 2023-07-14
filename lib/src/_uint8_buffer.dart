import 'dart:math';
import 'dart:typed_data';

class Uint8Buffer {
  Uint8Buffer([int initialCapacity = 1024])
      : initialCapacity =
            (initialCapacity <= 0 ? _blockSize : initialCapacity) {
    _bytes = Uint8List(initialCapacity);
  }

  final int initialCapacity;

  late Uint8List _bytes;

  int get capacity => _bytes.length;

  int _length = 0;
  int get length => _length;

  static const int _kib = 1024;
  static const int _blockSize = _kib;
  // ignore: constant_identifier_names
  static const int _4Mib = 4 * _kib * _kib;

  static final _empty = Uint8List(0);

  void dispose() {
    _bytes = _empty;
    _length = 0;
  }

  void clear() {
    _length = 0;
  }

  static int _blocks(int length) {
    var nbBlocks = length ~/ _blockSize;
    if (length % _blockSize != 0) {
      nbBlocks += 1;
    }
    return nbBlocks;
  }

  void _ensureCapacity(int length) {
    if (_bytes.isEmpty) {
      if (length <= initialCapacity) {
        _bytes = Uint8List(initialCapacity);
      } else {
        _bytes = Uint8List(max(_blockSize * _blocks(length), initialCapacity));
      }
    } else if (length > _bytes.length) {
      var capacity = _bytes.length;
      while (capacity < length) {
        capacity += (capacity < _4Mib) ? capacity : _4Mib;
      }
      final buf = Uint8List(capacity);
      buf.setRange(0, _length, _bytes);
      _bytes = buf;
    }
  }

  void writeByte(int byte) {
    _ensureCapacity(_length + 1);
    _bytes[_length++] = byte;
  }

  void writeBytes(List<int> bytes) {
    final len = bytes.length;
    _ensureCapacity(_length + len);
    _bytes.setRange(_length, _length + len, bytes);
    _length += len;
  }

  Uint8List toList() {
    final list = Uint8List(_length);
    list.setRange(0, _length, _bytes);
    return list;
  }

  Iterable<int> asIterable() => _bytes.take(_length);
}
