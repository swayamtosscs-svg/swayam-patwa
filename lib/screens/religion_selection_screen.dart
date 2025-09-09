import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class ReligionSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> googleUserData;
  final String authToken;
  
  const ReligionSelectionScreen({
    super.key,
    required this.googleUserData,
    required this.authToken,
  });

  @override
  State<ReligionSelectionScreen> createState() => _ReligionSelectionScreenState();
}

class _ReligionSelectionScreenState extends State<ReligionSelectionScreen> {
  String? _selectedReligion;
  bool _isLoading = false;
  String? _error;

  final List<Map<String, dynamic>> _religions = [
    {
      'name': 'hinduism',
      'displayName': 'Hinduism',
      'icon': Icons.auto_awesome,
      'color': const Color(0xFFFF6B35),
      'description': 'Ancient Indian religion with diverse traditions',
    },
    {
      'name': 'islam',
      'displayName': 'Islam',
      'icon': Icons.star,
      'color': const Color(0xFF2E8B57),
      'description': 'Monotheistic Abrahamic religion',
    },
    {
      'name': 'christianity',
      'displayName': 'Christianity',
      'icon': Icons.add,
      'color': const Color(0xFF4169E1),
      'description': 'Abrahamic religion based on Jesus Christ',
    },
    {
      'name': 'sikhism',
      'displayName': 'Sikhism',
      'icon': Icons.circle,
      'color': const Color(0xFFFFD700),
      'description': 'Monotheistic religion from Punjab',
    },
    {
      'name': 'buddhism',
      'displayName': 'Buddhism',
      'icon': Icons.self_improvement,
      'color': const Color(0xFF8B4513),
      'description': 'Path to enlightenment and inner peace',
    },
    {
      'name': 'other',
      'displayName': 'Other',
      'icon': Icons.favorite,
      'color': const Color(0xFF9370DB),
      'description': 'Other spiritual or religious beliefs',
    },
  ];

  Future<void> _completeRegistration() async {
    if (_selectedReligion == null) {
      setState(() {
        _error = 'Please select a religion to continue';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Update the user data with selected religion
      final updatedUserData = Map<String, dynamic>.from(widget.googleUserData);
      updatedUserData['religion'] = _selectedReligion;

      // Complete the registration with the auth provider using the real token
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.handleSuccessfulLogin(
        widget.authToken,
        updatedUserData,
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome to R-Gram! Your spiritual journey begins here.'),
            backgroundColor: const Color(0xFF6366F1),
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Registration failed: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFDF7EC),
              Color(0xFFE8F5E8),
              Color(0xFFD4F0D4),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const SizedBox(height: 40),
                const Text(
                  'Choose Your Spiritual Path',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome ${widget.googleUserData['fullName'] ?? 'User'}! Please select your religion to personalize your experience.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 40),

                // Religion Grid
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: _religions.length,
                    itemBuilder: (context, index) {
                      final religion = _religions[index];
                      final isSelected = _selectedReligion == religion['name'];
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedReligion = religion['name'];
                            _error = null;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? religion['color'].withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? religion['color'] : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: religion['color'].withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    religion['icon'],
                                    color: religion['color'],
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                                                 Text(
                                   religion['displayName'],
                                   style: TextStyle(
                                     fontSize: 16,
                                     fontWeight: FontWeight.w600,
                                     color: isSelected ? religion['color'] : const Color(0xFF1A1A1A),
                                     fontFamily: 'Poppins',
                                   ),
                                   textAlign: TextAlign.center,
                                 ),
                                const SizedBox(height: 4),
                                Text(
                                  religion['description'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontFamily: 'Poppins',
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Error message
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 14,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Continue Button
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _completeRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Continue to R-Gram'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
