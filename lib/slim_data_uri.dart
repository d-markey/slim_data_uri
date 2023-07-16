export 'src/slim_data_uri.dart';
export 'src/percent_codec.dart' hide reserved;

import 'src/slim_data_uri.dart';

Uri parseUri(String uri, {bool safetyCheck = false}) =>
    (uri.length > 'data:'.length &&
            uri.substring(0, 'data:'.length).toLowerCase() == 'data:')
        ? SlimDataUri.parse(uri, safetyCheck: safetyCheck)
        : Uri.parse(uri);
