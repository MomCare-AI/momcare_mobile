import 'package:flutter/material.dart';

import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/glass_surface.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_gradients.dart';

/// Which tab the sliding toggle starts on.
enum AuthTab { login, register }

String? _validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Email is required';
  }
  final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!emailPattern.hasMatch(value.trim())) {
    return 'Enter a valid email address';
  }
  return null;
}

String? _validatePassword(String? value, {int minLength = 1}) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }
  if (value.length < minLength) {
    return 'Password must be at least $minLength characters';
  }
  return null;
}

void _showNotConnected(BuildContext context, String title, String message) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// One screen, two tabs — Login and Register — switched by a pill-shaped
/// toggle whose indicator slides between them, backed by a real PageView so
/// swiping left/right works too, not just tapping the toggle. Real forms,
/// real client-side validation; submitting shows an honest "not connected
/// yet" message rather than faking success, same as the rest of this app's
/// placeholders — there is no patient sign-up/sign-in endpoint on the
/// backend yet (the only existing RegisterView creates a hospital-admin +
/// organization, not a patient).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.initialTab = AuthTab.login});

  final AuthTab initialTab;

  static const loginPath = '/signin';
  static const registerPath = '/signup';

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialTab == AuthTab.login ? 0 : 1;
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToTab(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  children: [
                    GlassSurface(
                      borderRadius: 40,
                      padding: const EdgeInsets.all(16),
                      child: Image.asset(
                        'assets/images/momcare_icon.png',
                        width: 48,
                        height: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _index == 0 ? 'Welcome back' : 'Create your account',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Choose an option below to continue',
                      style: TextStyle(color: AppColors.body),
                    ),
                    const SizedBox(height: 24),
                    _AuthToggle(
                      pageController: _pageController,
                      currentIndex: _index,
                      onSelect: _goToTab,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _index = i),
                  children: const [_LoginForm(), _RegisterForm()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthToggle extends StatelessWidget {
  const _AuthToggle({
    required this.pageController,
    required this.currentIndex,
    required this.onSelect,
  });

  final PageController pageController;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  double _page() {
    if (pageController.hasClients && pageController.page != null) {
      return pageController.page!;
    }
    return currentIndex.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 26,
      opacity: 0.5,
      padding: const EdgeInsets.all(4),
      child: SizedBox(
        height: 44,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final segmentWidth = constraints.maxWidth / 2;
            return AnimatedBuilder(
              animation: pageController,
              builder: (context, _) {
                final page = _page().clamp(0.0, 1.0);
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 80),
                      curve: Curves.linear,
                      left: page * segmentWidth,
                      top: 0,
                      bottom: 0,
                      width: segmentWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppGradients.primaryButton,
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        _ToggleLabel(
                          label: 'Login',
                          width: segmentWidth,
                          active: currentIndex == 0,
                          onTap: () => onSelect(0),
                        ),
                        _ToggleLabel(
                          label: 'Register',
                          width: segmentWidth,
                          active: currentIndex == 1,
                          onTap: () => onSelect(1),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ToggleLabel extends StatelessWidget {
  const _ToggleLabel({
    required this.label,
    required this.width,
    required this.active,
    required this.onTap,
  });

  final String label;
  final double width;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : AppColors.body,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _showNotConnected(
      context,
      'Sign-in isn’t connected yet',
      'This form works, but patient sign-in isn’t wired up to the '
          'backend yet. Nothing was sent.',
    );
  }

  void _forgotPassword() {
    _showNotConnected(
      context,
      'Password reset isn’t connected yet',
      'This will send a reset link once the backend supports it. Nothing '
          'was sent.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 24),
      child: GlassSurface(
        borderRadius: 28,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) => _validatePassword(value),
              ),
              Row(
                children: [
                  Transform.scale(
                    scale: 0.85,
                    child: Checkbox(
                      value: _rememberMe,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      onChanged: (value) =>
                          setState(() => _rememberMe = value ?? false),
                    ),
                  ),
                  const Flexible(
                    child: Text(
                      'Remember me',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(color: AppColors.body, fontSize: 13),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _forgotPassword,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Forgot password?', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: GlassButton(label: 'Login', onPressed: _submit),
              ),
              const SizedBox(height: 24),
              const _SocialDivider(),
              const SizedBox(height: 16),
              const _SocialButtonsRow(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisterForm extends StatefulWidget {
  const _RegisterForm();

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _showNotConnected(
      context,
      'Sign-up isn’t connected yet',
      'This form works, but account creation isn’t wired up to the '
          'backend yet — that endpoint doesn’t exist. Nothing was sent.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 24),
      child: GlassSurface(
        borderRadius: 28,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'First name'),
                      validator: (value) =>
                          _requiredValidator(value, 'First name'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Last name'),
                      validator: (value) =>
                          _requiredValidator(value, 'Last name'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) => _validatePassword(value, minLength: 8),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: GlassButton(label: 'Register', onPressed: _submit),
              ),
              const SizedBox(height: 24),
              const _SocialDivider(),
              const SizedBox(height: 16),
              const _SocialButtonsRow(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialDivider extends StatelessWidget {
  const _SocialDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.borderSoft)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('Or continue with', style: TextStyle(color: AppColors.faint)),
        ),
        Expanded(child: Divider(color: AppColors.borderSoft)),
      ],
    );
  }
}

/// Visual only — real Google/Facebook sign-in is out of scope for this
/// phase (no OAuth wiring, per the same "no fake backend responses" rule
/// as the forms above). Tapping says so instead of doing nothing.
class _SocialButtonsRow extends StatelessWidget {
  const _SocialButtonsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            label: 'Google',
            icon: Icons.g_mobiledata_rounded,
            onTap: () => _showNotConnected(
              context,
              'Google sign-in isn’t connected yet',
              'Social sign-in isn’t wired up to the backend yet.',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SocialButton(
            label: 'Facebook',
            icon: Icons.facebook_rounded,
            onTap: () => _showNotConnected(
              context,
              'Facebook sign-in isn’t connected yet',
              'Social sign-in isn’t wired up to the backend yet.',
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
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      label: label,
      icon: icon,
      variant: GlassButtonVariant.outlined,
      onPressed: onTap,
    );
  }
}
