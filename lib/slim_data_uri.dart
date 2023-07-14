export 'src/slim_data_uri.dart';
export 'src/percent_codec.dart';

import 'src/slim_data_uri.dart';

Uri parseUri(String uri) {
  final parser = (uri.length > 'data:'.length &&
          uri.substring(0, 'data:'.length).toLowerCase() == 'data:')
      ? SlimDataUri.parse
      : Uri.parse;
  return parser(uri);
}
