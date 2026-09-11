import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/easy_word_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/easy_toast.dart';
import '../auth/forgot_password_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 0;
  String authMode = 'login';
  bool obscurePassword = true;
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final List<TextEditingController> otpCtrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> otpNodes = List.generate(6, (_) => FocusNode());

  // Inline validation error messages
  String? nameError;
  String? emailError;
  String? passwordError;

  final List<String> prefOptions = [
    "Fiction",
    "Research",
    "Business",
    "Self-development",
    "News",
    "Education"
  ];
  final Set<String> selectedPrefs = {};

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 6; i++) {
      otpNodes[i].onKeyEvent = (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
          if (otpCtrls[i].text.isEmpty && i > 0) {
            otpNodes[i - 1].requestFocus();
            otpCtrls[i - 1].clear();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      };
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    for (var c in otpCtrls) {
      c.dispose();
    }
    for (var f in otpNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: _buildCurrentStep(context),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context) {
    switch (step) {
      case 0:
        return _buildStep0Splash(context);
      case 1:
        return _buildStep1FeatureDictionary(context);
      case 2:
        return _buildStep2FeatureLibrary(context);
      case 3:
        return _buildStep3Auth(context);
      case 4:
        return _buildStep4Preferences(context);
      default:
        return _buildStep0Splash(context);
    }
  }

  // Step 0: Splash & Welcome
  Widget _buildStep0Splash(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x6616241D),
                blurRadius: 30,
                offset: Offset(0, 14),
              )
            ],
          ),
          child: const Center(
            child: Icon(Icons.auto_stories, color: AppColors.goldSoft, size: 36),
          ),
        ),
        const SizedBox(height: 20),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "Easy",
                style: AppTypography.fraunces(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              TextSpan(
                text: "Read",
                style: AppTypography.fraunces(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Your personal reading & learning companion books, articles, and documents, all in one place.",
          textAlign: TextAlign.center,
          style: AppTypography.inter(
            fontSize: 13,
            color: AppColors.textMute,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 36),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ink,
            foregroundColor: AppColors.paper,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          onPressed: () => setState(() => step = 1),
          child: Text(
            "Get started",
            style: AppTypography.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.paper,
            ),
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () {
            setState(() {
              authMode = 'login';
              step = 3;
            });
          },
          child: Text(
            "I already have an account",
            style: AppTypography.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMute,
            ),
          ),
        ),
      ],
    );
  }

  // Step 1: Feature - Dictionary
  Widget _buildStep1FeatureDictionary(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 180,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.paperSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "definition ↝",
                  style: AppTypography.fraunces(
                    fontSize: 12,
                    color: AppColors.paper,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 130,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          "Tap any word, instantly\nunderstand it",
          textAlign: TextAlign.center,
          style: AppTypography.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Definitions, pronunciation, and examples appear right where you're reading you never leave the page.",
          textAlign: TextAlign.center,
          style: AppTypography.inter(
            fontSize: 12.5,
            color: AppColors.textMute,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        _buildDots(0),
        const SizedBox(height: 28),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ink,
            foregroundColor: AppColors.paper,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          onPressed: () => setState(() => step = 2),
          child: Text(
            "Next",
            style: AppTypography.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.paper,
            ),
          ),
        ),
      ],
    );
  }

  // Step 2: Feature - Library + AI
  Widget _buildStep2FeatureLibrary(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildMiniBook(AppColors.plum, 80),
            const SizedBox(width: 8),
            _buildMiniBook(AppColors.moss, 92),
            const SizedBox(width: 8),
            _buildMiniBook(AppColors.blueTheme, 76),
            const SizedBox(width: 8),
            _buildMiniBook(AppColors.gold, 86),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          "One place for\neverything you read",
          textAlign: TextAlign.center,
          style: AppTypography.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Books, PDFs, articles, and pasted text plus an AI companion to simplify anything you don't understand.",
          textAlign: TextAlign.center,
          style: AppTypography.inter(
            fontSize: 12.5,
            color: AppColors.textMute,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        _buildDots(1),
        const SizedBox(height: 28),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ink,
            foregroundColor: AppColors.paper,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          onPressed: () => setState(() => step = 3),
          child: Text(
            "Next",
            style: AppTypography.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.paper,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniBook(Color color, double height) {
    return Container(
      width: 32,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))
        ],
      ),
    );
  }

  Widget _buildDots(int activeIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: activeIndex == 0 ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: activeIndex == 0 ? AppColors.gold : AppColors.line,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: activeIndex == 1 ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: activeIndex == 1 ? AppColors.gold : AppColors.line,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }

  // Form Validation with Inline Errors
  bool _validateInputs(bool isSignup) {
    setState(() {
      nameError = null;
      emailError = null;
      passwordError = null;
    });

    if (isSignup) {
      final name = nameCtrl.text.trim();
      if (name.isEmpty) {
        showEasyToast(context, "Full name is required");
        return false;
      } else if (name.length < 2) {
        showEasyToast(context, "Name must be at least 2 characters");
        return false;
      }
    }

    final email = emailCtrl.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email.isEmpty) {
      showEasyToast(context, "Email address is required");
      return false;
    } else if (!emailRegex.hasMatch(email)) {
      showEasyToast(context, "Please enter a valid email (e.g. name@domain.com)");
      return false;
    }

    final pass = passCtrl.text;
    if (pass.isEmpty) {
      showEasyToast(context, "Password is required");
      return false;
    } else if (pass.length < 6) {
      showEasyToast(context, "Password must be at least 6 characters");
      return false;
    }

    return true;
  }

  Future<void> _handleVerifySignupOtp(BuildContext ctx) async {
    final otp = otpCtrls.map((c) => c.text).join();
    if (otp.length < 6) {
      showEasyToast(context, "Please enter all 6 digits.");
      return;
    }

    final provider = ctx.read<EasyReadProvider>();
    final res = await provider.register(nameCtrl.text.trim(), emailCtrl.text.trim(), passCtrl.text, otp);
    
    if (!mounted) return;
    
    if (res['success'] == true) {
      showEasyToast(context, "Account created successfully! Welcome.");
      if (provider.pendingSharedFilePath != null && provider.pendingSharedFilePath!.isNotEmpty) {
        provider.finishOnboarding();
      } else {
        setState(() => step = 4);
      }
    } else {
      final msg = res['message']?.toString() ?? "Verification failed.";
      showEasyToast(context, msg);
      if (res['field'] == 'otp') {
        for (var c in otpCtrls) c.clear();
        otpNodes[0].requestFocus();
      }
    }
  }

  // Handle Login & Signup API calls
  Future<void> _handleAuthSubmit(BuildContext ctx, bool isSignup) async {
    if (!_validateInputs(isSignup)) return;

    final provider = ctx.read<EasyReadProvider>();
    if (isSignup) {
      final res = await provider.sendSignupOtp(nameCtrl.text.trim(), emailCtrl.text.trim(), passCtrl.text);
      if (!mounted) return;
      if (res['success'] == true) {
        showEasyToast(context, res['message'] ?? "Verification code sent.");
        setState(() {
          authMode = 'signup_otp';
        });
        // Auto focus first OTP field
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) otpNodes[0].requestFocus();
        });
      } else {
        final msg = res['message']?.toString() ?? "Failed to send code. Try again.";
        showEasyToast(context, msg);
      }
    } else {
      final res = await provider.login(emailCtrl.text.trim(), passCtrl.text);
      if (!mounted) return;
      if (res['success'] == true) {
        showEasyToast(context, "Welcome back, ${provider.currentUserName}!");
        provider.finishOnboarding();
      } else {
        final field = res['field']?.toString().toLowerCase();
        final msg = res['message']?.toString() ?? "Invalid credentials.";
        final errors = res['errors'] as Map<String, dynamic>?;
        final emailErrMsg = errors?['email'] is List && (errors!['email'] as List).isNotEmpty
            ? errors['email'][0].toString()
            : null;
        final passErrMsg = errors?['password'] is List && (errors!['password'] as List).isNotEmpty
            ? errors['password'][0].toString()
            : null;

        // If account was suspended or deleted, show the 5-second popup banner
        if (msg.toLowerCase().contains("suspended") || res['account_deleted'] == true || msg.toLowerCase().contains("deleted")) {
          final notice = msg.toLowerCase().contains("suspended")
              ? "Your account has been suspended by EasyRead."
              : "Your account has been deleted by EasyRead.";
          provider.showDeactivationNotice(notice);
          return;
        }

        showEasyToast(context, passErrMsg ?? emailErrMsg ?? msg);
      }
    }
  }

  // Handle Google Sign-In
  Future<void> _handleGoogleSignIn(BuildContext ctx) async {
    final provider = ctx.read<EasyReadProvider>();
    final res = await provider.signInWithGoogle();
    if (!mounted) return;
    if (res['success'] == true) {
      showEasyToast(context, "Welcome, ${provider.currentUserName}!");
      provider.finishOnboarding();
    } else {
      final msg = res['message']?.toString() ?? "Google Sign-In failed.";
      if (!msg.toLowerCase().contains("cancelled")) {
        showEasyToast(context, msg);
      }
    }
  }

  // Handle Apple Sign-In
  Future<void> _handleAppleSignIn(BuildContext ctx) async {
    final provider = ctx.read<EasyReadProvider>();
    final res = await provider.signInWithApple();
    if (!mounted) return;
    if (res['success'] == true) {
      showEasyToast(context, "Welcome, ${provider.currentUserName}!");
      provider.finishOnboarding();
    } else {
      final msg = res['message']?.toString() ?? "Apple Sign-In failed.";
      showEasyToast(context, msg);
    }
  }

  // Step 3: Auth Screen
  Widget _buildStep3Auth(BuildContext context) {
    if (authMode == 'signup_otp') {
      return _buildSignupOtp(context);
    }

    final provider = context.watch<EasyReadProvider>();
    final isSignup = authMode == 'signup';
    final isLoading = provider.isAuthLoading;
    final hasPendingDoc = provider.pendingSharedFilePath != null && provider.pendingSharedFilePath!.isNotEmpty;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Notice banner removed as requested
            if (hasPendingDoc) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.moss.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.moss.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description_outlined, color: AppColors.moss, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Log in or sign up to read your document",
                        style: AppTypography.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.moss),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Mode Switcher Tabs
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.paperSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: isLoading
                          ? null
                          : () => setState(() {
                                authMode = 'signup';
                                nameError = null;
                                emailError = null;
                                passwordError = null;
                              }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: isSignup ? AppColors.ink : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isSignup ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))] : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Create Account",
                          style: AppTypography.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isSignup ? Colors.white : AppColors.textMute,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: isLoading
                          ? null
                          : () => setState(() {
                                authMode = 'login';
                                nameError = null;
                                emailError = null;
                                passwordError = null;
                              }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: !isSignup ? AppColors.ink : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: !isSignup ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))] : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Log In",
                          style: AppTypography.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: !isSignup ? Colors.white : AppColors.textMute,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              isSignup ? "Create your reader account" : "Welcome back, Reader",
              style: AppTypography.fraunces(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isSignup ? "Sign up to sync your reading library & AI summaries across devices." : "Enter your credentials to access your saved books and vocabulary.",
              style: AppTypography.inter(
                fontSize: 12,
                color: AppColors.textMute,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Form Fields with CLEAR LABELS & INLINE ERROR STATES
            if (isSignup) ...[
              _buildLabeledField(
                label: "FULL NAME",
                controller: nameCtrl,
                hint: "e.g. Elena Rostova",
                icon: Icons.person_outline,
                keyboardType: TextInputType.name,
                errorText: nameError,
                onChanged: (val) {
                  if (nameError != null) setState(() => nameError = null);
                },
              ),
              const SizedBox(height: 14),
            ],

            _buildLabeledField(
              label: "EMAIL ADDRESS",
              controller: emailCtrl,
              hint: "e.g. user@gmail.com",
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              errorText: emailError,
              onChanged: (val) {
                if (emailError != null) setState(() => emailError = null);
              },
            ),
            const SizedBox(height: 14),

            _buildLabeledField(
              label: "PASSWORD",
              controller: passCtrl,
              hint: isSignup ? "Create a password (min 6 chars)" : "Enter your account password",
              icon: Icons.lock_outline,
              isPassword: true,
              obscureText: obscurePassword,
              errorText: passwordError,
              onToggleVisibility: () => setState(() => obscurePassword = !obscurePassword),
              onChanged: (val) {
                if (passwordError != null) setState(() => passwordError = null);
              },
            ),
            if (!isSignup) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ForgotPasswordScreen(
                          initialEmail: emailCtrl.text.trim(),
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    "Forgot password?",
                    style: AppTypography.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.moss,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),

            // Submit Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: AppColors.paper,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: isLoading ? null : () => _handleAuthSubmit(context, isSignup),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      isSignup ? "Create Account & Continue" : "Log In to EasyRead",
                      style: AppTypography.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.paper,
                      ),
                    ),
            ),
            const SizedBox(height: 20),

            if (provider.isGoogleAuthEnabled || (provider.isAppleAuthEnabled && Platform.isIOS)) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.line)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "or continue with",
                      style: AppTypography.inter(fontSize: 11, color: AppColors.textMute),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.line)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (provider.isGoogleAuthEnabled)
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.line),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        onPressed: isLoading ? null : () => _handleGoogleSignIn(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF4285F4), width: 1.5),
                              ),
                              child: const Center(
                                child: Text(
                                  "G",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF4285F4),
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Google",
                              style: AppTypography.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (provider.isGoogleAuthEnabled && provider.isAppleAuthEnabled && Platform.isIOS)
                    const SizedBox(width: 10),
                  if (provider.isAppleAuthEnabled && Platform.isIOS)
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.line),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        onPressed: isLoading ? null : () => _handleAppleSignIn(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.apple, color: Colors.black, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              "Apple",
                              style: AppTypography.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Labeled Input Field with clear header, inline error, and clean focus style
  Widget _buildLabeledField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool obscureText = false,
    String? errorText,
    VoidCallback? onToggleVisibility,
    ValueChanged<String>? onChanged,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Row(
            children: [
              Text(
                label,
                style: AppTypography.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: hasError ? const Color(0xFFA13B3B) : AppColors.textDark,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                "*",
                style: TextStyle(
                  color: hasError ? const Color(0xFFA13B3B) : const Color(0xFFA13B3B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? const Color(0xFFA13B3B) : AppColors.line,
              width: hasError ? 1.5 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: hasError ? const Color(0x1AA13B3B) : const Color(0x08000000),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            onChanged: onChanged,
            style: AppTypography.inter(fontSize: 13.5, color: AppColors.textDark, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                size: 19,
                color: hasError ? const Color(0xFFA13B3B) : AppColors.moss,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 19,
                        color: hasError ? const Color(0xFFA13B3B) : AppColors.textMute,
                      ),
                      onPressed: onToggleVisibility,
                    )
                  : (hasError
                      ? const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(Icons.info_outline, size: 18, color: Color(0xFFA13B3B)),
                        )
                      : null),
              hintText: hint,
              hintStyle: AppTypography.inter(fontSize: 12.5, color: const Color(0xFF9E9E9E)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 4),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 13, color: Color(0xFFA13B3B)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    errorText,
                    style: AppTypography.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFA13B3B),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Step 4: Preferences
  Widget _buildStep4Preferences(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "What do you like to read?",
          textAlign: TextAlign.center,
          style: AppTypography.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "We'll use this to tailor your library — change it any time.",
          textAlign: TextAlign.center,
          style: AppTypography.inter(
            fontSize: 12.5,
            color: AppColors.textMute,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: prefOptions.map((opt) {
            final active = selectedPrefs.contains(opt);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (active) {
                    selectedPrefs.remove(opt);
                  } else {
                    selectedPrefs.add(opt);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: active ? AppColors.moss : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: active ? AppColors.moss : AppColors.line),
                ),
                child: Text(
                  opt,
                  style: AppTypography.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : AppColors.textDark,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 36),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ink,
            foregroundColor: AppColors.paper,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          onPressed: () {
            if (selectedPrefs.isNotEmpty) {
              showEasyToast(context, "Library tailored to your interests");
            }
            context.read<EasyReadProvider>().finishOnboarding();
          },
          child: Text(
            "Start reading",
            style: AppTypography.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.paper,
            ),
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => context.read<EasyReadProvider>().finishOnboarding(),
          child: Text(
            "Skip for now",
            style: AppTypography.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMute,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupOtp(BuildContext context) {
    final provider = context.watch<EasyReadProvider>();
    final isLoading = provider.isAuthLoading;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: () => setState(() => authMode = 'signup'),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.paperSoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.line),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textDark),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Verify your email",
              style: AppTypography.fraunces(fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            Text(
              "We sent a 6-digit verification code to\n${emailCtrl.text.trim()}",
              style: AppTypography.inter(fontSize: 14, color: AppColors.textMute, height: 1.5),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 44,
                  height: 54,
                  child: TextField(
                    controller: otpCtrls[index],
                    focusNode: otpNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.line, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.line, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.moss, width: 2),
                      ),
                    ),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (val) {
                      if (val.length > 1) {
                        // Handle paste
                        for (int i = 0; i < val.length && (index + i) < 6; i++) {
                          otpCtrls[index + i].text = val[i];
                        }
                        int nextFocus = index + val.length;
                        if (nextFocus < 6) {
                          otpNodes[nextFocus].requestFocus();
                        } else {
                          otpNodes[5].unfocus();
                          String otpStr = otpCtrls.map((c) => c.text).join('');
                          if (otpStr.length == 6) {
                            _handleVerifySignupOtp(context);
                          }
                        }
                      } else if (val.isNotEmpty) {
                        if (index < 5) {
                          otpNodes[index + 1].requestFocus();
                        } else {
                          otpNodes[index].unfocus();
                          String otpStr = otpCtrls.map((c) => c.text).join('');
                          if (otpStr.length == 6) {
                            _handleVerifySignupOtp(context);
                          }
                        }
                      } else {
                        if (index > 0) {
                          otpNodes[index - 1].requestFocus();
                        }
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: AppColors.paper,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: isLoading ? null : () => _handleVerifySignupOtp(context),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      "Verify & Create Account",
                      style: AppTypography.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.paper,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
