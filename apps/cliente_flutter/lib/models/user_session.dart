class UserSession {
  UserSession({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.token,
    required this.rawData,
  });

  final int id;
  final String email;
  final String fullName;
  final String phone;
  final String token;
  final Map<String, dynamic> rawData;

  String get displayName => fullName.isEmpty ? email : fullName;
  bool get hasIdentifier => id > 0;

  /// Tener usuario parseado NO siempre significa tener sesión abierta.
  ///
  /// Para este práctico, consideramos autenticada únicamente una respuesta
  /// que trae token usable.
  bool get hasToken => token.trim().isNotEmpty;

  factory UserSession.fromJson(Map<String, dynamic> json) {
    final nestedUser = _extractNestedUser(json);

    return UserSession(
      id: _readInt(nestedUser['id'] ?? json['id'] ?? json['cliente_id']),
      email: _readString(nestedUser['email'] ?? json['email']),
      fullName: _readString(
        nestedUser['nombrecompleto'] ??
            nestedUser['nombre'] ??
            nestedUser['name'] ??
            json['nombrecompleto'] ??
            json['nombre'],
      ),
      phone: _readString(
        nestedUser['telefono'] ??
            nestedUser['phone'] ??
            json['telefono'] ??
            json['phone'],
      ),
      token: _readString(
        json['token'] ??
            json['access_token'] ??
            json['plainTextToken'] ??
            json['bearer_token'],
      ),
      rawData: json,
    );
  }

  static Map<String, dynamic> _extractNestedUser(Map<String, dynamic> json) {
    const candidates = ['user', 'cliente', 'data'];

    for (final key in candidates) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
    }

    return json;
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }

    return int.tryParse('$value') ?? 0;
  }

  static String _readString(Object? value) {
    return value == null ? '' : '$value'.trim();
  }
}
