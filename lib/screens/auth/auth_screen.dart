import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/auth_service.dart';
import 'auth_gate.dart';

const _forest = Color(0xFF006D44);
const _emerald = Color(0xFF00A669);
const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _border = Color(0xFFE5E7EB);

enum AuthTab { signIn, signUp }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.initialTab = AuthTab.signIn});

  final AuthTab initialTab;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = AuthService();
  late AuthTab _tab;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _signUpPasswordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureSignIn = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreed = false;
  bool _loading = false;
  String _countryCode = '+92';
  String _role = 'individual';
  DateTime? _dob;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _signUpPasswordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool get _hasMinLength => _signUpPasswordCtrl.text.length >= 8;
  bool get _hasNumber => RegExp(r'\d').hasMatch(_signUpPasswordCtrl.text);
  bool get _hasUpper => RegExp(r'[A-Z]').hasMatch(_signUpPasswordCtrl.text);
  bool get _hasSpecial => RegExp(
        r'[!@#$%^&*(),.?":{}|<>_\-\[\]\\;/+=~`]',
      ).hasMatch(_signUpPasswordCtrl.text);

  void _switchTab(AuthTab tab) => setState(() => _tab = tab);

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
      if (!mounted) return;
      await navigateAfterAuth(context, _auth);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_auth.messageFor(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signIn() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter email and password')),
      );
      return;
    }
    await _run(() => _auth.signInWithEmail(email: email, password: password));
  }

  Future<void> _signUp() async {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms of Service')),
      );
      return;
    }
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth')),
      );
      return;
    }

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = '$_countryCode ${_phoneCtrl.text.trim()}'.trim();
    final password = _signUpPasswordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (name.isEmpty || email.isEmpty || _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }
    if (!_hasMinLength || !_hasNumber || !_hasUpper || !_hasSpecial) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password does not meet the requirements')),
      );
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    final dob =
        '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}';

    await _run(
      () => _auth.signUpWithEmail(
        fullName: name,
        email: email,
        password: password,
        phone: phone,
        role: _role,
        dateOfBirth: dob,
      ),
    );
  }

  Future<void> _google() async {
    if (_tab == AuthTab.signUp && !_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms of Service')),
      );
      return;
    }
    await _run(() => _auth.signInWithGoogle());
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email to reset the password')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reset email sent to $email')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_auth.messageFor(e))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: _forest),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _dob = picked);
  }

  void _comingSoon(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$provider — coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSignIn = _tab == AuthTab.signIn;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final footerHeight = constraints.maxWidth * (1024 / 1536);

          return Column(
            children: [
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: constraints.maxWidth - 32,
                        child: Column(
                  children: [
                    _TopBar(onBack: () => Navigator.of(context).maybePop()),
                    _Branding(compact: !isSignIn),
                    const SizedBox(height: 4),
                    _AuthTabs(tab: _tab, onChanged: _switchTab),
                    const SizedBox(height: 6),
                    if (isSignIn) ...[
                      _AuthField(
                        controller: _emailCtrl,
                        hint: 'Email or Phone Number',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 8),
                      _AuthField(
                        controller: _passwordCtrl,
                        hint: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscureSignIn,
                        onToggleObscure: () =>
                            setState(() => _obscureSignIn = !_obscureSignIn),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _loading ? null : _forgotPassword,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.plusJakartaSans(
                              color: _forest,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      _PrimaryButton(
                        label: 'Sign In',
                        loading: _loading,
                        onPressed: _signIn,
                      ),
                      const SizedBox(height: 10),
                    ] else ...[
                      Text(
                        'Create your account',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                      Text(
                        'Join Ability Link and be a part of an inclusive community.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          height: 1.2,
                          color: _muted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'I am a',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _RoleRow(
                        selected: _role,
                        onSelected: (v) => setState(() => _role = v),
                      ),
                      const SizedBox(height: 6),
                      _AuthField(
                        controller: _nameCtrl,
                        hint: 'Full Name',
                        icon: Icons.person_outline_rounded,
                        keyboardType: TextInputType.name,
                        compact: true,
                      ),
                      const SizedBox(height: 4),
                      _AuthField(
                        controller: _emailCtrl,
                        hint: 'Email Address',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        compact: true,
                      ),
                      const SizedBox(height: 4),
                      _PhoneField(
                        controller: _phoneCtrl,
                        countryCode: _countryCode,
                        compact: true,
                        onCodeChanged: (v) =>
                            setState(() => _countryCode = v),
                      ),
                      const SizedBox(height: 4),
                      _AuthField(
                        controller: _signUpPasswordCtrl,
                        hint: 'Create Password',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscurePassword,
                        compact: true,
                        onToggleObscure: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _AuthField(
                        controller: _confirmCtrl,
                        hint: 'Confirm Password',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscureConfirm,
                        compact: true,
                        onToggleObscure: () => setState(
                          () => _obscureConfirm = !_obscureConfirm,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _DateField(dob: _dob, onTap: _pickDob),
                      const SizedBox(height: 2),
                      _TermsRow(
                        agreed: _agreed,
                        onChanged: (v) => setState(() => _agreed = v ?? false),
                      ),
                      const SizedBox(height: 6),
                      _PrimaryButton(
                        label: 'Create Account',
                        loading: _loading,
                        onPressed: _signUp,
                        compact: true,
                      ),
                    ],
                    const SizedBox(height: 6),
                    const _OrDivider(),
                    const SizedBox(height: 6),
                    _SocialRow(
                      loading: _loading,
                      signUp: !isSignIn,
                      onGoogle: _google,
                      onApple: () => _comingSoon('Apple'),
                      onFacebook: () => _comingSoon('Facebook'),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text.rich(
                        TextSpan(
                          text: isSignIn
                              ? "Don't have an account? "
                              : 'Already have an account? ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: _muted,
                          ),
                          children: [
                            TextSpan(
                              text: isSignIn ? 'Sign Up' : 'Sign In',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _forest,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _switchTab(
                                      isSignIn
                                          ? AuthTab.signUp
                                          : AuthTab.signIn,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: constraints.maxWidth,
                height: footerHeight,
                child: Image.asset(
                  'assets/images/auth_footer_illustration.png',
                  width: constraints.maxWidth,
                  height: footerHeight,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: onBack,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: const Icon(Icons.arrow_back_rounded, color: _forest),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language_rounded, size: 16, color: _forest),
              const SizedBox(width: 6),
              Text(
                'English',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: _muted),
            ],
          ),
        ),
      ],
    );
  }
}

class _Branding extends StatelessWidget {
  const _Branding({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/ability_link_logo_a.png',
          height: compact ? 44 : 84,
          filterQuality: FilterQuality.high,
        ),
        SizedBox(height: compact ? 0 : 4),
        RichText(
          text: TextSpan(
            style: GoogleFonts.plusJakartaSans(
              fontSize: compact ? 18 : 24,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
            children: const [
              TextSpan(text: 'Ability ', style: TextStyle(color: _forest)),
              TextSpan(text: 'Link', style: TextStyle(color: _emerald)),
            ],
          ),
        ),
        SizedBox(height: compact ? 2 : 4),
        RichText(
          text: TextSpan(
            style: GoogleFonts.plusJakartaSans(
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w600,
              color: _ink,
            ),
            children: const [
              TextSpan(text: 'Access. '),
              TextSpan(text: 'Connect. ', style: TextStyle(color: _forest)),
              TextSpan(text: 'Empower.'),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuthTabs extends StatelessWidget {
  const _AuthTabs({required this.tab, required this.onChanged});

  final AuthTab tab;
  final ValueChanged<AuthTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _TabLabel(
                label: 'Sign In',
                selected: tab == AuthTab.signIn,
                onTap: () => onChanged(AuthTab.signIn),
              ),
            ),
            Expanded(
              child: _TabLabel(
                label: 'Sign Up',
                selected: tab == AuthTab.signUp,
                onTap: () => onChanged(AuthTab.signUp),
              ),
            ),
          ],
        ),
        Stack(
          children: [
            Container(height: 2, color: _border),
            AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              alignment: tab == AuthTab.signIn
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(height: 2.5, color: _forest),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: selected ? _forest : _muted,
          ),
        ),
      ),
    );
  }
}

class _RoleRow extends StatelessWidget {
  const _RoleRow({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  static const _roles = [
    ('individual', 'Individual', Icons.person_outline_rounded),
    ('service_provider', 'Service Provider', Icons.work_outline_rounded),
    ('organization', 'Organization', Icons.groups_outlined),
    ('caregiver', 'Caregiver', Icons.volunteer_activism_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _roles.map((role) {
        final active = selected == role.$1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: role.$1 == 'caregiver' ? 0 : 6),
            child: InkWell(
              onTap: () => onSelected(role.$1),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFF1FBF6) : Colors.white,
                  border: Border.all(
                    color: active ? _forest : _border,
                    width: active ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      role.$3,
                      size: 16,
                      color: active ? _forest : _muted,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role.$2,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                        color: active ? _forest : _muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.onToggleObscure,
    this.compact = false,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.plusJakartaSans(
        fontSize: compact ? 12 : 13,
        color: _ink,
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: compact ? 12 : 13,
          color: const Color(0xFF9CA3AF),
        ),
        prefixIcon: Icon(icon, color: _forest, size: compact ? 17 : 18),
        suffixIcon: onToggleObscure == null
            ? null
            : IconButton(
                tooltip: obscure ? 'Show password' : 'Hide password',
                onPressed: onToggleObscure,
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF9CA3AF),
                  size: compact ? 17 : 18,
                ),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: compact ? 6 : 10,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _forest, width: 1.5),
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.controller,
    required this.countryCode,
    required this.onCodeChanged,
    this.compact = false,
  });

  final TextEditingController controller;
  final String countryCode;
  final ValueChanged<String> onCodeChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: compact ? 34 : 44,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: countryCode,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
              items: const [
                DropdownMenuItem(value: '+92', child: Text('+92')),
                DropdownMenuItem(value: '+1', child: Text('+1')),
                DropdownMenuItem(value: '+33', child: Text('+33')),
                DropdownMenuItem(value: '+44', child: Text('+44')),
              ],
              onChanged: (v) {
                if (v != null) onCodeChanged(v);
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _AuthField(
            controller: controller,
            hint: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            compact: compact,
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.dob, required this.onTap});

  final DateTime? dob;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final display = dob == null
        ? 'Select Date'
        : '${dob!.day.toString().padLeft(2, '0')}/${dob!.month.toString().padLeft(2, '0')}/${dob!.year}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: _forest),
            const SizedBox(width: 8),
            Text(
              'Date of Birth',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: _ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                display,
                textAlign: TextAlign.right,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: dob == null ? const Color(0xFF9CA3AF) : _ink,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: _muted),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
    this.compact = false,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: compact ? 36 : 44,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _forest,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: compact ? 15 : 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: _border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'or',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF9CA3AF),
              fontSize: 13,
            ),
          ),
        ),
        const Expanded(child: Divider(color: _border)),
      ],
    );
  }
}

class _SocialRow extends StatelessWidget {
  const _SocialRow({
    required this.loading,
    required this.signUp,
    required this.onGoogle,
    required this.onApple,
    required this.onFacebook,
  });

  final bool loading;
  final bool signUp;
  final VoidCallback onGoogle;
  final VoidCallback onApple;
  final VoidCallback onFacebook;

  @override
  Widget build(BuildContext context) {
    final prefix = signUp ? 'Sign up with' : 'Continue with';
    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            label: '$prefix Google',
            enabled: !loading,
            onTap: onGoogle,
            leading: Image.asset(
              'assets/images/ic_google_logo.png',
              width: 22,
              height: 22,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _SocialButton(
            label: '$prefix Apple',
            enabled: !loading,
            onTap: onApple,
            leading: Image.asset(
              'assets/images/ic_apple_logo.png',
              width: 22,
              height: 22,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _SocialButton(
            label: '$prefix Facebook',
            enabled: !loading,
            onTap: onFacebook,
            leading: Image.asset(
              'assets/images/ic_facebook_logo.png',
              width: 22,
              height: 22,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.leading,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final Widget leading;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: FittedBox(fit: BoxFit.contain, child: leading),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsRow extends StatelessWidget {
  const _TermsRow({required this.agreed, required this.onChanged});

  final bool agreed;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(
            value: agreed,
            onChanged: onChanged,
            activeColor: _forest,
            side: const BorderSide(color: _border),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'I agree to the ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: _muted,
                height: 1.25,
              ),
              children: const [
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: _forest,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: _forest,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

