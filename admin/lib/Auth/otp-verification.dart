import 'dart:convert';
import 'package:admin/Auth/reset_password.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class OTPVerification extends StatefulWidget {
  final String email;

  const OTPVerification({super.key, required this.email, String? phone});

  @override
  State<OTPVerification> createState() => _OTPVerificationState();
}

class _OTPVerificationState extends State<OTPVerification> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  bool _isOtpFilled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendOTP();
    });
    for (var controller in _otpControllers) {
      controller.addListener(_updateOtpFilledStatus);
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.removeListener(_updateOtpFilledStatus);
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _updateOtpFilledStatus() {
    setState(() {
      _isOtpFilled = _otpControllers.every(
        (controller) => controller.text.isNotEmpty,
      );
    });
  }

  Future<void> _sendOTP() async {
    setState(() {
      _isResending = true;
    });

    final url = Uri.parse('http://192.168.20.16:8000/api/send-otp/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send OTP: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _onOTPChanged(String value, int index) {
    SystemSound.play(SystemSoundType.click);

    if (value.isNotEmpty) {
      if (index < _focusNodes.length - 1) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        FocusScope.of(context).unfocus();
      }
    } else if (index > 0) {
      _otpControllers[index - 1].clear();
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
  }

  bool _handleKeyEvent(RawKeyEvent event, int index) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_otpControllers[index].text.isEmpty && index > 0) {
        _otpControllers[index - 1].clear();
        FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
      }
      return true;
    }
    return false;
  }

  String _getOTPCode() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyOTP() async {
    String otpCode = _getOTPCode();

    if (otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a complete 6-digit OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('http://192.168.20.16:8000/api/verify-otp/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email, 'otp': otpCode}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPassword(email: widget.email),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid OTP: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true, // Ensure content resizes for keyboard
      backgroundColor: Colors.white,
      body: SafeArea(
        // Wrap in SafeArea to respect system insets
        child: Stack(
          children: [
            SingleChildScrollView(
              // Make content scrollable
              padding: EdgeInsets.all(screenWidth * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: screenHeight * 0.18,
                  ), // Reduced to save space
                  Text(
                    'Check your email',
                    style: TextStyle(
                      fontSize: screenWidth * 0.07,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF030047),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: screenWidth * 0.038,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(text: 'We sent a reset link to '),
                        TextSpan(
                          text: widget.email,
                          style: const TextStyle(
                            color: Color(0xFF030047),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(
                          text:
                              '\nEnter the 6-digit code mentioned in the email',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: screenWidth * 0.12,
                        height: screenHeight * 0.08,
                        child: RawKeyboardListener(
                          focusNode: FocusNode(),
                          onKey: (event) => _handleKeyEvent(event, index),
                          child: TextField(
                            controller: _otpControllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: TextStyle(
                              fontSize: screenWidth * 0.06,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF030047),
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  screenWidth * 0.03,
                                ),
                                borderSide: const BorderSide(
                                  color: Colors.grey,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  screenWidth * 0.03,
                                ),
                                borderSide: const BorderSide(
                                  color: Color(0xFF030047),
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (value) => _onOTPChanged(value, index),
                          ),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: screenHeight * 0.05),
                  SizedBox(
                    width: double.infinity,
                    height: screenHeight * 0.07,
                    child: ElevatedButton(
                      onPressed: _isLoading || !_isOtpFilled
                          ? null
                          : _verifyOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isOtpFilled
                            ? const Color(0xFF030047)
                            : const Color(0xFFE8E8E8),
                        foregroundColor: _isOtpFilled
                            ? const Color(0xFFE8E8E8)
                            : const Color(0xFF030047),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.03,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: screenHeight * 0.025,
                              width: screenHeight * 0.025,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFE8E8E8),
                                ),
                              ),
                            )
                          : Text(
                              'Verify Code',
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Haven't got the email yet? ",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: screenWidth * 0.04,
                          ),
                        ),
                        TextButton(
                          onPressed: _isResending ? null : _sendOTP,
                          child: _isResending
                              ? SizedBox(
                                  height: screenHeight * 0.02,
                                  width: screenHeight * 0.02,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFFFFCC3E),
                                    ),
                                  ),
                                )
                              : Text(
                                  'Resend email',
                                  style: TextStyle(
                                    color: const Color(0xFFFFCC3E),
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).viewInsets.bottom,
                  ), // Dynamic padding for keyboard
                ],
              ),
            ),
            Positioned(
              top: screenHeight * 0.12,
              left: screenWidth * 0.07,
              child: Container(
                width: screenWidth * 0.12,
                height: screenWidth * 0.12,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFCC3E),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.center,
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: const Color(0xFF030047),
                    size: screenWidth * 0.05,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
