import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/auth_service.dart';
import '../../data/models.dart';
import '../../ui/common.dart';
import '../navigation.dart';
import 'auth_widgets.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.initialEmail, this.notice});

  /// Prefilled after sign-up or a password reset.
  final String? initialEmail;

  /// Shown once in a snack bar when the screen opens.
  final String? notice;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _email = TextEditingController(
    text: widget.initialEmail,
  );
  final TextEditingController _password = TextEditingController();

  bool _loading = false;
  bool _googleLoading = false;
  String? _error;
  int _shakes = 0;

  @override
  void initState() {
    super.initState();
    final String? notice = widget.notice;
    if (notice != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: <Widget>[
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text(notice)),
              ],
            ),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
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
      await Future<void>.delayed(const Duration(milliseconds: 700));
      final AppUser user = await auth.logIn(
        email: _email.text,
        password: _password.text,
      );
      if (mounted) goHome(context, user);
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
    final String? error = await continueWithGoogle(context);
    if (mounted) {
      setState(() {
        _googleLoading = false;
        _error = error;
        if (error != null) _shakes++;
      });
    }
  }

  Future<void> _forgotPassword() async {
    final String? email = await Navigator.of(context).push<String>(
      slideRoute<String>(
        ForgotPasswordScreen(initialEmail: _email.text.trim()),
      ),
    );
    if (email != null && mounted) {
      setState(() {
        _email.text = email;
        _password.clear();
        _error = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Password updated. Log in with your new password.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Welcome back',
      subtitle: 'Log in to keep learning with Studyy Buddy',
      children: <Widget>[
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
                    key: const ValueKey<String>('login_email'),
                    controller: _email,
                    label: 'Email',
                    icon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const <String>[AutofillHints.email],
                    validator: validateEmail,
                  ),
                  PasswordField(
                    key: const ValueKey<String>('login_password'),
                    controller: _password,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    validator: (String? v) =>
                        (v ?? '').isEmpty ? 'Enter your password' : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            key: const ValueKey<String>('go_forgot'),
            onPressed: _forgotPassword,
            child: const Text('Forgot password?'),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedSubmitButton(
          key: const ValueKey<String>('login_submit'),
          label: 'Log in',
          loading: _loading,
          onPressed: _submit,
        ),
        const OrDivider(),
        GoogleButton(
          label: 'Continue with Google',
          loading: _googleLoading,
          onPressed: _google,
        ),
        const SizedBox(height: 12),
        SwitchAuthLink(
          prompt: 'New to Studyy Buddy?',
          action: 'Create an account',
          buttonKey: const ValueKey<String>('go_signup'),
          onTap: () =>
              Navigator.of(context)
                  .pushReplacement(slideRoute<void>(const SignUpScreen())),
        ),
      ],
    );
  }
}
