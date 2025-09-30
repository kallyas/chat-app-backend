import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/validators.dart';
import '../../utils/constants.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.requestPasswordReset(
      email: _emailController.text.trim(),
    );

    if (success) {
      setState(() {
        _emailSent = true;
      });
    } else {
      // Show error message
      if (mounted && authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleResendEmail() {
    setState(() {
      _emailSent = false;
    });
    _handleSendResetEmail();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Consumer2<AuthProvider, ThemeProvider>(
          builder: (context, authProvider, themeProvider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.largePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  
                  // Icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppConstants.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Icon(
                        _emailSent ? Icons.mark_email_read_outlined : Icons.lock_reset,
                        size: 40,
                        color: AppConstants.primaryBlue,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AppConstants.largePadding),
                  
                  // Title and subtitle
                  Center(
                    child: Column(
                      children: [
                        Text(
                          _emailSent ? 'Check Your Email' : 'Reset Password',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppConstants.smallPadding),
                        Text(
                          _emailSent
                              ? 'We\'ve sent password reset instructions to ${_emailController.text}'
                              : 'Enter your email address and we\'ll send you instructions to reset your password',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: themeProvider.secondaryTextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  if (!_emailSent) ...[
                    // Email form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            validator: Validators.validateEmail,
                            onFieldSubmitted: (_) => _handleSendResetEmail(),
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter your email address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          
                          const SizedBox(height: AppConstants.largePadding),
                          
                          // Send button
                          ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _handleSendResetEmail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                              ),
                            ),
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Send Reset Instructions',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Email sent success view
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppConstants.defaultPadding),
                          decoration: BoxDecoration(
                            color: AppConstants.accentGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                            border: Border.all(
                              color: AppConstants.accentGreen.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: AppConstants.accentGreen,
                                size: 24,
                              ),
                              const SizedBox(width: AppConstants.defaultPadding),
                              Expanded(
                                child: Text(
                                  'Reset instructions sent successfully!',
                                  style: TextStyle(
                                    color: AppConstants.accentGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: AppConstants.largePadding),
                        
                        // Instructions
                        Container(
                          padding: const EdgeInsets.all(AppConstants.defaultPadding),
                          decoration: BoxDecoration(
                            color: themeProvider.surfaceVariantColor,
                            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Next Steps:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: themeProvider.primaryTextColor,
                                ),
                              ),
                              const SizedBox(height: AppConstants.smallPadding),
                              _buildInstructionStep(
                                '1.',
                                'Check your email inbox',
                                themeProvider,
                              ),
                              _buildInstructionStep(
                                '2.',
                                'Click the reset link in the email',
                                themeProvider,
                              ),
                              _buildInstructionStep(
                                '3.',
                                'Follow the instructions to create a new password',
                                themeProvider,
                              ),
                              const SizedBox(height: AppConstants.smallPadding),
                              Text(
                                'The reset link will expire in 1 hour for security reasons.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: themeProvider.secondaryTextColor,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: AppConstants.largePadding),
                        
                        // Resend button
                        OutlinedButton(
                          onPressed: authProvider.isLoading ? null : _handleResendEmail,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                            ),
                            side: const BorderSide(color: AppConstants.primaryBlue),
                          ),
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryBlue),
                                  ),
                                )
                              : const Text(
                                  'Resend Email',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: AppConstants.largePadding),
                  
                  // Back to login button
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text.rich(
                        TextSpan(
                          text: 'Remember your password? ',
                          style: TextStyle(
                            color: themeProvider.secondaryTextColor,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Back to Sign In',
                              style: TextStyle(
                                color: AppConstants.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Help text
                  if (!_emailSent)
                    Container(
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      decoration: BoxDecoration(
                        color: themeProvider.surfaceVariantColor,
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: themeProvider.secondaryTextColor,
                              ),
                              const SizedBox(width: AppConstants.smallPadding),
                              Text(
                                'Need Help?',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: themeProvider.primaryTextColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.smallPadding),
                          Text(
                            'If you don\'t receive the email within a few minutes, please check your spam folder or contact support.',
                            style: TextStyle(
                              fontSize: 14,
                              color: themeProvider.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: themeProvider.primaryTextColor,
            ),
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: themeProvider.primaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}