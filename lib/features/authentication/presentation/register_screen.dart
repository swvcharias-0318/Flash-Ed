import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_providers.dart';
import 'auth_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _course = TextEditingController();
  final _yearLevel = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _isBusy = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _course.dispose();
    _yearLevel.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isBusy = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .register(
            fullName: _name.text,
            email: _email.text,
            password: _password.text,
            course: _course.text,
            yearLevel: _yearLevel.text,
          );
    } catch (error) {
      if (mounted) showAuthError(context, error);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      title: 'Create your account',
      subtitle: 'A few details, then you can start building your study sets.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('register-name'),
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: (value) => (value == null || value.trim().length < 2)
                  ? 'Enter your full name.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('register-email'),
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: validateEmail,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('register-course'),
              controller: _course,
              decoration: const InputDecoration(
                labelText: 'Course / program',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter your course or program.'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('register-year'),
              initialValue: null,
              decoration: const InputDecoration(
                labelText: 'Year level',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              items:
                  const [
                        '1st Year',
                        '2nd Year',
                        '3rd Year',
                        '4th Year',
                        'Other',
                      ]
                      .map(
                        (year) =>
                            DropdownMenuItem(value: year, child: Text(year)),
                      )
                      .toList(),
              onChanged: (value) => _yearLevel.text = value ?? '',
              validator: (value) =>
                  value == null ? 'Select your year level.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('register-password'),
              controller: _password,
              decoration: InputDecoration(
                labelText: 'Password',
                helperText:
                    'At least 8 characters, including a letter and a number.',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              validator: validatePassword,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('register-confirm-password'),
              controller: _confirmPassword,
              decoration: const InputDecoration(
                labelText: 'Confirm password',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _register(),
              validator: (value) =>
                  value != _password.text ? 'Passwords do not match.' : null,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isBusy ? null : _register,
              child: _isBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create account'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Already have an account? Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
