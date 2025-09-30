import 'package:flutter/material.dart';
import '../models/follow_request_model.dart';
import '../widgets/follow_request_item_widget.dart';
import '../services/follow_request_service.dart';

/// Test screen to demonstrate follow request functionality
/// This creates sample follow requests to show how they appear in the UI
class TestFollowRequestDemo extends StatefulWidget {
  const TestFollowRequestDemo({super.key});

  @override
  State<TestFollowRequestDemo> createState() => _TestFollowRequestDemoState();
}

class _TestFollowRequestDemoState extends State<TestFollowRequestDemo>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<FollowRequest> _pendingRequests = [];
  List<FollowRequest> _sentRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRealAndSampleData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRealAndSampleData() async {
    try {
      // Load real follow requests from server
      final realPendingRequests = await FollowRequestService.getPendingRequests();
      final realSentRequests = await FollowRequestService.getSentRequests();
      
      // Create sample data
      final samplePendingRequests = _createSamplePendingRequests();
      final sampleSentRequests = _createSampleSentRequests();
      
      // Combine real and sample data
      setState(() {
        _pendingRequests = [...realPendingRequests, ...samplePendingRequests];
        _sentRequests = [...realSentRequests, ...sampleSentRequests];
      });
      
      print('Loaded ${realPendingRequests.length} real pending requests and ${samplePendingRequests.length} sample pending requests');
      print('Loaded ${realSentRequests.length} real sent requests and ${sampleSentRequests.length} sample sent requests');
    } catch (e) {
      print('Error loading real follow requests: $e');
      // Fallback to sample data only
      _createSampleData();
    }
  }

  List<FollowRequest> _createSamplePendingRequests() {
    return [
      FollowRequest(
        id: 'demo_req_1',
        fromUserId: '68d13b4da564ecdd0668a03', // Real user ID from token
        fromUsername: 'dhani',
        fromUserAvatar: null,
        toUserId: 'current_user',
        toUsername: 'you',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'pending',
      ),
      FollowRequest(
        id: 'demo_req_2',
        fromUserId: '68c98967a921a001da9787b3', // Real user ID from tests
        fromUsername: 'ram',
        fromUserAvatar: null,
        toUserId: 'current_user',
        toUsername: 'you',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: 'pending',
      ),
      FollowRequest(
        id: 'demo_req_3',
        fromUserId: '68b53b03f09b98a6dcded481', // Real user ID from tests
        fromUsername: 'sita',
        fromUserAvatar: null,
        toUserId: 'current_user',
        toUsername: 'you',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        status: 'pending',
      ),
    ];
  }

  List<FollowRequest> _createSampleSentRequests() {
    return [
      FollowRequest(
        id: 'demo_req_4',
        fromUserId: 'current_user',
        fromUsername: 'you',
        fromUserAvatar: null,
        toUserId: '68d13b4da564ecdd0668a03', // Real user ID from token
        toUsername: 'krishna',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        status: 'pending',
      ),
      FollowRequest(
        id: 'demo_req_5',
        fromUserId: 'current_user',
        fromUsername: 'you',
        fromUserAvatar: null,
        toUserId: '68c98967a921a001da9787b3', // Real user ID from tests
        toUsername: 'radha',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        status: 'pending',
      ),
    ];
  }

  void _createSampleData() {
    // Create sample pending requests (received)
    _pendingRequests = [
      FollowRequest(
        id: 'req_1',
        fromUserId: 'user_dhani',
        fromUsername: 'dhani',
        fromUserAvatar: null,
        toUserId: 'current_user',
        toUsername: 'you',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'pending',
      ),
      FollowRequest(
        id: 'req_2',
        fromUserId: 'user_ram',
        fromUsername: 'ram',
        fromUserAvatar: null,
        toUserId: 'current_user',
        toUsername: 'you',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: 'pending',
      ),
      FollowRequest(
        id: 'req_3',
        fromUserId: 'user_sita',
        fromUsername: 'sita',
        fromUserAvatar: null,
        toUserId: 'current_user',
        toUsername: 'you',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        status: 'pending',
      ),
    ];

    // Create sample sent requests
    _sentRequests = [
      FollowRequest(
        id: 'req_4',
        fromUserId: 'current_user',
        fromUsername: 'you',
        fromUserAvatar: null,
        toUserId: 'user_krishna',
        toUsername: 'krishna',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        status: 'pending',
      ),
      FollowRequest(
        id: 'req_5',
        fromUserId: 'current_user',
        fromUsername: 'you',
        fromUserAvatar: null,
        toUserId: 'user_radha',
        toUsername: 'radha',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        status: 'pending',
      ),
    ];

    setState(() {});
  }

  Future<void> _handleAcceptRequest(FollowRequest request) async {
    try {
      // Check if this is a demo request or real request
      final isDemoRequest = request.id.startsWith('demo_req_');
      
      if (isDemoRequest) {
        // For demo requests, simulate the follow action without API calls
        setState(() {
          _pendingRequests.removeWhere((r) => r.id == request.id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Now following ${request.fromUsername}!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // For real requests, use the actual API
        final success = await FollowRequestService.acceptFollowRequest(request.id);
        
        if (success) {
          setState(() {
            _pendingRequests.removeWhere((r) => r.id == request.id);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Accepted follow request from ${request.fromUsername} - Now following!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to accept follow request from ${request.fromUsername}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error accepting request: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleRejectRequest(FollowRequest request) async {
    try {
      // Check if this is a demo request or real request
      final isDemoRequest = request.id.startsWith('demo_req_');
      
      if (isDemoRequest) {
        // For demo requests, just simulate rejection (no real API call needed)
        setState(() {
          _pendingRequests.removeWhere((r) => r.id == request.id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Rejected follow request from ${request.fromUsername}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // For real requests, use the actual API
        final success = await FollowRequestService.rejectFollowRequest(request.id);
        
        if (success) {
          setState(() {
            _pendingRequests.removeWhere((r) => r.id == request.id);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Rejected follow request from ${request.fromUsername}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to reject follow request from ${request.fromUsername}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error rejecting request: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleCancelRequest(FollowRequest request) async {
    try {
      // Check if this is a demo request or real request
      final isDemoRequest = request.id.startsWith('demo_req_');
      
      if (isDemoRequest) {
        // For demo requests, just simulate cancellation
        setState(() {
          _sentRequests.removeWhere((r) => r.id == request.id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Cancelled follow request to ${request.toUsername}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // For real requests, use the actual API
        final success = await FollowRequestService.cancelFollowRequest(request.id);
        
        if (success) {
          setState(() {
            _sentRequests.removeWhere((r) => r.id == request.id);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Cancelled follow request to ${request.toUsername}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to cancel follow request to ${request.toUsername}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error cancelling request: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EBE1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0EBE1),
        elevation: 0,
        title: const Text(
          'Follow Requests Demo',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: _loadRealAndSampleData,
            icon: const Icon(Icons.refresh, color: Colors.black),
            tooltip: 'Refresh Real Data',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          indicatorColor: const Color(0xFF4A2C2A),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pending', style: TextStyle(color: Colors.black)),
                  if (_pendingRequests.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _pendingRequests.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sent', style: TextStyle(color: Colors.black)),
                  if (_sentRequests.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _sentRequests.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Demo notice
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is a demo with sample data. Real API calls will be attempted but may fail if users don\'t exist.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsList(_pendingRequests, true),
                _buildRequestsList(_sentRequests, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList(List<FollowRequest> requests, bool isPending) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_disabled,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isPending ? 'No pending requests' : 'No sent requests',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPending
                  ? 'When someone sends you a follow request, it\'ll appear here'
                  : 'Follow requests you send will appear here',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return FollowRequestItemWidget(
          request: request,
          isPending: isPending,
          onAccept: isPending ? () => _handleAcceptRequest(request) : null,
          onReject: isPending ? () => _handleRejectRequest(request) : null,
          onCancel: !isPending ? () => _handleCancelRequest(request) : null,
        );
      },
    );
  }
}
