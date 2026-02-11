// lib/screens/auth/app_unlock_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../services/auth_service.dart';

class AppUnlockScreen extends StatefulWidget {
  const AppUnlockScreen({super.key});

  @override
  State<AppUnlockScreen> createState() => _AppUnlockScreenState();
}

class _AppUnlockScreenState extends State<AppUnlockScreen> {
  final AuthService _authService = AuthService();
  String _passcode = '';
  String? _errorMessage;
  bool _hasBiometric = false;
  bool _hasPasscode = false;
  bool _isLoading = true;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final hasBiometric = await _authService.isBiometricEnabled();
      final hasPasscode = await _authService.hasPasscode();
      
      // Get user name
      final user = _authService.currentUser;
      String name = 'User';
      if (user != null) {
        try {
          final profile = await _authService.getUserProfile(user.uid);
          name = profile.firstName;
        } catch (e) {
          // Ignore error getting profile
        }
      }

      setState(() {
        _hasBiometric = hasBiometric;
        _hasPasscode = hasPasscode;
        _userName = name;
        _isLoading = false;
      });

      // Auto-prompt biometric if enabled
      if (hasBiometric) {
        _authenticateWithBiometric();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _authenticateWithBiometric() async {
    try {
      final authenticated = await _authService.authenticateWithBiometrics();
      
      if (authenticated) {
        _unlockApp();
      }
    } catch (e) {
      // Biometric failed, user can still use passcode
    }
  }

  void _onNumberPressed(String number) {
    if (_passcode.length < 6) {
      setState(() {
        _errorMessage = null;
        _passcode += number;
      });

      // Auto-verify when passcode length matches
      if (_passcode.length >= 4) {
        _verifyPasscode();
      }
    }
  }

  void _onDeletePressed() {
    if (_passcode.isNotEmpty) {
      setState(() {
        _errorMessage = null;
        _passcode = _passcode.substring(0, _passcode.length - 1);
      });
    }
  }

  Future<void> _verifyPasscode() async {
    final isValid = await _authService.verifyPasscode(_passcode);
    
    if (isValid) {
      _unlockApp();
    } else {
      setState(() {
        _errorMessage = 'Incorrect passcode';
        _passcode = '';
      });
    }
  }

  void _unlockApp() {
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Provider.of<ThemeProvider>(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              const SizedBox(height: 60),
              // App Icon
              Icon(
                Icons.gps_fixed,
                size: 80,
                color: primaryColor,
              ),
              const SizedBox(height: 24),
              // Welcome message
              Text(
                'Welcome back,',
                style: TextStyle(
                  fontSize: 20,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                _userName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Passcode dots
              if (_hasPasscode)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    final isFilled = index < _passcode.length;
                    
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

              const SizedBox(height: 40),

              // Biometric button
              if (_hasBiometric)
                ElevatedButton.icon(
                  onPressed: _authenticateWithBiometric,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Use Biometric'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              
              if (_hasBiometric && _hasPasscode) const SizedBox(height: 16),

              // Number pad
              if (_hasPasscode)
                _NumberPad(
                  onNumberPressed: _onNumberPressed,
                  onDeletePressed: _onDeletePressed,
                  primaryColor: primaryColor,
                  isDark: isDark,
                ),
              
              const SizedBox(height: 24),

              // Logout button
              TextButton(
                onPressed: _logout,
                child: Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
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
