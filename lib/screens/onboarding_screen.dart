import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../utils/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Religion? _selectedReligion;
  int _currentStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return Column(
              children: [
                // Progress Indicator
                _buildProgressIndicator(),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 40),
                          
                          if (_currentStep == 0) ...[
                            _buildWelcomeStep(),
                          ] else if (_currentStep == 1) ...[
                            _buildReligionSelectionStep(),
                          ] else if (_currentStep == 2) ...[
                            _buildProfileStep(),
                          ],
                          
                          const SizedBox(height: 40),
                          
                          // Navigation Buttons
                          _buildNavigationButtons(authProvider),
                          
                          const SizedBox(height: 20),
                          
                          // Error Message
                          if (authProvider.error != null)
                            _buildErrorWidget(authProvider.error!),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: List.generate(3, (index) {
          bool isActive = index <= _currentStep;
          bool isCompleted = index < _currentStep;
          
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              decoration: BoxDecoration(
                color: isCompleted 
                    ? AppTheme.primaryColor
                    : isActive 
                        ? AppTheme.primaryColor.withOpacity(0.3)
                        : AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return Column(
      children: [
        // Welcome Icon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(60),
          ),
          child: const Icon(
            Icons.self_improvement,
            size: 60,
            color: AppTheme.primaryColor,
          ),
        ),
        
        const SizedBox(height: 32),
        
        const Text(
          'Welcome to DivineConnect',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontFamily: 'Poppins',
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 16),
        
        const Text(
          'Connect with people who share your spiritual journey. Let\'s personalize your experience.',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
            fontFamily: 'Poppins',
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildReligionSelectionStep() {
    return Column(
      children: [
        const Text(
          'Choose Your Faith',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        
        const SizedBox(height: 8),
        
        const Text(
          'Select your religion to personalize your feed',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
            fontFamily: 'Poppins',
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 32),
        
        // Religion Options
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: Religion.values.length,
          itemBuilder: (context, index) {
            Religion religion = Religion.values[index];
            bool isSelected = _selectedReligion == religion;
            
            return _buildReligionCard(religion, isSelected);
          },
        ),
      ],
    );
  }

  Widget _buildReligionCard(Religion religion, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedReligion = religion;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryColor
                : AppTheme.borderColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _getReligionSymbol(religion),
              style: TextStyle(
                fontSize: 32,
                color: isSelected ? Colors.white : _getReligionColor(religion),
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              _getReligionName(religion),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStep() {
    return Column(
      children: [
        const Text(
          'Complete Your Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        
        const SizedBox(height: 8),
        
        const Text(
          'Tell us a bit about yourself',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
            fontFamily: 'Poppins',
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 32),
        
        // Name Input
        _buildInputField(
          controller: _nameController,
          label: 'Full Name',
          hint: 'Enter your full name',
          icon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Email Input
        _buildInputField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'Enter your email address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Bio Input
        _buildInputField(
          controller: _bioController,
          label: 'Bio (Optional)',
          hint: 'Tell us about yourself...',
          icon: Icons.edit_outlined,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppTheme.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(AuthProvider authProvider) {
    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: authProvider.isLoading ? null : _previousStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: AppTheme.primaryColor),
              ),
              child: const Text(
                'Back',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        
        Expanded(
          child: ElevatedButton(
            onPressed: authProvider.isLoading ? null : _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
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
                : Text(
                    _currentStep == 2 ? 'Complete' : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() async {
    if (_currentStep == 1 && _selectedReligion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a religion'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_currentStep == 2) {
      if (!_formKey.currentState!.validate()) return;
      
      // Complete onboarding
      final authProvider = context.read<AuthProvider>();
      await authProvider.createUserProfile(
        name: _nameController.text,
        email: _emailController.text,
        selectedReligion: _selectedReligion,
        bio: _bioController.text.isNotEmpty ? _bioController.text : null,
      );
    } else {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  String _getReligionSymbol(Religion religion) {
    switch (religion) {
      case Religion.hinduism:
        return 'ॐ';
      case Religion.islam:
        return '☪';
      case Religion.christianity:
        return '✝';
      case Religion.buddhism:
        return '☸';
      case Religion.sikhism:
        return '☬';
      case Religion.judaism:
        return '✡';
      case Religion.other:
        return '🕉';
    }
  }

  String _getReligionName(Religion religion) {
    switch (religion) {
      case Religion.hinduism:
        return 'Hinduism';
      case Religion.islam:
        return 'Islam';
      case Religion.christianity:
        return 'Christianity';
      case Religion.buddhism:
        return 'Buddhism';
      case Religion.sikhism:
        return 'Sikhism';
      case Religion.judaism:
        return 'Judaism';
      case Religion.other:
        return 'Other';
    }
  }

  Color _getReligionColor(Religion religion) {
    switch (religion) {
      case Religion.hinduism:
        return Colors.orange;
      case Religion.islam:
        return Colors.green;
      case Religion.christianity:
        return Colors.blue;
      case Religion.buddhism:
        return Colors.purple;
      case Religion.sikhism:
        return Colors.amber;
      case Religion.judaism:
        return Colors.indigo;
      case Religion.other:
        return Colors.grey;
    }
  }
} 