export 'src/slim_data_uri.dart';

import 'src/slim_data_uri.dart';

Uri parseUri(String uri, {bool safetyCheck = false}) =>
    (uri.length > 'data:'.length &&
            uri.substring(0, 'data:'.length).toLowerCase() == 'data:')
        ? SlimDataUri.parse(uri, safetyCheck: safetyCheck)
        : Uri.parse(uri);
