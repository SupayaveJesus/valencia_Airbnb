class UserSession {
  UserSession({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.token,
    required this.rawData,
  });

  /// Datos mínimos que la app necesita recordar del cliente autenticado.
  ///
  /// Importante: este modelo NO representa todo el perfil del backend. Solo
  /// guarda la identidad y los datos prácticos que otras capas consumen para
  /// decidir si hay sesión utilizable y para personalizar la experiencia.
  final int id;
  final String email;
  final String fullName;
  final String phone;

  /// `token` queda disponible para endpoints que sí exijan Bearer, aunque el
  /// flujo actual pueda quedar autenticado solo con identidad de cliente.
  final String token;

  /// `rawData` guarda el payload original por si más adelante hace falta
  /// inspeccionar campos que este modelo todavía no expone formalmente.
  final Map<String, dynamic> rawData;

  String get displayName => fullName.isEmpty ? email : fullName;
  bool get hasIdentifier => id > 0;
  bool get hasIdentity => hasIdentifier || email.isNotEmpty;

  /// Tener usuario parseado NO siempre significa tener sesión ABIERTA.
  ///
  /// En este cliente, una sesión usable existe cuando el backend identifica de
  /// forma estable al cliente autenticado. Si además llega token, mejor: queda
  /// listo para endpoints protegidos. Si no llega, la app igual puede decidir
  /// correctamente Home vs Login y personalizar la navegación actual.
  bool get hasToken => token.trim().isNotEmpty;
  bool get isAuthenticatedSession => hasIdentity;

  factory UserSession.fromJson(Map<String, dynamic> json) {
    // El backend no siempre entrega la identidad con la misma estructura.
    // Primero normalizamos dónde vive el cliente; después leemos campos.
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
        // Convertimos mapas dinámicos a `Map<String, dynamic>` para que el resto
        // del parseo trabaje con un contrato estable y predecible.
        return Map<String, dynamic>.from(value);
      }
    }

    return json;
  }

  static int _readInt(Object? value) {
    // El backend puede enviar ids como número o string. Este helper absorbe esa
    // variación para que el modelo exponga un entero consistente.
    if (value is int) {
      return value;
    }

    return int.tryParse('$value') ?? 0;
  }

  static String _readString(Object? value) {
    // Normalizamos `null`, strings y otros valores a texto limpio para que UI y
    // providers reaccionen a datos consistentes, no a espacios o nulls sueltos.
    return value == null ? '' : '$value'.trim();
  }
}
