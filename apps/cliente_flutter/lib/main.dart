import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/places_provider.dart';
import 'providers/reservations_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() {
  // El arranque deja toda la composición global dentro de `PracticoFinalApp`
  // para que el flujo de sesión se lea de punta a punta: runApp -> providers ->
  // pantalla inicial.
  runApp(const PracticoFinalApp());
}

/// Punto de entrada real de la app cliente.
///
/// `MultiProvider` concentra el estado compartido que define qué datos se pueden
/// mostrar y qué flujo debe seguir la persona usuaria.
class PracticoFinalApp extends StatelessWidget {
  const PracticoFinalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // AuthProvider es la fuente de verdad de la sesión. Si cambia la
        // identidad autenticada, el resto de la app se entera desde acá.
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, PlacesProvider>(
          create: (_) => PlacesProvider(),
          update: (_, authProvider, placesProvider) {
            final provider = placesProvider ?? PlacesProvider();
            // `syncSession()` baja la identidad actual al dominio de lugares.
            // Así el provider decide si conserva datos, los limpia o vuelve a
            // pedirlos sin depender del árbol de widgets.
            provider.syncSession(authProvider.currentUser);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, ReservationsProvider>(
          create: (_) => ReservationsProvider(),
          update: (_, authProvider, reservationsProvider) {
            final provider = reservationsProvider ?? ReservationsProvider();
            // Misma idea para reservas: la sesión manda, y el provider de
            // dominio ajusta su estado sin mezclar autenticación con UI.
            provider.syncSession(authProvider.currentUser);
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'StayHub Cliente',
        theme: AppTheme.lightTheme,
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            // Decisión de UX al iniciar:
            // - con una sesión utilizable, la app entra directo a Home;
            // - sin identidad válida, obliga a pasar por Login.
            //
            // La decisión usa el contrato real de autenticación: la app necesita
            // un cliente identificable, no necesariamente un Bearer token.
            if (authProvider.isAuthenticated) {
              return const HomeScreen();
            }

            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
