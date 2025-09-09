import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/baba_page_model.dart';
import '../services/baba_page_service.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class BabaPageEditScreen extends StatefulWidget {
  final BabaPage babaPage;

  const BabaPageEditScreen({
    super.key,
    required this.babaPage,
  });

  @override
  State<BabaPageEditScreen> createState() => _BabaPageEditScreenState();
}

class _BabaPageEditScreenState extends State<BabaPageEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();

  String _selectedReligion = 'Hinduism';
  bool _isLoading = false;

  final List<String> _religions = [
    'Hinduism',
    'Islam',
    'Christianity',
    'Sikhism',
    'Buddhism',
    'Jainism',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _nameController.text = widget.babaPage.name;
    _descriptionController.text = widget.babaPage.description;
    _locationController.text = widget.babaPage.location;
    _websiteController.text = widget.babaPage.website;
    _selectedReligion = widget.babaPage.religion;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _updateBabaPage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;

      if (token == null) {
        _showErrorSnackBar('Please login to update Baba Ji page');
        return;
      }

      final request = BabaPageRequest(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        religion: _selectedReligion,
        website: _websiteController.text.trim(),
      );

      final response = await BabaPageService.updateBabaPage(
        pageId: widget.babaPage.id,
        request: request,
        token: token,
      );

      if (response.success) {
        _showSuccessSnackBar('Baba Ji page updated successfully!');
        Navigator.of(context).pop(true); // Return true to indicate success
      } else {
        _showErrorSnackBar(response.message);
      }
    } catch (e) {
      _showErrorSnackBar('Error updating Baba Ji page: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Edit Baba Ji Page',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                print('Back button pressed in BabaPageEditScreen');
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  print('Cannot pop - no previous route');
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _updateBabaPage,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Baba Ji Name *',
                  hintText: 'Enter the name of the spiritual leader',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Enter a brief description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Location Field
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'Enter the location (city, country)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 20),

              // Religion Dropdown
              DropdownButtonFormField<String>(
                value: _selectedReligion,
                decoration: const InputDecoration(
                  labelText: 'Religion *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.self_improvement),
                ),
                items: _religions.map((String religion) {
                  return DropdownMenuItem<String>(
                    value: religion,
                    child: Text(religion),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedReligion = newValue!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a religion';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Website Field
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(
                  labelText: 'Website',
                  hintText: 'Enter website URL (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.web),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 30),

              // Update Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateBabaPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Update Baba Ji Page',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
