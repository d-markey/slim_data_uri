export 'src/slim_data_uri.dart';
export 'src/percent_codec.dart';

import 'src/slim_data_uri.dart';

Uri parseUri(String uri) => (uri.length > 'data:'.length &&
        uri.substring(0, 'data:'.length).toLowerCase() == 'data:')
    ? SlimDataUri.parse(uri)
    : Uri.parse(uri);
