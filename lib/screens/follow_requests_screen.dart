import 'package:flutter/material.dart';
import '../models/follow_request_model.dart';
import '../services/follow_request_service.dart';
import '../widgets/follow_request_item_widget.dart';

class FollowRequestsScreen extends StatefulWidget {
  const FollowRequestsScreen({super.key});

  @override
  State<FollowRequestsScreen> createState() => _FollowRequestsScreenState();
}

class _FollowRequestsScreenState extends State<FollowRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<FollowRequest> _pendingRequests = [];
  List<FollowRequest> _sentRequests = [];
  List<FollowRequest> _samplePendingRequests = [];
  List<FollowRequest> _sampleSentRequests = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _createSampleData();
    _loadFollowRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _createSampleData() {
    // Create sample pending requests (received)
    _samplePendingRequests = [
      FollowRequest(
        id: 'sample_req_1',
        fromUserId: '68d13b4da564ecdd0668a03',
        fromUsername: 'dhani',
        fromUserAvatar: null,
        toUserId: 'current_user',
        toUsername: 'you',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'pending',
      ),
      FollowRequest(
        id: 'sample_req_2',
        fromUserId: '68c98967a921a001da9787b3',
        fromUsername: 'ram',
        fromUserAvatar: null,
        toUserId: 'current_user',
        toUsername: 'you',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: 'pending',
      ),
      FollowRequest(
        id: 'sample_req_3',
        fromUserId: '68b53b03f09b98a6dcded481',
        fromUsername: 'sita',
        fromUserAvatar: null,
        toUserId: 'current_user',
        toUsername: 'you',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        status: 'pending',
      ),
    ];

    // Create sample sent requests
    _sampleSentRequests = [
      FollowRequest(
        id: 'sample_req_4',
        fromUserId: 'current_user',
        fromUsername: 'you',
        fromUserAvatar: null,
        toUserId: '68d13b4da564ecdd0668a03',
        toUsername: 'krishna',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        status: 'pending',
      ),
      FollowRequest(
        id: 'sample_req_5',
        fromUserId: 'current_user',
        fromUsername: 'you',
        fromUserAvatar: null,
        toUserId: '68c98967a921a001da9787b3',
        toUsername: 'radha',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        status: 'pending',
      ),
    ];
  }

  Future<void> _loadFollowRequests({bool loadMore = false}) async {
    if (_isLoading && !loadMore) return;
    if (_isLoadingMore && loadMore) return;

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _currentPage = 1;
        _hasMoreData = true;
      }
    });

    try {
      final page = loadMore ? _currentPage + 1 : 1;
      
      // Load pending requests (received)
      final pendingRequests = await FollowRequestService.getPendingRequests(
        page: page,
        limit: _pageSize,
      );

      // Load sent requests
      final sentRequests = await FollowRequestService.getSentRequests(
        page: page,
        limit: _pageSize,
      );

      if (mounted) {
        setState(() {
          if (loadMore) {
            _pendingRequests.addAll(pendingRequests);
            _sentRequests.addAll(sentRequests);
            _currentPage = page;
          } else {
            _pendingRequests = pendingRequests;
            _sentRequests = sentRequests;
            _currentPage = 1;
          }
          
          _hasMoreData = pendingRequests.length == _pageSize || sentRequests.length == _pageSize;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading follow requests: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleAcceptRequest(FollowRequest request) async {
    try {
      // Check if this is a sample request
      final isSampleRequest = request.id.startsWith('sample_req_');
      
      if (isSampleRequest) {
        // For sample requests, simulate the follow action without API calls
        setState(() {
          _samplePendingRequests.removeWhere((r) => r.id == request.id);
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
        if (success && mounted) {
          // Remove from pending requests
          setState(() {
            _pendingRequests.removeWhere((r) => r.id == request.id);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Accepted follow request from ${request.fromUsername}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRejectRequest(FollowRequest request) async {
    try {
      // Check if this is a sample request
      final isSampleRequest = request.id.startsWith('sample_req_');
      
      if (isSampleRequest) {
        // For sample requests, just simulate rejection
        setState(() {
          _samplePendingRequests.removeWhere((r) => r.id == request.id);
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
        if (success && mounted) {
          // Remove from pending requests
          setState(() {
            _pendingRequests.removeWhere((r) => r.id == request.id);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rejected follow request from ${request.fromUsername}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleCancelRequest(FollowRequest request) async {
    try {
      final success = await FollowRequestService.cancelFollowRequest(request.id);
      if (success && mounted) {
        // Remove from sent requests
        setState(() {
          _sentRequests.removeWhere((r) => r.id == request.id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cancelled follow request to ${request.toUsername}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          'Follow Requests',
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4A2C2A),
          unselectedLabelColor: const Color(0xFF999999),
          indicatorColor: const Color(0xFF4A2C2A),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pending'),
                  if (_pendingRequests.isNotEmpty || _samplePendingRequests.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        (_pendingRequests.isNotEmpty ? _pendingRequests.length : _samplePendingRequests.length).toString(),
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
                  const Text('Sent'),
                  if (_sentRequests.isNotEmpty || _sampleSentRequests.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        (_sentRequests.isNotEmpty ? _sentRequests.length : _sampleSentRequests.length).toString(),
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestsList(_pendingRequests.isEmpty ? _samplePendingRequests : _pendingRequests, isPending: true),
          _buildRequestsList(_sentRequests.isEmpty ? _sampleSentRequests : _sentRequests, isPending: false),
        ],
      ),
    );
  }

  Widget _buildRequestsList(List<FollowRequest> requests, {required bool isPending}) {
    if (_isLoading && requests.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6366F1),
        ),
      );
    }

    if (requests.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending ? Icons.person_add_disabled : Icons.send,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              isPending ? 'No pending requests' : 'No sent requests',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPending 
                ? 'When someone sends you a follow request, it\'ll appear here'
                : 'Follow requests you send will appear here',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF999999),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadFollowRequests(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == requests.length) {
            // Load more indicator
            if (_isLoadingMore) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    color: Color(0xFF6366F1),
                  ),
                ),
              );
            } else if (_hasMoreData) {
              // Load more trigger
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadFollowRequests(loadMore: true);
              });
              return const SizedBox.shrink();
            } else {
              return const SizedBox.shrink();
            }
          }

          final request = requests[index];
          return FollowRequestItemWidget(
            request: request,
            isPending: isPending,
            onAccept: isPending ? () => _handleAcceptRequest(request) : null,
            onReject: isPending ? () => _handleRejectRequest(request) : null,
            onCancel: !isPending ? () => _handleCancelRequest(request) : null,
          );
        },
      ),
    );
  }
}
