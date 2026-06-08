import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/app_text_field.dart';
import '../widgets/minimal_card.dart';
import '../widgets/primary_button.dart';
import 'register_screen.dart';

/// Pantalla de autenticación del cliente.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted || success || authProvider.errorMessage == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(authProvider.errorMessage!)),
    );
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text('StayHub', style: theme.textTheme.headlineLarge),
              const SizedBox(height: 12),
              Text(
                'Inicia sesión para buscar alojamientos con una interfaz simple, limpia y enfocada en el flujo cliente del PDF.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              MinimalCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Iniciar sesión', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 20),
                      AppTextField(
                        label: 'Email',
                        hint: 'ejemplo@correo.com',
                        icon: Icons.alternate_email,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) {
                            return 'El email es obligatorio.';
                          }
                          if (!text.contains('@')) {
                            return 'Ingresa un email válido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Contraseña',
                        icon: Icons.lock_outline,
                        controller: _passwordController,
                        obscureText: true,
                        validator: (value) {
                          if ((value ?? '').isEmpty) {
                            return 'La contraseña es obligatoria.';
                          }
                          if ((value ?? '').length < 6) {
                            return 'Usa al menos 6 caracteres.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Ingresar',
                        icon: Icons.login,
                        isLoading: authProvider.isLoading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: 'Crear cuenta',
                        icon: Icons.person_add_alt_1,
                        isSecondary: true,
                        onPressed: _goToRegister,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
             
            ],
          ),
        ),
      ),
    );
  }
}
