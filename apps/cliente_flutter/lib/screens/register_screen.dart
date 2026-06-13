import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/app_text_field.dart';
import '../widgets/minimal_card.dart';
import '../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Igual que en login, los controllers solo capturan input. El contrato con la
  // API y el estado observable viven en provider/service, no en el widget.
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Envía el formulario y decide qué pantalla mostrar según la respuesta real.
  ///
  /// La UX distingue dos caminos sanos:
  /// - si el registro ya deja sesión abierta, volvemos al inicio autenticados;
  /// - si solo crea la cuenta, regresamos a login con el siguiente paso claro.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.register(
      fullName: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      phone: _phoneController.text,
    );

    if (!mounted) {
      return;
    }

    if (result.isAuthenticated) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    if (result.isSuccess) {
      // Devolvemos el mensaje a LoginScreen para que el feedback aparezca en el
      // lugar donde la persona usuaria debe ejecutar el siguiente paso.
      Navigator.of(context).pop(result.message);
      return;
    }

    if (authProvider.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authProvider.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: MinimalCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crear cuenta cliente',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  // El formulario reúne los datos visibles; el provider/service
                  // los traduce después al contrato HTTP real de la API.
                  AppTextField(
                    label: 'Nombre completo',
                    controller: _nameController,
                    icon: Icons.person_outline,
                    validator: (value) {
                      if ((value ?? '').trim().length < 3) {
                        return 'Ingresa un nombre válido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Email',
                    controller: _emailController,
                    icon: Icons.alternate_email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty || !text.contains('@')) {
                        return 'Ingresa un email válido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Teléfono',
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if ((value ?? '').trim().length < 7) {
                        return 'Ingresa un teléfono válido.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Contraseña',
                    controller: _passwordController,
                    icon: Icons.lock_outline,
                    obscureText: true,
                    validator: (value) {
                      if ((value ?? '').length < 6) {
                        return 'Usa al menos 6 caracteres.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Registrarme',
                    icon: Icons.how_to_reg,
                    isLoading: authProvider.isLoading,
                    // El botón no decide la navegación por su cuenta. Dispara
                    // `_submit()`, y el resultado del provider define el flujo.
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
