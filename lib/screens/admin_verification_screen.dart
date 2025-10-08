import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/verification_model.dart';
import '../services/verification_service.dart';

class AdminVerificationScreen extends StatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  State<AdminVerificationScreen> createState() => _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen> {
  List<VerificationRequest> _requests = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasNextPage = false;

  @override
  void initState() {
    super.initState();
    _loadVerificationRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Verification Requests'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVerificationRequests,
          ),
        ],
      ),
      body: _isLoading && _requests.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadVerificationRequests,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length + (_hasNextPage ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _requests.length) {
                        return _buildLoadMoreButton();
                      }
                      return _buildVerificationRequestCard(_requests[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No verification requests',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All verification requests have been processed',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadVerificationRequests,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationRequestCard(VerificationRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _getStatusColor(request.status),
                  child: Icon(
                    _getStatusIcon(request.status),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.personalInfo.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${request.type.toUpperCase()} • ${request.status.toUpperCase()}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(request.status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Personal Information
            _buildInfoSection('Personal Information', [
              _buildInfoRow('Full Name', request.personalInfo.fullName),
              _buildInfoRow('Phone', request.personalInfo.phoneNumber),
              _buildInfoRow('Address', request.personalInfo.address),
              _buildInfoRow('Date of Birth', request.personalInfo.dateOfBirth.toString().split(' ')[0]),
            ]),

            // Social Media Profiles
            if (request.socialMediaProfiles.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoSection('Social Media Profiles', [
                ...request.socialMediaProfiles.map((profile) => 
                  _buildSocialMediaProfile(profile)
                ),
              ]),
            ],

            // Reason
            const SizedBox(height: 16),
            _buildInfoSection('Reason', [
              Text(
                request.reason,
                style: const TextStyle(fontSize: 14),
              ),
            ]),

            // Additional Info
            if (request.additionalInfo.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoSection('Additional Information', [
                Text(
                  request.additionalInfo,
                  style: const TextStyle(fontSize: 14),
                ),
              ]),
            ],

            // Timestamps
            const SizedBox(height: 16),
            _buildInfoSection('Timestamps', [
              _buildInfoRow('Created', request.createdAt.toString().split('.')[0]),
              if (request.reviewedAt != null)
                _buildInfoRow('Reviewed', request.reviewedAt.toString().split('.')[0]),
            ]),

            // Actions
            if (request.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveRequest(request),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectRequest(request),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaProfile(SocialMediaProfile profile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(
            _getPlatformIcon(profile.platform),
            color: _getPlatformColor(profile.platform),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.platform.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '@${profile.username}',
                  style: const TextStyle(fontSize: 11),
                ),
                Text(
                  '${profile.followers} followers',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (profile.verified)
            Icon(
              Icons.verified,
              color: Colors.blue[600],
              size: 16,
            ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ElevatedButton(
          onPressed: _loadMoreRequests,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Load More'),
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt;
      case 'twitter':
        return Icons.alternate_email;
      case 'facebook':
        return Icons.facebook;
      case 'youtube':
        return Icons.play_circle;
      default:
        return Icons.public;
    }
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return Colors.purple;
      case 'twitter':
        return Colors.blue;
      case 'facebook':
        return Colors.indigo;
      case 'youtube':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _loadVerificationRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      final token = adminProvider.adminToken;

      if (token == null) {
        setState(() {
          _error = 'Admin authentication required';
        });
        return;
      }

      final response = await VerificationService.getVerificationRequests(
        token: token,
        page: 1,
        limit: 10,
      );

      if (response.success && response.data != null) {
        setState(() {
          _requests = response.data!.requests;
          _currentPage = response.data!.pagination.currentPage;
          _hasNextPage = response.data!.pagination.hasNextPage;
        });
      } else {
        setState(() {
          _error = 'Failed to load verification requests';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading requests: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreRequests() async {
    if (!_hasNextPage || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      final token = adminProvider.adminToken;

      if (token == null) return;

      final response = await VerificationService.getVerificationRequests(
        token: token,
        page: _currentPage + 1,
        limit: 10,
      );

      if (response.success && response.data != null) {
        setState(() {
          _requests.addAll(response.data!.requests);
          _currentPage = response.data!.pagination.currentPage;
          _hasNextPage = response.data!.pagination.hasNextPage;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading more requests: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _approveRequest(VerificationRequest request) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _ApprovalDialog(),
    );

    if (result != null) {
      try {
        final adminProvider = Provider.of<AdminProvider>(context, listen: false);
        final token = adminProvider.adminToken;

        if (token == null) return;

        final response = await VerificationService.approveVerification(
          requestId: request.id,
          badgeType: result['badgeType']!,
          expiresAt: result['expiresAt']!,
          token: token,
        );

        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification approved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadVerificationRequests();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to approve: ${response.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving verification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(VerificationRequest request) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _RejectionDialog(),
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        final adminProvider = Provider.of<AdminProvider>(context, listen: false);
        final token = adminProvider.adminToken;

        if (token == null) return;

        final response = await VerificationService.rejectVerification(
          requestId: request.id,
          reason: reason,
          token: token,
        );

        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification rejected successfully!'),
              backgroundColor: Colors.orange,
            ),
          );
          _loadVerificationRequests();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to reject: ${response.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting verification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _ApprovalDialog extends StatefulWidget {
  @override
  State<_ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends State<_ApprovalDialog> {
  final _formKey = GlobalKey<FormState>();
  String _selectedBadgeType = 'blue_tick';
  DateTime _expiresAt = DateTime.now().add(const Duration(days: 365));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Approve Verification'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedBadgeType,
              decoration: const InputDecoration(labelText: 'Badge Type'),
              items: const [
                DropdownMenuItem(value: 'blue_tick', child: Text('Blue Tick')),
                DropdownMenuItem(value: 'gold_tick', child: Text('Gold Tick')),
                DropdownMenuItem(value: 'verified', child: Text('Verified')),
              ],
              onChanged: (value) => setState(() => _selectedBadgeType = value!),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Expiration Date'),
              subtitle: Text(_expiresAt.toString().split(' ')[0]),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _expiresAt,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                );
                if (date != null) {
                  setState(() => _expiresAt = date);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'badgeType': _selectedBadgeType,
              'expiresAt': _expiresAt.toIso8601String().split('T')[0],
            });
          },
          child: const Text('Approve'),
        ),
      ],
    );
  }
}

class _RejectionDialog extends StatefulWidget {
  @override
  State<_RejectionDialog> createState() => _RejectionDialogState();
}

class _RejectionDialogState extends State<_RejectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject Verification'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText: 'Please provide a reason for rejecting this verification request',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please provide a reason';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _reasonController.text);
            }
          },
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
