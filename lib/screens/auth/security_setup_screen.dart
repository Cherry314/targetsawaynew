// lib/screens/auth/security_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../services/auth_service.dart';

class SecuritySetupScreen extends StatefulWidget {
  const SecuritySetupScreen({super.key});

  @override
  State<SecuritySetupScreen> createState() => _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends State<SecuritySetupScreen> {
  final AuthService _authService = AuthService();
  bool _biometricAvailable = false;
  String _biometricType = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final available = await _authService.isBiometricAvailable();
      final biometrics = await _authService.getAvailableBiometrics();
      
      String type = 'Biometric';
      if (biometrics.isNotEmpty) {
        type = biometrics.first.toString().contains('face') 
            ? 'Face ID' 
            : 'Fingerprint';
      }

      setState(() {
        _biometricAvailable = available;
        _biometricType = type;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _setupPasscode() async {
    Navigator.pushNamed(context, '/passcode_setup');
  }

  Future<void> _setupBiometric() async {
    try {
      final authenticated = await _authService.authenticateWithBiometrics();
      
      if (authenticated) {
        await _authService.setBiometricEnabled(true);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$_biometricType enabled successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _goToHome();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _skipSecurity() {
    _goToHome();
  }

  void _goToHome() {
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Icon
              Icon(
                Icons.security,
                size: 80,
                color: primaryColor,
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                'Secure Your App',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Choose how you want to protect your data',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Passcode Option
              _SecurityOptionCard(
                icon: Icons.pin,
                title: 'Set Up Passcode',
                description: 'Use a 4-6 digit code to unlock',
                primaryColor: primaryColor,
                isDark: isDark,
                onTap: _setupPasscode,
              ),
              const SizedBox(height: 16),

              // Biometric Option
              if (_biometricAvailable)
                _SecurityOptionCard(
                  icon: Icons.fingerprint,
                  title: 'Use $_biometricType',
                  description: 'Quick and secure authentication',
                  primaryColor: primaryColor,
                  isDark: isDark,
                  onTap: _setupBiometric,
                ),
              
              if (_biometricAvailable) const SizedBox(height: 16),

              // Skip Option
              _SecurityOptionCard(
                icon: Icons.lock_open,
                title: 'Skip for Now',
                description: 'You can set this up later in settings',
                primaryColor: Colors.grey,
                isDark: isDark,
                onTap: _skipSecurity,
                isOutlined: true,
              ),

              const Spacer(),

              // Info text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: primaryColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can always change these settings later',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onTap;
  final bool isOutlined;

  const _SecurityOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isOutlined
                ? Colors.transparent
                : (isDark ? Colors.grey[850] : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOutlined
                  ? (isDark ? Colors.grey[700]! : Colors.grey[300]!)
                  : primaryColor.withOpacity(0.3),
              width: isOutlined ? 1 : 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: primaryColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
