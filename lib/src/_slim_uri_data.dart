import 'dart:convert';
import 'dart:typed_data';
import 'package:meta/meta.dart';

import 'percent_codec.dart';
import 'slim_data_uri.dart';

class SlimUriData implements UriData {
  SlimUriData._(String mimeType, this.uri, this._params, this.isBase64)
      : mimeType = mimeType.toLowerCase();

  @override
  final bool isBase64;

  @override
  final String mimeType;

  @override
  final SlimDataUri uri;

  final String _params;

  @override
  String get charset => ascii.name;

  Iterable<int> get bytes =>
      isBase64 ? base64Decode(uri.payload) : percentDecodeBytes(uri.payload);

  @override
  Uint8List contentAsBytes() =>
      isBase64 ? base64Decode(uri.payload) : percentDecode(uri.payload);

  @override
  String contentAsString({Encoding? encoding}) =>
      (encoding ??= ascii).decode(contentAsBytes());

  @override
  String get contentText => uri.path;

  @override
  bool isCharset(String charset) => Encoding.getByName(charset) == ascii;

  @override
  bool isEncoding(Encoding encoding) => encoding == ascii;

  @override
  bool isMimeType(String mimeType) =>
      mimeType.toLowerCase().compareTo(this.mimeType) == 0;

  Map<String, String>? _parameters;

  @override
  Map<String, String> get parameters {
    if (_parameters == null) {
      final params = <String, String>{};
      for (var pair in _params.split(';')) {
        final pos = pair.indexOf('=');
        params[pair.substring(0, pos)] = pair.substring(pos + 1);
      }
      _parameters = params;
    }
    return _parameters!;
  }
}

@internal
SlimUriData createSlimUriData(
        String mimeType, SlimDataUri uri, String params, bool isBase64) =>
    SlimUriData._(mimeType, uri, params, isBase64);
