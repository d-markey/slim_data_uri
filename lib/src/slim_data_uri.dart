import '_slim_uri_data.dart';
import 'percent_codec.dart' as percent_codec;

class SlimDataUri implements Uri {
  // for internal use
  SlimDataUri._(this._contentText, this._pathStart, this._payloadStart);

  // payload must be base64-encoded
  factory SlimDataUri.base64(String payload,
          {String mimeType = 'application/octet-stream',
          bool safetyCheck = false}) =>
      SlimDataUri.parse('data:$mimeType;base64,$payload',
          safetyCheck: safetyCheck);

  // payload must be percent-encoded
  factory SlimDataUri.percent(String payload,
          {String mimeType = 'application/octet-stream',
          bool safetyCheck = false}) =>
      SlimDataUri.parse('data:$mimeType,$payload', safetyCheck: safetyCheck);

  // payload must be percent-encoded
  factory SlimDataUri.parse(String contentText, {bool safetyCheck = false}) {
    // find path start
    var comma = contentText.indexOf(',');
    if (comma < 0) {
      contentText = 'data:,$contentText';
      comma = 'data:,'.length;
    }
    var header = contentText.substring(0, comma);
    // check scheme
    var colon = header.indexOf(':');
    if (colon >= 0) {
      // accept data scheme only
      final scheme = header.substring(0, colon).toLowerCase();
      if (scheme != 'data') {
        throw UnsupportedError('Unsupported scheme "$scheme"');
      }
    } else {
      // force data scheme
      contentText = 'data:$contentText';
      comma += 'data:'.length;
      colon = 'data:'.length;
      header = contentText.substring(0, comma);
    }
    // extract mime-type if present
    var mimeType = header.substring(colon + 1, comma);
    var isBase64 = false;
    final semicolon = mimeType.indexOf(';');
    var params = '';
    if (semicolon >= 0) {
      isBase64 = mimeType.toLowerCase().endsWith(';base64');
      params = mimeType.substring(semicolon + 1);
      if (isBase64) {
        params = params.substring(0, params.length - 'base64'.length);
        if (params.endsWith(';')) {
          params = params.substring(0, params.length - 1);
        }
      }
      mimeType = mimeType.substring(0, semicolon);
    }
    if (mimeType.isEmpty) {
      // force 'application/octet-stream' mime type
      mimeType = 'application/octet-stream';
    }
    // check payload
    if (safetyCheck) {
      if (isBase64) {
        _checkBase64(contentText, comma + 1);
      } else {
        _checkPercentEncoded(contentText, comma + 1);
      }
    }
    // build SlimDataUri
    final uri = SlimDataUri._(contentText, colon + 1, comma + 1);
    uri.data = createSlimUriData(mimeType, uri, params, isBase64);
    return uri;
  }

  static void _checkBase64(String contentText, int start) {
    final allowed = <int>{};
    allowed.addAll('abcdefghijklmnopqrstuvwxyz'
            'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
            '0123456789+/='
        .codeUnits);
    final len = contentText.length;
    for (var i = start; i < len; i++) {
      if (!allowed.contains(contentText.codeUnitAt(i))) {
        throw Exception('Invalid base64 payload');
      }
    }
  }

  static void _checkPercentEncoded(String contentText, int start) {
    final reserved = <int>{};
    for (var i = 0; i < 32; i++) {
      reserved.add((i));
    }
    reserved.addAll(percent_codec.reserved);
    reserved.remove(0x25); // allow '%' in percent-encoded payload!
    final len = contentText.length;
    for (var i = start; i < len; i++) {
      if (reserved.contains(contentText.codeUnitAt(i))) {
        throw Exception('Invalid parcent-encoded payload');
      }
    }
  }

  final String _contentText;
  final int _pathStart;
  final int _payloadStart;

  String get payload => _contentText.substring(_payloadStart);

  @override
  late final SlimUriData data;

  @override
  String get authority => '';

  @override
  String get fragment => '';

  @override
  bool get hasAbsolutePath => false;

  @override
  bool get hasAuthority => false;

  @override
  bool get hasEmptyPath => false;

  @override
  bool get hasFragment => false;

  @override
  bool get hasPort => false;

  @override
  bool get hasQuery => false;

  @override
  bool get hasScheme => true;

  @override
  String get host => '';

  @override
  bool get isAbsolute => false;

  @override
  bool isScheme(String scheme) => scheme.toLowerCase().compareTo('data') == 0;

  bool get isSafeContent {
    try {
      if (data.isBase64) {
        _checkBase64(_contentText, _payloadStart);
      } else {
        _checkPercentEncoded(_contentText, _payloadStart);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Uri normalizePath() => this;

  @override
  String get origin => '';

  @override
  String get path => _contentText.substring(_pathStart);

  @override
  List<String> get pathSegments => [path];

  @override
  int get port => 0;

  @override
  String get query => '';

  @override
  Map<String, String> get queryParameters => const {};

  @override
  Map<String, List<String>> get queryParametersAll => const {};

  @override
  Uri removeFragment() => this;

  @override
  Uri replace(
      {String? scheme,
      String? userInfo,
      String? host,
      int? port,
      String? path,
      Iterable<String>? pathSegments,
      String? query,
      Map<String, dynamic>? queryParameters,
      String? fragment}) {
    throw UnimplementedError();
  }

  @override
  Uri resolve(String reference) => this;

  @override
  Uri resolveUri(Uri reference) => this;

  @override
  String get scheme => 'data';

  @override
  String toFilePath({bool? windows}) {
    throw UnimplementedError();
  }

  @override
  String get userInfo => '';

  @override
  String toString() => _contentText;
}
