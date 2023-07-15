* slim_data_uri

A drop-in, lightweight replacement for "data:" Uri.

Example:

```dart
final dataUri = parseUri('data:audio/mpeg;base64,....');
print(dataUri.runtimeType); // SlimDataUri

final uri = parseUri('http://www.google.com');
print(uri.runtimeType); // Uri
```
