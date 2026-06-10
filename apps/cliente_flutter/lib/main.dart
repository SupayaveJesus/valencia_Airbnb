import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/places_provider.dart';
import 'providers/reservations_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'widgets/mock_mode_indicator.dart';

void main() {
  runApp(const PracticoFinalApp());
}

/// Punto de entrada real de la app cliente.
///
/// Se usa MultiProvider porque el práctico ya viene trabajando con estado simple,
/// explícito y fácil de defender en clase.
class PracticoFinalApp extends StatelessWidget {
  const PracticoFinalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, PlacesProvider>(
          create: (_) => PlacesProvider(),
          update: (_, authProvider, placesProvider) {
            final provider = placesProvider ?? PlacesProvider();
            provider.syncSession(authProvider.currentUser);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, ReservationsProvider>(
          create: (_) => ReservationsProvider(),
          update: (_, authProvider, reservationsProvider) {
            final provider = reservationsProvider ?? ReservationsProvider();
            provider.syncSession(authProvider.currentUser);
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'StayHub Cliente',
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return Stack(
            children: [
              child ?? const SizedBox.shrink(),
              const MockModeIndicator(),
            ],
          );
        },
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
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
