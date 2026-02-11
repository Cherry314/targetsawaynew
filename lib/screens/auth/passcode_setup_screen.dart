// lib/screens/auth/passcode_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../services/auth_service.dart';

class PasscodeSetupScreen extends StatefulWidget {
  const PasscodeSetupScreen({super.key});

  @override
  State<PasscodeSetupScreen> createState() => _PasscodeSetupScreenState();
}

class _PasscodeSetupScreenState extends State<PasscodeSetupScreen> {
  final AuthService _authService = AuthService();
  String _passcode = '';
  String _confirmPasscode = '';
  bool _isConfirming = false;
  String? _errorMessage;

  void _onNumberPressed(String number) {
    setState(() {
      _errorMessage = null;
      
      if (_isConfirming) {
        if (_confirmPasscode.length < 6) {
          _confirmPasscode += number;
          
          if (_confirmPasscode.length == _passcode.length) {
            _verifyPasscode();
          }
        }
      } else {
        if (_passcode.length < 6) {
          _passcode += number;
          
          if (_passcode.length >= 4) {
            // Can proceed to confirm after 4 digits
          }
        }
      }
    });
  }

  void _onDeletePressed() {
    setState(() {
      _errorMessage = null;
      if (_isConfirming) {
        if (_confirmPasscode.isNotEmpty) {
          _confirmPasscode = _confirmPasscode.substring(0, _confirmPasscode.length - 1);
        }
      } else {
        if (_passcode.isNotEmpty) {
          _passcode = _passcode.substring(0, _passcode.length - 1);
        }
      }
    });
  }

  void _onContinue() {
    if (_passcode.length >= 4 && _passcode.length <= 6) {
      setState(() {
        _isConfirming = true;
        _errorMessage = null;
      });
    }
  }

  Future<void> _verifyPasscode() async {
    if (_passcode == _confirmPasscode) {
      // Passcodes match - save it
      try {
        await _authService.setPasscode(_passcode);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Passcode set successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate to home
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to save passcode';
          _confirmPasscode = '';
        });
      }
    } else {
      // Passcodes don't match
      setState(() {
        _errorMessage = 'Passcodes don\'t match. Try again.';
        _confirmPasscode = '';
        _isConfirming = false;
        _passcode = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Provider.of<ThemeProvider>(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () {
            if (_isConfirming) {
              setState(() {
                _isConfirming = false;
                _confirmPasscode = '';
                _errorMessage = null;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                         MediaQuery.of(context).padding.top - 
                         MediaQuery.of(context).padding.bottom - 
                         kToolbarHeight - 48,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Icon
                  Icon(
                    Icons.pin,
                    size: 60,
                    color: primaryColor,
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    _isConfirming ? 'Confirm Passcode' : 'Create Passcode',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isConfirming
                        ? 'Re-enter your passcode'
                        : 'Enter 4-6 digits',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Passcode dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      final currentPasscode = _isConfirming ? _confirmPasscode : _passcode;
                      final isFilled = index < currentPasscode.length;
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled ? primaryColor : Colors.transparent,
                          border: Border.all(
                            color: isFilled ? primaryColor : Colors.grey,
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const Spacer(),

                  // Number pad
                  _NumberPad(
                    onNumberPressed: _onNumberPressed,
                    onDeletePressed: _onDeletePressed,
                    primaryColor: primaryColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),

                  // Continue button (only show when not confirming and passcode is 4-6 digits)
                  if (!_isConfirming && _passcode.length >= 4 && _passcode.length <= 6)
                    ElevatedButton(
                      onPressed: _onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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

class _NumberPad extends StatelessWidget {
  final Function(String) onNumberPressed;
  final VoidCallback onDeletePressed;
  final Color primaryColor;
  final bool isDark;

  const _NumberPad({
    required this.onNumberPressed,
    required this.onDeletePressed,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow(['1', '2', '3']),
        const SizedBox(height: 12),
        _buildRow(['4', '5', '6']),
        const SizedBox(height: 12),
        _buildRow(['7', '8', '9']),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 70, height: 70), // Empty space
            _buildNumberButton('0'),
            _buildDeleteButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) => _buildNumberButton(number)).toList(),
    );
  }

  Widget _buildNumberButton(String number) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onNumberPressed(number),
        borderRadius: BorderRadius.circular(35),
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onDeletePressed,
        borderRadius: BorderRadius.circular(35),
        child: Container(
          width: 70,
          height: 70,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              color: isDark ? Colors.white : Colors.black87,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
