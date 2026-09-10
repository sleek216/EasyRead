import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/easy_word_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/easy_toast.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int currentStep = 0; // 0: Email, 1: OTP, 2: New Password

  // Controllers
  final TextEditingController _emailCtrl = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final TextEditingController _newPassCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();

  // State
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  String? _resetToken;

  // Timers
  Timer? _resendTimer;
  int _resendCooldown = 0;
  Timer? _expiryTimer;
  int _expirySecondsLeft = 900; // 15 minutes
  Timer? _bannerDismissTimer;

  // Visibility
  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;

  void _showAutoDismissSuccess(String message) {
    _bannerDismissTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _successMessage = message;
      _errorMessage = null;
    });
    _bannerDismissTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _successMessage = null);
      }
    });
  }

  void _showAutoDismissError(String message) {
    _bannerDismissTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _successMessage = null;
    });
    _bannerDismissTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _errorMessage = null);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.trim().isNotEmpty) {
      _emailCtrl.text = widget.initialEmail!.trim();
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    _resendTimer?.cancel();
    _expiryTimer?.cancel();
    _bannerDismissTimer?.cancel();
    super.dispose();
  }

  void _startResendCooldown([int seconds = 60]) {
    _resendCooldown = seconds;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  void _startExpiryTimer([int seconds = 900]) {
    _expirySecondsLeft = seconds;
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_expirySecondsLeft > 0) {
        setState(() => _expirySecondsLeft--);
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTimer(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  // STEP 1: Send OTP
  Future<void> _handleSendOtp() async {
    final email = _emailCtrl.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (email.isEmpty) {
      _showAutoDismissError("Please enter your email address.");
      return;
    }
    if (!emailRegex.hasMatch(email)) {
      _showAutoDismissError("Please enter a valid email address.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final res = await ApiService.forgotPassword(email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() {
        currentStep = 1;
      });
      _showAutoDismissSuccess(res['message'] ?? "Verification code sent to $email");
      _startResendCooldown(res['retry_after'] is int ? res['retry_after'] : 60);
      _startExpiryTimer(900); // 15 mins
      // Auto focus on first OTP box
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _otpFocusNodes[0].requestFocus();
      });
    } else {
      _showAutoDismissError(res['message'] ?? "Failed to send reset code. Please try again.");
    }
  }

  // STEP 2: Verify OTP
  String get _currentOtp => _otpControllers.map((c) => c.text).join();

  Future<void> _handleVerifyOtp() async {
    final otp = _currentOtp;
    if (otp.length < 6) {
      _showAutoDismissError("Please enter all 6 digits of the code.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final email = _emailCtrl.text.trim();
    final res = await ApiService.verifyOtp(email, otp);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true && res['reset_token'] != null) {
      _bannerDismissTimer?.cancel();
      setState(() {
        _resetToken = res['reset_token'];
        currentStep = 2;
        _errorMessage = null;
        _successMessage = null;
      });
      _expiryTimer?.cancel();
    } else {
      _showAutoDismissError(res['message'] ?? "Invalid or expired verification code.");
      // Clear OTP digits on failure
      for (var c in _otpControllers) {
        c.clear();
      }
      _otpFocusNodes[0].requestFocus();
    }
  }

  // Resend OTP
  Future<void> _handleResendOtp() async {
    if (_resendCooldown > 0 || _isLoading) return;
    final email = _emailCtrl.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService.forgotPassword(email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      showEasyToast(context, "New code sent to your email!");
      _showAutoDismissSuccess("New verification code sent to $email");
      _startResendCooldown(res['retry_after'] is int ? res['retry_after'] : 60);
      _startExpiryTimer(900);
      for (var c in _otpControllers) {
        c.clear();
      }
      _otpFocusNodes[0].requestFocus();
    } else {
      _showAutoDismissError(res['message'] ?? "Failed to resend code.");
    }
  }

  // STEP 3: Reset Password & Auto Login
  Future<void> _handleResetPassword() async {
    final newPass = _newPassCtrl.text;
    final confirmPass = _confirmPassCtrl.text;

    if (newPass.isEmpty) {
      _showAutoDismissError("Please enter a new password.");
      return;
    }
    if (newPass.length < 6) {
      _showAutoDismissError("Password must be at least 6 characters.");
      return;
    }
    if (newPass != confirmPass) {
      _showAutoDismissError("Passwords do not match. Please check.");
      return;
    }
    if (_resetToken == null) {
      _showAutoDismissError("Reset token expired. Please start over.");
      setState(() => currentStep = 0);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final provider = context.read<EasyReadProvider>();
    final res = await provider.resetPasswordAndLogin(
      resetToken: _resetToken!,
      newPassword: newPass,
      passwordConfirmation: confirmPass,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      showEasyToast(context, "Password reset successfully! Welcome back.");
      // Pop all the way back to main home screen
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      _showAutoDismissError(res['message'] ?? "Failed to reset password. Please try again.");
    }
  }

  // Password Strength Indicator
  int _calculateStrength(String pass) {
    if (pass.isEmpty) return 0;
    int score = 0;
    if (pass.length >= 6) score++;
    if (pass.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(pass) && RegExp(r'[a-z]').hasMatch(pass)) score++;
    if (RegExp(r'[0-9]').hasMatch(pass) || RegExp(r'[^A-Za-z0-9]').hasMatch(pass)) score++;
    return score; // 0 to 4
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.ink, size: 20),
          onPressed: () {
            if (currentStep > 0) {
              setState(() {
                currentStep--;
                _errorMessage = null;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          "Reset Password",
          style: AppTypography.fraunces(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error Banner
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _errorMessage != null
                    ? Container(
                        margin: const EdgeInsets.only(bottom: 18),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE8E8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF8B4B4)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFE02424), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTypography.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF9B1C1C),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                _bannerDismissTimer?.cancel();
                                setState(() => _errorMessage = null);
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(Icons.close, size: 16, color: Color(0xFF9B1C1C)),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // Success Banner
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: (_successMessage != null && currentStep == 1)
                    ? Container(
                        margin: const EdgeInsets.only(bottom: 18),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDF7ED),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFB7EB8F)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline, color: AppColors.moss, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _successMessage!,
                                style: AppTypography.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.moss,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                _bannerDismissTimer?.cancel();
                                setState(() => _successMessage = null);
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(Icons.close, size: 16, color: AppColors.moss),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // Animated Step Content
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildCurrentStepWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildCurrentStepWidget() {
    switch (currentStep) {
      case 0:
        return _buildStep0Email();
      case 1:
        return _buildStep1Otp();
      case 2:
        return _buildStep2NewPassword();
      default:
        return _buildStep0Email();
    }
  }

  // STEP 0: Email Screen
  Widget _buildStep0Email() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Icon Badge
        Center(
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 8)),
              ],
            ),
            child: const Icon(Icons.lock_reset, color: AppColors.goldSoft, size: 34),
          ),
        ),
        const SizedBox(height: 22),

        Text(
          "Forgot Your Password?",
          textAlign: TextAlign.center,
          style: AppTypography.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Enter the email associated with your EasyRead account. We will send a 6-digit verification code to reset your password.",
          textAlign: TextAlign.center,
          style: AppTypography.inter(
            fontSize: 13,
            color: AppColors.textMute,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),

        // Email Field
        Text(
          "REGISTERED EMAIL",
          style: AppTypography.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          style: AppTypography.inter(fontSize: 13.5, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: "e.g. user@gmail.com",
            hintStyle: AppTypography.inter(fontSize: 13, color: AppColors.textMute.withValues(alpha: 0.6)),
            prefixIcon: const Icon(Icons.mail_outline, color: AppColors.textMute, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
            ),
          ),
          onSubmitted: (_) => _handleSendOtp(),
        ),
        const SizedBox(height: 24),

        // Send Button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ink,
            foregroundColor: AppColors.paper,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          onPressed: _isLoading ? null : _handleSendOtp,
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Text(
                  "Send Verification Code",
                  style: AppTypography.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.paper,
                  ),
                ),
        ),
        const SizedBox(height: 20),

        // Security Note
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.paperSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.moss, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "For your security, verification codes expire after 15 minutes. Check your spam or junk folder if you don't receive it in 1 minute.",
                  style: AppTypography.inter(
                    fontSize: 11.5,
                    color: AppColors.textMute,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 1: OTP Code Verification Screen
  Widget _buildStep1Otp() {
    final email = _emailCtrl.text.trim();

    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.moss,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 8)),
              ],
            ),
            child: const Icon(Icons.mark_email_read_outlined, color: AppColors.paper, size: 34),
          ),
        ),
        const SizedBox(height: 22),

        Text(
          "Enter 6-Digit Code",
          textAlign: TextAlign.center,
          style: AppTypography.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),

        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTypography.inter(fontSize: 13, color: AppColors.textMute, height: 1.5),
            children: [
              const TextSpan(text: "We have sent a verification code to\n"),
              TextSpan(
                text: email,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 6-digit OTP Box Inputs
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) => _buildOtpBox(index)),
        ),
        const SizedBox(height: 18),

        // Expiration Countdown
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 15,
                color: _expirySecondsLeft < 120 ? Colors.red : AppColors.textMute,
              ),
              const SizedBox(width: 5),
              Text(
                _expirySecondsLeft > 0
                    ? "Code expires in ${_formatTimer(_expirySecondsLeft)}"
                    : "Code expired. Please request a new one.",
                style: AppTypography.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _expirySecondsLeft < 120 ? Colors.red : AppColors.textMute,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Verify Button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ink,
            foregroundColor: AppColors.paper,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          onPressed: _isLoading ? null : _handleVerifyOtp,
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Text(
                  "Verify Code",
                  style: AppTypography.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.paper,
                  ),
                ),
        ),
        const SizedBox(height: 16),

        // Resend Button
        Center(
          child: TextButton(
            onPressed: (_resendCooldown > 0 || _isLoading) ? null : _handleResendOtp,
            child: Text(
              _resendCooldown > 0
                  ? "Resend code in ${_resendCooldown}s"
                  : "Didn't receive code? Resend",
              style: AppTypography.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _resendCooldown > 0 ? AppColors.textMute : AppColors.moss,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 44,
      height: 54,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
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
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (val) {
          if (val.isNotEmpty) {
            if (index < 5) {
              _otpFocusNodes[index + 1].requestFocus();
            } else {
              _otpFocusNodes[index].unfocus();
              // All 6 digits filled -> Auto trigger verification!
              if (_currentOtp.length == 6) {
                _handleVerifyOtp();
              }
            }
          } else {
            if (index > 0) {
              _otpFocusNodes[index - 1].requestFocus();
            }
          }
        },
      ),
    );
  }

  // STEP 2: New Password Screen
  Widget _buildStep2NewPassword() {
    final strength = _calculateStrength(_newPassCtrl.text);

    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 8)),
              ],
            ),
            child: const Icon(Icons.vpn_key_outlined, color: AppColors.goldSoft, size: 34),
          ),
        ),
        const SizedBox(height: 22),

        Text(
          "Create New Password",
          textAlign: TextAlign.center,
          style: AppTypography.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Your identity has been verified. Enter your new password below to secure your EasyRead account.",
          textAlign: TextAlign.center,
          style: AppTypography.inter(
            fontSize: 13,
            color: AppColors.textMute,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),

        // New Password Field
        Text(
          "NEW PASSWORD",
          style: AppTypography.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: _newPassCtrl,
          obscureText: _obscureNewPass,
          autofocus: true,
          style: AppTypography.inter(fontSize: 13.5, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: "Enter new password (min 6 characters)",
            hintStyle: AppTypography.inter(fontSize: 13, color: AppColors.textMute.withValues(alpha: 0.6)),
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMute, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNewPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textMute,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),

        // Password Strength Indicator Bar
        if (_newPassCtrl.text.isNotEmpty) ...[
          Row(
            children: List.generate(4, (index) {
              final isFilled = index < strength;
              Color barColor = Colors.grey.shade300;
              if (isFilled) {
                if (strength == 1) {
                  barColor = Colors.red;
                } else if (strength == 2) {
                  barColor = Colors.orange;
                } else if (strength == 3) {
                  barColor = Colors.blue;
                } else {
                  barColor = AppColors.moss;
                }
              }
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              strength == 1
                  ? "Weak password"
                  : (strength == 2
                      ? "Fair password"
                      : (strength == 3 ? "Good password" : "Strong password")),
              style: AppTypography.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: strength == 1
                    ? Colors.red
                    : (strength == 2
                        ? Colors.orange
                        : (strength == 3 ? Colors.blue : AppColors.moss)),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ] else
          const SizedBox(height: 16),

        // Confirm Password Field
        Text(
          "CONFIRM NEW PASSWORD",
          style: AppTypography.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: _confirmPassCtrl,
          obscureText: _obscureConfirmPass,
          style: AppTypography.inter(fontSize: 13.5, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: "Re-enter your new password",
            hintStyle: AppTypography.inter(fontSize: 13, color: AppColors.textMute.withValues(alpha: 0.6)),
            prefixIcon: const Icon(Icons.lock_reset, color: AppColors.textMute, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textMute,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
            ),
          ),
          onSubmitted: (_) => _handleResetPassword(),
        ),
        const SizedBox(height: 28),

        // Submit Button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ink,
            foregroundColor: AppColors.paper,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          onPressed: _isLoading ? null : _handleResetPassword,
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Text(
                  "Reset Password & Log In",
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
}
