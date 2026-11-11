import 'dart:convert';

String? samsungToken(String? stored, String pin) {
  if (stored == null) {
    return null;
  }
  try {
    final data = jsonDecode(stored);
    if (data case {'pin': String savedPin, 'token': String token}
        when savedPin == pin && validSamsungToken(token)) {
      return token;
    }
  } on FormatException {
    return null;
  }
  return null;
}

bool validSamsungToken(String value) =>
    RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(value);

String encodeSamsungToken(String pin, String token) =>
    jsonEncode({'pin': pin, 'token': token});
