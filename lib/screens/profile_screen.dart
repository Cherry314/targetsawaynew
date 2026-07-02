// lib/screens/profile_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../models/user_profile.dart';
import '../models/hive/club.dart';
import '../widgets/app_drawer.dart';
import '../widgets/help_icon_button.dart';
import '../utils/help_content.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _profilePhotoPathKey = 'profilePhotoPath';

  final AuthService _authService = AuthService();
  UserProfile? _userProfile;
  bool _loadingProfile = true;
  String? _profilePhotoPath;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPhotoPath = prefs.getString(_profilePhotoPathKey);
      final user = _authService.currentUser;
      if (user != null) {
        final profile = await _authService.getUserProfile(user.uid);
        if (!mounted) return;
        setState(() {
          _userProfile = profile;
          _profilePhotoPath = savedPhotoPath;
          _loadingProfile = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _profilePhotoPath = savedPhotoPath;
          _loadingProfile = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingProfile = false;
      });
    }
  }

  String _getBiometricTypeName(List<BiometricType> types) {
    if (types.isEmpty) return 'biometric';
    final names = types.map((b) {
      switch (b) {
        case BiometricType.fingerprint:
          return 'fingerprint';
        case BiometricType.face:
          return 'face recognition';
        case BiometricType.iris:
          return 'iris';
        default:
          return 'biometric';
      }
    }).toList();
    return names.join('/');
  }

  String _getProfileInitials() {
    final firstInitial = _userProfile?.firstName.trim().isNotEmpty == true
        ? _userProfile!.firstName.trim()[0]
        : '';
    final lastInitial = _userProfile?.lastName.trim().isNotEmpty == true
        ? _userProfile!.lastName.trim()[0]
        : '';
    final initials = '$firstInitial$lastInitial'.toUpperCase();
    return initials.isNotEmpty ? initials : '?';
  }

  bool get _hasProfilePhoto {
    final path = _profilePhotoPath;
    return path != null && path.isNotEmpty && File(path).existsSync();
  }

  Future<void> _checkAndLoadClubs() async {
    final clubsBox = Hive.box<Club>('clubs');
    if (clubsBox.isNotEmpty) return;

    await _downloadClubsFromFirestore();
  }

  Future<void> _downloadClubsFromFirestore() async {
    final firestore = FirebaseFirestore.instance;
    final clubsBox = Hive.box<Club>('clubs');

    await clubsBox.clear();

    final snapshot = await firestore.collection('clubs').get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey('clubname')) {
        await clubsBox.add(Club(clubname: data['clubname'] as String));
      }
    }
  }

  Future<void> _showEditClubsDialog() async {
    final profile = _userProfile;
    if (profile == null) return;

    if (Hive.box<Club>('clubs').isEmpty) {
      try {
        await _checkAndLoadClubs();
      } catch (_) {
        // The edit dialog still allows manual club entry if clubs cannot load.
      }
    }

    if (!mounted) return;

    final updatedClubRenewalDates = await showDialog<Map<String, DateTime>>(
      context: context,
      builder: (_) => _EditClubsDialog(
        initialClubs: profile.clubs,
        initialClubRenewalDates: profile.clubRenewalDates,
        downloadClubsFromFirestore: _downloadClubsFromFirestore,
      ),
    );

    if (updatedClubRenewalDates == null) return;

    try {
      final updatedClubs = updatedClubRenewalDates.keys.toList();
      final updatedProfile = profile.copyWith(
        clubs: updatedClubs,
        clubRenewalDates: updatedClubRenewalDates,
      );
      await _authService.updateUserProfile(updatedProfile);
      if (!mounted) return;
      setState(() {
        _userProfile = updatedProfile;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clubs updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update clubs: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateProfilePhoto(ImageSource source) async {
    try {
      final imageQualityProvider = Provider.of<ImageQualityProvider>(
        context,
        listen: false,
      );
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: imageQualityProvider.qualityPercentage,
      );
      if (picked == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final profileDir = Directory('${appDir.path}/images/profile');
      await profileDir.create(recursive: true);

      final extension = picked.path.split('.').last.toLowerCase();
      final safeExtension = extension.isNotEmpty ? extension : 'jpg';
      final savedFile = File(
        '${profileDir.path}/profile_photo_${DateTime.now().millisecondsSinceEpoch}.$safeExtension',
      );
      await File(picked.path).copy(savedFile.path);

      final prefs = await SharedPreferences.getInstance();
      final previousPhotoPath = _profilePhotoPath;
      await prefs.setString(_profilePhotoPathKey, savedFile.path);

      if (previousPhotoPath != null && previousPhotoPath != savedFile.path) {
        final previousFile = File(previousPhotoPath);
        if (await previousFile.exists()) {
          await previousFile.delete();
        }
      }

      if (!mounted) return;
      setState(() {
        _profilePhotoPath = savedFile.path;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile photo: $e')),
      );
    }
  }

  Future<void> _removeProfilePhoto() async {
    final currentPhotoPath = _profilePhotoPath;
    if (currentPhotoPath == null || currentPhotoPath.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Profile Photo?'),
        content: const Text('Your initials will be shown instead.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profilePhotoPathKey);
    final currentFile = File(currentPhotoPath);
    if (await currentFile.exists()) {
      await currentFile.delete();
    }

    if (!mounted) return;
    setState(() {
      _profilePhotoPath = null;
    });
  }

  Future<void> _showProfilePhotoOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _updateProfilePhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _updateProfilePhoto(ImageSource.gallery);
              },
            ),
            if (_hasProfilePhoto)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfilePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(Color primaryColor) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: primaryColor,
          backgroundImage: _hasProfilePhoto
              ? FileImage(File(_profilePhotoPath!))
              : null,
          child: _hasProfilePhoto
              ? null
              : Text(
                  _getProfileInitials(),
                  style: const TextStyle(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        Material(
          color: primaryColor,
          shape: const CircleBorder(),
          elevation: 2,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _showProfilePhotoOptions,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClubsSubtitle(BuildContext context) {
    final profile = _userProfile;
    final clubs = profile?.clubs ?? [];
    if (clubs.isEmpty || profile == null) {
      return const Text('No clubs selected');
    }

    final dividerColor = Theme.of(context).dividerColor.withOpacity(0.6);

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < clubs.length; index++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(clubs[index]),
                  Text(
                    'Renewal Date: ${_formatDate(profile.clubRenewalDates[clubs[index]] ?? profile.createdAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (index < clubs.length - 1)
              Divider(height: 1, thickness: 0.5, color: dividerColor),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
    required BuildContext context,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (value != newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (!mounted) return;
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );

        // Re-authenticate user with current password
        await _authService.reauthenticate(currentPasswordController.text);

        // Update password
        await _authService.currentUser?.updatePassword(
          newPasswordController.text,
        );

        // Close loading indicator
        if (mounted) Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password changed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Close loading indicator
        if (mounted) Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to change password: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    // Dispose controllers
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_loadingProfile) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile'), centerTitle: true),
        body: const Center(
          child: Text('No user profile found. Please log in again.'),
        ),
      );
    }

    return Scaffold(
      drawer: const AppDrawer(currentRoute: 'profile'),
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0,
        actions: const [
          HelpIconButton(
            title: 'Profile Help',
            content: HelpContent.profileScreen,
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Profile Header Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildProfileAvatar(themeProvider.primaryColor),
                      const SizedBox(height: 16),
                      Text(
                        _userProfile!.fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userProfile!.email,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Account Section
              _buildSectionCard(
                title: 'Account Information',
                context: context,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person),
                    title: const Text(
                      'Name',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(_userProfile!.fullName),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.email),
                    title: const Text(
                      'Email',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(_userProfile!.email),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.sports),
                    title: const Text(
                      'Clubs',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: _buildClubsSubtitle(context),
                    trailing: TextButton.icon(
                      onPressed: _showEditClubsDialog,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                    ),
                  ),
                ],
              ),

              // Security Section
              _buildSectionCard(
                title: 'Security',
                context: context,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.pin),
                    title: const Text('Change Passcode'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pushNamed(context, '/passcode_setup');
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.lock),
                    title: const Text('Change Password'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _showChangePasswordDialog,
                  ),
                  const Divider(height: 1),
                  FutureBuilder<bool>(
                    future: _authService.isBiometricAvailable(),
                    builder: (context, availabilitySnapshot) {
                      if (availabilitySnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      if (availabilitySnapshot.data == true) {
                        return FutureBuilder<List<BiometricType>>(
                          future: _authService.getAvailableBiometrics(),
                          builder: (context, biometricsSnapshot) {
                            final availableBiometrics =
                                biometricsSnapshot.data ?? [];
                            final biometricName = availableBiometrics.isNotEmpty
                                ? availableBiometrics
                                      .map((b) {
                                        switch (b) {
                                          case BiometricType.fingerprint:
                                            return 'Fingerprint';
                                          case BiometricType.face:
                                            return 'Face ID';
                                          case BiometricType.iris:
                                            return 'Iris';
                                          default:
                                            return 'Biometric';
                                        }
                                      })
                                      .join('/')
                                : 'Biometric';
                            return FutureBuilder<bool>(
                              future: _authService.isBiometricEnabled(),
                              builder: (context, enabledSnapshot) {
                                final isEnabled = enabledSnapshot.data ?? false;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.fingerprint),
                                  title: Text('$biometricName Authentication'),
                                  trailing: Switch(
                                    value: isEnabled,
                                    onChanged: (value) async {
                                      if (value) {
                                        debugPrint(
                                          'Attempting to enable biometric auth...',
                                        );
                                        // Authenticate first before enabling
                                        final authenticated = await _authService
                                            .authenticateWithBiometrics();
                                        debugPrint(
                                          'Biometric auth result: $authenticated',
                                        );
                                        if (authenticated) {
                                          debugPrint(
                                            'Authentication successful, enabling biometric...',
                                          );
                                          await _authService
                                              .setBiometricEnabled(true);
                                          // Trigger rebuild to show enabled state
                                          if (context.mounted) {
                                            setState(() {});
                                          }
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Biometric authentication enabled.',
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        } else {
                                          // Authentication failed or cancelled
                                          debugPrint(
                                            'Authentication failed or cancelled',
                                          );
                                          if (context.mounted) {
                                            String errorMsg;
                                            if (availableBiometrics.isEmpty) {
                                              errorMsg =
                                                  'No biometrics enrolled on this device. Please set up fingerprint or face unlock in your device settings first.';
                                            } else {
                                              errorMsg =
                                                  'Biometric authentication failed. Please ensure your ${_getBiometricTypeName(availableBiometrics)} is properly enrolled and try again.';
                                            }
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(errorMsg),
                                                backgroundColor: Colors.orange,
                                                duration: const Duration(
                                                  seconds: 5,
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      } else {
                                        // Turning off - no authentication needed
                                        await _authService.setBiometricEnabled(
                                          false,
                                        );
                                        if (context.mounted) {
                                          setState(() {});
                                        }
                                      }
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),

              // Account Actions Section
              _buildSectionCard(
                title: 'Account Actions',
                context: context,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text(
                            'Are you sure you want to logout?',
                          ),
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
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                        }
                      }
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Delete Account',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () async {
                      // Show confirmation dialog
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete Account'),
                          content: const Text(
                            'This action cannot be undone. All your data will be permanently deleted.\n\nAre you sure you want to delete your account?',
                          ),
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
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        if (!context.mounted) return;
                        // Show password re-authentication dialog
                        final passwordController = TextEditingController();
                        final reauthed = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Confirm Identity'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Please enter your password to confirm account deletion:',
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: passwordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Password',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  passwordController.dispose();
                                  Navigator.pop(context, false);
                                },
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await _authService.reauthenticate(
                                      passwordController.text,
                                    );
                                    passwordController.dispose();
                                    if (!context.mounted) return;
                                    Navigator.pop(context, true);
                                  } catch (e) {
                                    passwordController.dispose();
                                    if (!context.mounted) return;
                                    Navigator.pop(context, false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Confirm'),
                              ),
                            ],
                          ),
                        );

                        if (reauthed == true) {
                          try {
                            await _authService.deleteAccount();
                            if (context.mounted) {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/login',
                                (route) => false,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error deleting account: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditClubsDialog extends StatefulWidget {
  final List<String> initialClubs;
  final Map<String, DateTime> initialClubRenewalDates;
  final Future<void> Function() downloadClubsFromFirestore;

  const _EditClubsDialog({
    required this.initialClubs,
    required this.initialClubRenewalDates,
    required this.downloadClubsFromFirestore,
  });

  @override
  State<_EditClubsDialog> createState() => _EditClubsDialogState();
}

class _EditClubsDialogState extends State<_EditClubsDialog> {
  final TextEditingController _clubSearchController = TextEditingController();
  late final Set<String> _selectedClubs;
  late final Map<String, DateTime> _clubRenewalDates;
  List<String> _searchResults = [];
  bool _isLoadingClubs = false;

  @override
  void initState() {
    super.initState();
    _selectedClubs = widget.initialClubs.toSet();
    _clubRenewalDates = {
      for (final club in widget.initialClubs)
        club: widget.initialClubRenewalDates[club] ?? DateTime.now(),
    };
  }

  @override
  void dispose() {
    _clubSearchController.dispose();
    super.dispose();
  }

  List<String> _filterAvailableClubs(String query) {
    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isEmpty) return [];

    final clubsBox = Hive.box<Club>('clubs');
    final allClubs = clubsBox.values.map((club) => club.clubname).toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return allClubs
        .where((club) => club.toLowerCase().contains(normalizedQuery))
        .where((club) => !_selectedClubs.contains(club))
        .toList();
  }

  void _refreshSearchResults() {
    setState(() {
      _searchResults = _filterAvailableClubs(_clubSearchController.text);
    });
  }

  void _addClub(String clubName) {
    final trimmedClubName = clubName.trim();
    if (trimmedClubName.isEmpty) return;

    setState(() {
      _selectedClubs.add(trimmedClubName);
      _clubRenewalDates.putIfAbsent(trimmedClubName, () => DateTime.now());
      _clubSearchController.clear();
      _searchResults = [];
    });
  }

  void _removeClub(String clubName) {
    setState(() {
      _selectedClubs.remove(clubName);
      _clubRenewalDates.remove(clubName);
      _searchResults = _filterAvailableClubs(_clubSearchController.text);
    });
  }

  Future<void> _selectClubRenewalDate(String clubName) async {
    final now = DateTime.now();
    final earliestDate = DateTime(now.year - 1, now.month, now.day);
    final latestDate = DateTime(now.year + 100, now.month, now.day);
    final currentDate = _clubRenewalDates[clubName] ?? now;
    final initialDate = currentDate.isBefore(earliestDate)
        ? earliestDate
        : currentDate.isAfter(latestDate)
        ? latestDate
        : currentDate;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: earliestDate,
      lastDate: latestDate,
    );

    if (selectedDate == null || !mounted) return;

    setState(() {
      _clubRenewalDates[clubName] = selectedDate;
    });
  }

  Map<String, DateTime> _selectedClubRenewalDates() {
    return {
      for (final club in _selectedClubs)
        club: _clubRenewalDates[club] ?? DateTime.now(),
    };
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _refreshClubs() async {
    setState(() {
      _isLoadingClubs = true;
    });

    try {
      await widget.downloadClubsFromFirestore();
      if (!mounted) return;
      setState(() {
        _isLoadingClubs = false;
        _searchResults = _filterAvailableClubs(_clubSearchController.text);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded ${Hive.box<Club>('clubs').length} clubs'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingClubs = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download clubs: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clubsBox = Hive.box<Club>('clubs');

    return AlertDialog(
      title: const Text('Edit Clubs'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add clubs from the list or remove clubs you no longer belong to.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              if (_isLoadingClubs) ...[
                Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Loading clubs...')),
                  ],
                ),
                const SizedBox(height: 12),
              ] else if (clubsBox.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No clubs available in database.',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'You can enter a club manually or refresh the clubs list.',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _isLoadingClubs ? null : _refreshClubs,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Refresh Clubs List'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _clubSearchController,
                onChanged: (_) => _refreshSearchResults(),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty &&
                      (clubsBox.isEmpty || _searchResults.isEmpty)) {
                    _addClub(value);
                  }
                },
                decoration: InputDecoration(
                  hintText: clubsBox.isEmpty
                      ? 'Type your club name and press Enter'
                      : 'Search for a club...',
                  prefixIcon: Icon(
                    clubsBox.isEmpty ? Icons.edit : Icons.search,
                    color: primaryColor,
                  ),
                  suffixIcon: _clubSearchController.text.isNotEmpty
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (clubsBox.isEmpty || _searchResults.isEmpty)
                              IconButton(
                                icon: Icon(Icons.add, color: primaryColor),
                                tooltip: 'Add this club',
                                onPressed: () =>
                                    _addClub(_clubSearchController.text),
                              ),
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _clubSearchController.clear();
                                  _searchResults = [];
                                });
                              },
                            ),
                          ],
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
                ),
              ),
              const SizedBox(height: 12),
              if (_clubSearchController.text.isNotEmpty) ...[
                if (_searchResults.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                      ),
                      itemBuilder: (context, index) {
                        final club = _searchResults[index];
                        return ListTile(
                          dense: true,
                          title: Text(club),
                          trailing: ElevatedButton(
                            onPressed: () => _addClub(club),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Select'),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'No clubs found matching "${_clubSearchController.text}". You can add it manually.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Selected Clubs:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedClubs.isNotEmpty)
                Column(
                  children: _selectedClubs.map((club) {
                    final renewalDate =
                        _clubRenewalDates[club] ?? DateTime.now();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: primaryColor.withOpacity(0.08),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    club,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  color: primaryColor,
                                  tooltip: 'Remove club',
                                  onPressed: () => _removeClub(club),
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            OutlinedButton.icon(
                              onPressed: () => _selectClubRenewalDate(club),
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(
                                'Renewal Date: ${_formatDate(renewalDate)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                )
              else
                Text(
                  'No clubs selected yet. Add at least one club before saving.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black45,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedClubs.isEmpty
              ? null
              : () => Navigator.pop(context, _selectedClubRenewalDates()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
