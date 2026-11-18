import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/components.dart';
import '../widgets/effects.dart';
import 'admin/admin_shell.dart';
import 'main_shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _register = false;
  bool _loading = false;
  bool _obscure = true;
  bool _vendor = false;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _form = GlobalKey<FormState>();

  /// Errors only show after a submit attempt, and are cleared when the user
  /// switches between sign-in and create-account.
  bool _submitted = false;

  String? _error(bool invalid, String message) => _submitted && invalid ? message : null;

  void _toggleMode() {
    setState(() {
      _register = !_register;
      _submitted = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _form.currentState?.validate());
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1300)); // simulated network
    if (!mounted) return;
    final state = AppScope.read(context);
    final name = _register ? _name.text.trim() : _email.text.split('@').first;
    state.signIn(name.isEmpty ? 'Guest' : '${name[0].toUpperCase()}${name.substring(1)}');
    Navigator.of(
      context,
    ).pushAndRemoveUntil(premiumRoute(_vendor ? const AdminShell() : const MainShell()), (_) => false);
  }

  void _continueAsGuest() {
    AppScope.read(context).signIn(_vendor ? 'Admin' : 'Guest');
    Navigator.of(
      context,
    ).pushAndRemoveUntil(premiumRoute(_vendor ? const AdminShell() : const MainShell()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AuroraBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Reveal(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: p.auroraGradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: p.accent.withValues(alpha: 0.5),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'L',
                          style: context.text.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Reveal(
                    delay: Reveal.stagger(1),
                    child: AnimatedSwitcher(
                      duration: Motion.medium,
                      transitionBuilder: (c, a) => FadeTransition(
                        opacity: a,
                        child: SlideTransition(
                          position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(a),
                          child: c,
                        ),
                      ),
                      child: Column(
                        key: ValueKey(_register),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _register ? 'Create your\naccount' : 'Welcome\nback',
                            style: context.text.displaySmall?.copyWith(height: 1.05),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _register
                                ? 'Join 2M+ members and unlock exclusive drops.'
                                : 'Sign in to continue your curated journey.',
                            style: context.text.bodyLarge?.copyWith(color: p.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Reveal(
                    delay: Reveal.stagger(2),
                    child: _Segmented(vendor: _vendor, onChanged: (v) => setState(() => _vendor = v)),
                  ),
                  const SizedBox(height: 20),
                  AnimatedSize(
                    duration: Motion.medium,
                    curve: Motion.emphasized,
                    child: _register
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _Field(controller: _name, hint: 'Full name', icon: Icons.person_outline_rounded),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                  Reveal(
                    delay: Reveal.stagger(3),
                    child: _Field(
                      controller: _email,
                      hint: 'Email address',
                      icon: Icons.alternate_email_rounded,
                      keyboard: TextInputType.emailAddress,
                      validator: (v) => _error(v == null || !v.contains('@'), 'Enter a valid email'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Reveal(
                    delay: Reveal.stagger(4),
                    child: _Field(
                      controller: _pass,
                      hint: 'Password',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscure,
                      validator: (v) => _error(v == null || v.length < 6, 'At least 6 characters'),
                      suffix: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: AnimatedSwitcher(
                          duration: Motion.fast,
                          child: Icon(
                            _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            key: ValueKey(_obscure),
                            color: p.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!_register)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => showComingSoon(
                          context,
                          title: 'Reset password',
                          icon: Icons.lock_reset_rounded,
                          body:
                              'We'
                              'll email you a secure reset link once accounts are connected.',
                        ),
                        child: Text('Forgot password?', style: TextStyle(color: p.accent)),
                      ),
                    )
                  else
                    const SizedBox(height: 16),
                  const SizedBox(height: 8),
                  Reveal(
                    delay: Reveal.stagger(5),
                    child: GradientButton(
                      label: _register ? 'Create account' : 'Sign in',
                      loading: _loading,
                      onTap: _submit,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Reveal(
                    delay: Reveal.stagger(6),
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: p.stroke)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or continue with', style: context.text.bodySmall?.copyWith(color: p.textMuted)),
                        ),
                        Expanded(child: Divider(color: p.stroke)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Reveal(
                    delay: Reveal.stagger(7),
                    child: Row(
                      children: [
                        for (final (icon, label) in [
                          (Icons.apple_rounded, 'Apple'),
                          (Icons.g_mobiledata_rounded, 'Google'),
                          (Icons.fingerprint_rounded, 'Passkey'),
                        ]) ...[
                          Expanded(
                            child: Pressable(
                              onTap: () => showComingSoon(
                                context,
                                title: 'Continue with $label',
                                icon: icon,
                                body:
                                    'One-tap sign-in with $label activates once authentication is connected. Use email or browse as a guest for now.',
                              ),
                              child: Glass(
                                radius: Radii.md,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: Column(
                                  children: [
                                    Icon(icon, size: 26),
                                    const SizedBox(height: 4),
                                    Text(label, style: context.text.labelSmall),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (label != 'Passkey') const SizedBox(width: 12),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: TextButton(
                      onPressed: _toggleMode,
                      child: Text.rich(
                        TextSpan(
                          text: _register ? 'Already a member? ' : 'New to Lumière? ',
                          style: TextStyle(color: p.textSecondary),
                          children: [
                            TextSpan(
                              text: _register ? 'Sign in' : 'Create account',
                              style: TextStyle(color: p.accent, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: TextButton.icon(
                      onPressed: _continueAsGuest,
                      iconAlignment: IconAlignment.end,
                      icon: Icon(Icons.arrow_forward_rounded, size: 16, color: p.textMuted),
                      label: Text(
                        _vendor ? 'Open demo dashboard' : 'Browse as guest',
                        style: TextStyle(color: p.textMuted),
                      ),
                    ),
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

class _Segmented extends StatelessWidget {
  const _Segmented({required this.vendor, required this.onChanged});
  final bool vendor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Glass(
      radius: 20,
      padding: const EdgeInsets.all(5),
      child: SizedBox(
        height: 44,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth / 2;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: Motion.slow,
                  curve: Motion.emphasized,
                  left: vendor ? w : 0,
                  width: w,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: p.surfaceHigh,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: p.shadow.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (final (i, label, icon) in [
                      (false, 'Shopper', Icons.shopping_bag_outlined),
                      (true, 'Vendor / Admin', Icons.storefront_outlined),
                    ])
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onChanged(i),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: Motion.medium,
                              style: context.text.labelLarge!.copyWith(
                                color: vendor == i ? p.textPrimary : p.textMuted,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon, size: 16, color: vendor == i ? p.accent : p.textMuted),
                                  const SizedBox(width: 6),
                                  Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Field extends StatefulWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboard,
    this.validator,
  });
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboard;
  final FormFieldValidator<String>? validator;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final focused = _focus.hasFocus;
    return AnimatedContainer(
      duration: Motion.medium,
      curve: Motion.emphasized,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.md),
        boxShadow: focused
            ? [BoxShadow(color: p.accent.withValues(alpha: 0.28), blurRadius: 22, offset: const Offset(0, 8))]
            : const [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focus,
        obscureText: widget.obscure,
        keyboardType: widget.keyboard,
        validator: widget.validator,
        style: context.text.bodyLarge,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: AnimatedSwitcher(
            duration: Motion.fast,
            child: Icon(widget.icon, key: ValueKey(focused), color: focused ? p.accent : p.textMuted),
          ),
          suffixIcon: widget.suffix,
        ),
      ),
    );
  }
}
