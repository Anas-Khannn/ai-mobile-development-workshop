import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/auth_service.dart';
import '../../data/models.dart';
import '../../ui/common.dart';
import '../navigation.dart';
import 'auth_widgets.dart';
import 'login_screen.dart';

/// First stop for new users: pick a role and create an account. On success
/// the user is sent to the login screen.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  UserRole _role = UserRole.student;
  bool _loading = false;
  bool _googleLoading = false;
  String? _error;
  int _shakes = 0;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) {
      setState(() => _shakes++);
      return;
    }
    setState(() => _loading = true);
    final AuthService auth = AppScope.of(context).auth;
    try {
      // A short pause lets the button's loading morph play out.
      await Future<void>.delayed(const Duration(milliseconds: 700));
      await auth.signUp(
        name: _name.text,
        email: _email.text,
        password: _password.text,
        role: _role,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        slideRoute<void>(
          LoginScreen(
            initialEmail: _email.text.trim(),
            notice:
                'Account created as a ${_role.label.toLowerCase()}. '
                'Log in to continue.',
          ),
        ),
      );
    } on AuthException catch (error) {
      setState(() {
        _loading = false;
        _error = error.message;
        _shakes++;
      });
    }
  }

  Future<void> _google() async {
    setState(() {
      _error = null;
      _googleLoading = true;
    });
    final String? error = await continueWithGoogle(context, role: _role);
    if (mounted) {
      setState(() {
        _googleLoading = false;
        _error = error;
        if (error != null) _shakes++;
      });
    }
  }

  void _goToLogin() {
    Navigator.of(
      context,
    ).pushReplacement(slideRoute<void>(const LoginScreen(), fromRight: false));
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Create account',
      subtitle: 'Join Studyy Buddy as a teacher or a student',
      children: <Widget>[
        RolePicker(
          value: _role,
          onChanged: (UserRole role) => setState(() => _role = role),
        ),
        ShakeOnChange(
          trigger: _shakes,
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AuthErrorBanner(message: _error),
                  AuthTextField(
                    key: const ValueKey<String>('signup_name'),
                    controller: _name,
                    label: 'Full name',
                    icon: Icons.person_outline_rounded,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const <String>[AutofillHints.name],
                    validator: (String? v) =>
                        (v?.trim().length ?? 0) < 2 ? 'Enter your name' : null,
                  ),
                  AuthTextField(
                    key: const ValueKey<String>('signup_email'),
                    controller: _email,
                    label: 'Email',
                    icon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const <String>[AutofillHints.email],
                    validator: validateEmail,
                  ),
                  PasswordField(
                    key: const ValueKey<String>('signup_password'),
                    controller: _password,
                    showStrength: true,
                    autofillHints: const <String>[AutofillHints.newPassword],
                    validator: validateNewPassword,
                  ),
                  PasswordField(
                    key: const ValueKey<String>('signup_confirm'),
                    controller: _confirm,
                    label: 'Confirm password',
                    textInputAction: TextInputAction.done,
                    autofillHints: const <String>[AutofillHints.newPassword],
                    onSubmitted: (_) => _submit(),
                    validator: (String? v) =>
                        v != _password.text ? 'Passwords do not match' : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedSubmitButton(
          key: const ValueKey<String>('signup_submit'),
          label: 'Create account',
          loading: _loading,
          onPressed: _submit,
        ),
        const OrDivider(),
        GoogleButton(
          label: 'Sign up with Google',
          loading: _googleLoading,
          onPressed: _google,
        ),
        const SizedBox(height: 12),
        SwitchAuthLink(
          prompt: 'Already have an account?',
          action: 'Log in',
          onTap: _goToLogin,
          buttonKey: const ValueKey<String>('go_login'),
        ),
      ],
    );
  }
}
