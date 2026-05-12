const String _defaultBaseUrl = 'https://serverflowers.onrender.com';

const String _configuredBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: _defaultBaseUrl,
);

String get baseUrl {
  final value = _configuredBaseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
  return value.isEmpty ? _defaultBaseUrl : value;
}
