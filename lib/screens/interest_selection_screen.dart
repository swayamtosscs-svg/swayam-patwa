import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class InterestSelectionScreen extends StatefulWidget {
  const InterestSelectionScreen({super.key});

  @override
  State<InterestSelectionScreen> createState() => _InterestSelectionScreenState();
}

class _InterestSelectionScreenState extends State<InterestSelectionScreen> {
  String? selectedReligion;
  
  static const List<Map<String, dynamic>> interests = [
    {
      'name': 'Hinduism',
      'icon': Icons.self_improvement,
      'color': Color(0xFF8A9A87),
      'gradient': [Color(0xFF8A9A87), Color(0xFF9BAF9A)],
      'description': 'Ancient Indian religion and philosophy',
      'followers': '1.2B followers'
    },
    {
      'name': 'Christianity',
      'icon': Icons.church,
      'color': Color(0xFF8A9A87),
      'gradient': [Color(0xFF8A9A87), Color(0xFF9BAF9A)],
      'description': 'Faith based on the teachings of Jesus Christ',
      'followers': '2.4B followers'
    },
    {
      'name': 'Islam',
      'icon': Icons.star,
      'color': Color(0xFF8A9A87),
      'gradient': [Color(0xFF8A9A87), Color(0xFF9BAF9A)],
      'description': 'Monotheistic Abrahamic religion',
      'followers': '1.9B followers'
    },
    {
      'name': 'Buddhism',
      'icon': Icons.spa,
      'color': Color(0xFF8A9A87),
      'gradient': [Color(0xFF8A9A87), Color(0xFF9BAF9A)],
      'description': 'Path to spiritual enlightenment',
      'followers': '535M followers'
    },
    {
      'name': 'Sikhism',
      'icon': Icons.wb_sunny,
      'color': Color(0xFF8A9A87),
      'gradient': [Color(0xFF8A9A87), Color(0xFF9BAF9A)],
      'description': 'Monotheistic religion from Punjab',
      'followers': '30M followers'
    },
    {
      'name': 'Judaism',
      'icon': Icons.star_border,
      'color': Color(0xFF8A9A87),
      'gradient': [Color(0xFF8A9A87), Color(0xFF9BAF9A)],
      'description': 'Ancient monotheistic religion',
      'followers': '15M followers'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.favorite,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Choose Your Spiritual Path',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select the religion that resonates with your soul',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Religion cards
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: interests.length,
                  itemBuilder: (context, index) {
                    final interest = interests[index];
                    final isSelected = selectedReligion == interest['name'];
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedReligion = interest['name'];
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: interest['gradient'],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected 
                                  ? interest['color'].withOpacity(0.4)
                                  : Colors.black.withOpacity(0.2),
                              spreadRadius: isSelected ? 2 : 1,
                              blurRadius: isSelected ? 8 : 4,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Content
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Round Icon
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          spreadRadius: 2,
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      interest['icon'],
                                      size: 40,
                                      color: const Color(0xFF8A9A87),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Religion name
                                  Text(
                                    interest['name'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  // Description
                                  Text(
                                    interest['description'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                  
                                  const SizedBox(height: 4),
                                  
                                  // Followers count
                                  Text(
                                    interest['followers'],
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white.withOpacity(0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            
                            // Selection indicator
                            if (isSelected)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Color(0xFF8A9A87),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Continue button
            if (selectedReligion != null)
              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8A9A87),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      // Update user's selected religion in auth provider
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      authProvider.updateSelectedReligion(selectedReligion!);
                      
                                             // Navigate to video feed
                       Navigator.pushReplacementNamed(
                         context,
                         '/video-feed',
                         arguments: selectedReligion,
                       );
                    },
                    child: Text(
                      'Continue with $selectedReligion',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}