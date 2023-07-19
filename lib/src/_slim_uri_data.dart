import 'dart:convert' as convert;
import 'dart:typed_data';
import 'package:meta/meta.dart';

import 'base64_encoding.dart' as base64;
import 'percent_encoding.dart' as percent;
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
  String get charset => convert.ascii.name;

  Iterable<int> get bytes => isBase64
      ? base64.decodeBytes(uri.payload)
      : percent.decodeBytes(uri.payload);

  @override
  Uint8List contentAsBytes() =>
      isBase64 ? base64.decode(uri.payload) : percent.decode(uri.payload);

  @override
  String contentAsString({convert.Encoding? encoding}) =>
      (encoding ??= convert.ascii).decode(contentAsBytes());

  @override
  String get contentText => uri.path;

  @override
  bool isCharset(String charset) =>
      convert.Encoding.getByName(charset) == convert.ascii;

  @override
  bool isEncoding(convert.Encoding encoding) => encoding == convert.ascii;

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
