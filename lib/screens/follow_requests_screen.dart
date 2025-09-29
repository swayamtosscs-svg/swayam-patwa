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
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFollowRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                  if (_pendingRequests.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
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
                  const Text('Sent'),
                  if (_sentRequests.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestsList(_pendingRequests, isPending: true),
          _buildRequestsList(_sentRequests, isPending: false),
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
