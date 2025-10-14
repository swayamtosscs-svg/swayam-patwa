import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/highlight_model.dart';
import '../services/highlight_service.dart';
import '../widgets/highlight_card.dart';
import 'create_highlight_screen.dart';
import 'highlight_viewer_screen.dart';

class HighlightsScreen extends StatefulWidget {
  const HighlightsScreen({Key? key}) : super(key: key);

  @override
  State<HighlightsScreen> createState() => _HighlightsScreenState();
}

class _HighlightsScreenState extends State<HighlightsScreen> {
  List<Highlight> highlights = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  String? token;
  int currentPage = 1;
  bool hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadToken();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('auth_token');
      if (storedToken != null) {
        setState(() {
          token = storedToken;
        });
        await _loadHighlights();
      } else {
        setState(() {
          hasError = true;
          errorMessage = 'No authentication token found';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = 'Error loading token: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadHighlights({bool refresh = false}) async {
    if (token == null) return;

    try {
      setState(() {
        if (refresh) {
          currentPage = 1;
          hasMoreData = true;
        }
        if (currentPage == 1) {
          isLoading = true;
        }
        hasError = false;
      });

      final response = await HighlightService.getHighlights(
        token: token!,
        page: currentPage,
        limit: 20,
      );

      if (response.success) {
        setState(() {
          if (refresh || currentPage == 1) {
            highlights = response.highlights;
          } else {
            highlights.addAll(response.highlights);
          }
          isLoading = false;
          hasMoreData = response.highlights.length == 20;
        });
      } else {
        setState(() {
          hasError = true;
          errorMessage = response.message;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = 'Error loading highlights: $e';
        isLoading = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!isLoading && hasMoreData) {
        setState(() {
          currentPage++;
        });
        _loadHighlights();
      }
    }
  }

  Future<void> _refreshHighlights() async {
    await _loadHighlights(refresh: true);
  }

  Future<void> _createHighlight() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateHighlightScreen(),
      ),
    );

    if (result == true) {
      await _refreshHighlights();
    }
  }

  Future<void> _deleteHighlight(Highlight highlight) async {
    if (token == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Highlight'),
        content: Text('Are you sure you want to delete "${highlight.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await HighlightService.deleteHighlight(
          highlightId: highlight.id,
          token: token!,
        );

        if (response.success) {
          setState(() {
            highlights.removeWhere((h) => h.id == highlight.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Highlight deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete highlight: ${response.message}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting highlight: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Highlights'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createHighlight,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading && highlights.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (hasError && highlights.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading highlights',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshHighlights,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (highlights.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.collections_bookmark_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No highlights yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first highlight to organize your stories',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _createHighlight,
              icon: const Icon(Icons.add),
              label: const Text('Create Highlight'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshHighlights,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: highlights.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == highlights.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final highlight = highlights[index];
          return HighlightCard(
            highlight: highlight,
            onDelete: () => _deleteHighlight(highlight),
            onTap: () => _viewHighlight(highlight),
          );
        },
      ),
    );
  }

  void _viewHighlight(Highlight highlight) {
    // Navigate to highlight viewer to show stories
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HighlightViewerScreen(highlight: highlight),
      ),
    );
  }
}


