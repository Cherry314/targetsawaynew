// lib/screens/auth/registration_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../../models/hive/club.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _clubSearchController = TextEditingController();

  final Set<String> _selectedClubs = {};
  List<String> _searchResults = [];
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isLoadingClubs = false;
  bool _clubsChecked = false;

  @override
  void initState() {
    super.initState();
    _clubSearchController.addListener(_onSearchChanged);
    _checkAndLoadClubs();
  }

  /// Check if clubs are loaded, and if not, download them from Firestore
  Future<void> _checkAndLoadClubs() async {
    setState(() {
      _clubsChecked = false;
    });

    final clubsBox = Hive.box<Club>('clubs');
    
    // If clubs are already loaded, no need to download
    if (clubsBox.isNotEmpty) {
      setState(() {
        _clubsChecked = true;
      });
      return;
    }

    // Clubs are empty, try to download from Firestore
    setState(() {
      _isLoadingClubs = true;
    });

    try {
      await _downloadClubsFromFirestore();
      if (mounted) {
        setState(() {
          _isLoadingClubs = false;
          _clubsChecked = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingClubs = false;
          _clubsChecked = true;
        });
      }
    }
  }

  /// Download clubs from Firestore
  Future<void> _downloadClubsFromFirestore() async {
    final firestore = FirebaseFirestore.instance;
    final clubsBox = Hive.box<Club>('clubs');

    // Clear existing clubs (if any)
    await clubsBox.clear();

    // Download from Firestore
    final snapshot = await firestore.collection('clubs').get();
    
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey('clubname')) {
        final club = Club(clubname: data['clubname'] as String);
        await clubsBox.add(club);
      }
    }
  }

  /// Manual refresh button handler
  Future<void> _refreshClubs() async {
    setState(() {
      _isLoadingClubs = true;
    });

    try {
      await _downloadClubsFromFirestore();
      if (mounted) {
        setState(() {
          _isLoadingClubs = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded ${Hive.box<Club>('clubs').length} clubs'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _clubSearchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _clubSearchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final clubsBox = Hive.box<Club>('clubs');
    final allClubs = clubsBox.values.map((club) => club.clubname).toList();

    final filtered = allClubs
        .where((club) => club.toLowerCase().contains(query))
        .where((club) => !_selectedClubs.contains(club))
        .toList();

    setState(() {
      _searchResults = filtered;
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedClubs.isEmpty) {
      _showError('Please select at least one club');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      await authService.registerWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        clubs: _selectedClubs.toList(),
      );

      if (mounted) {
        // Navigate to security setup screen
        Navigator.pushReplacementNamed(context, '/security_setup');
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Provider.of<ThemeProvider>(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // App Icon
                Icon(
                  Icons.gps_fixed,
                  size: 80,
                  color: primaryColor,
                ),
                const SizedBox(height: 16),
                // Title
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Join Targets Away',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // First Name
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    prefixIcon: Icon(Icons.person, color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your first name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Last Name
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your last name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email, color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock, color: primaryColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.white,
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Club Selection
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.sports, color: primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Select Your Clubs',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'You can select multiple clubs',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                          if (_clubsChecked && !_isLoadingClubs && Hive.box<Club>('clubs').isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${Hive.box<Club>('clubs').length} clubs',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Loading clubs indicator
                      if (_isLoadingClubs) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
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
                              Expanded(
                                child: Text(
                                  'Downloading clubs from database...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ]
                      // Database empty warning with retry button
                      else if (_clubsChecked && Hive.box<Club>('clubs').isEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'No clubs available in database.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'You can enter your club name manually below, or try refreshing the clubs list.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _refreshClubs,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Refresh Clubs List'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  minimumSize: Size.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Search Field
                      TextField(
                        controller: _clubSearchController,
                        onSubmitted: (value) {
                          // Allow manual entry if database is empty or no results
                          if (value.trim().isNotEmpty && 
                              (Hive.box<Club>('clubs').isEmpty || _searchResults.isEmpty)) {
                            setState(() {
                              _selectedClubs.add(value.trim());
                              _clubSearchController.clear();
                              _searchResults = [];
                            });
                          }
                        },
                        decoration: InputDecoration(
                          hintText: Hive.box<Club>('clubs').isEmpty 
                              ? 'Type your club name and press Enter'
                              : 'Search for a club...',
                          prefixIcon: Icon(
                            Hive.box<Club>('clubs').isEmpty ? Icons.edit : Icons.search, 
                            color: primaryColor,
                          ),
                          suffixIcon: _clubSearchController.text.isNotEmpty
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (Hive.box<Club>('clubs').isEmpty || 
                                        (_clubSearchController.text.isNotEmpty && _searchResults.isEmpty))
                                      IconButton(
                                        icon: Icon(Icons.add, color: primaryColor),
                                        tooltip: 'Add this club',
                                        onPressed: () {
                                          final clubName = _clubSearchController.text.trim();
                                          if (clubName.isNotEmpty) {
                                            setState(() {
                                              _selectedClubs.add(clubName);
                                              _clubSearchController.clear();
                                              _searchResults = [];
                                            });
                                          }
                                        },
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _clubSearchController.clear();
                                      },
                                    ),
                                  ],
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Search Results or Messages
                      if (_clubSearchController.text.isNotEmpty) ...[
                        if (_searchResults.isNotEmpty) ...[
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
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
                                  title: Text(
                                    club,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedClubs.add(club);
                                        _clubSearchController.clear();
                                        _searchResults = [];
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                    ),
                                    child: const Text(
                                      'Select',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ] else ...[
                          // No results found
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[850] : Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No clubs found matching "${_clubSearchController.text}"',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  Hive.box<Club>('clubs').isEmpty
                                      ? 'The clubs database is empty. You can manually enter your club name or use the refresh button above.'
                                      : 'Try a different search term or manually enter your club name.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : Colors.black45,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                      ],

                      // Selected Clubs
                      if (_selectedClubs.isNotEmpty) ...[
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'Selected Clubs:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedClubs.map((club) {
                            return Chip(
                              label: Text(club),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () {
                                setState(() {
                                  _selectedClubs.remove(club);
                                });
                              },
                              backgroundColor: primaryColor.withOpacity(0.1),
                              deleteIconColor: primaryColor,
                              labelStyle: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 12,
                              ),
                            );
                          }).toList(),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Text(
                          'No clubs selected yet. Search and select at least one club.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black45,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Register Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
