import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firestore_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _filteredHistory = [];
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _learnedTranslations = [];
  bool _isLoading = true;
  bool _isDeleting = false;
  bool _isLoadingLearned = false;
  bool _isSearching = false;

  final Color _lightBlue = const Color(0xFF87CEEB);
  final Color _darkBlue = const Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadLearnedTranslations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await _firestoreService.getHistoryOnce();
      setState(() {
        _history = history;
        _filteredHistory = history;
        _isSearching = false;
        _searchController.clear();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading history: $e');
      setState(() => _isLoading = false);
    }
  }

  void _runFilter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredHistory = _history;
      } else {
        _filteredHistory = _history.where((item) =>
            (item['original']?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
            (item['translated']?.toLowerCase().contains(query.toLowerCase()) ?? false)).toList();
      }
    });
  }

  Future<void> _loadLearnedTranslations() async {
    setState(() => _isLoadingLearned = true);
    try {
      // Get global suggestions from ALL users
      final suggestions = await _firestoreService.getGlobalSuggestions();
      print('📚 Loaded ${suggestions.length} community suggestions');
      setState(() {
        _learnedTranslations = suggestions;
        _isLoadingLearned = false;
      });
    } catch (e) {
      print('Error loading learned translations: $e');
      setState(() => _isLoadingLearned = false);
    }
  }

  Future<void> _deleteItem(String docId) async {
    setState(() => _isDeleting = true);
    await _firestoreService.deleteTranslation(docId);
    await _loadHistory();
    setState(() => _isDeleting = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Translation deleted'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _clearAllHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text('Are you sure you want to delete all translations? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() => _isDeleting = true);
      await _firestoreService.clearAllHistory();
      await _loadHistory();
      setState(() => _isDeleting = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All history cleared'), duration: Duration(seconds: 2)),
      );
    }
  }

  void _showLearnedTranslations() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Community Translations',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            onPressed: () async {
                              setModalState(() => _isLoadingLearned = true);
                              await _loadLearnedTranslations();
                              setModalState(() => _isLoadingLearned = false);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _isLoadingLearned
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('Loading community translations...'),
                                ],
                              ),
                            )
                          : _learnedTranslations.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.auto_awesome, size: 48, color: Colors.grey),
                                      SizedBox(height: 16),
                                      Text(
                                        'No community translations yet',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'When you suggest improvements, they appear here!\nTap "Suggest a Better Translation" on the translate screen.',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  controller: scrollController,
                                  itemCount: _learnedTranslations.length,
                                  itemBuilder: (context, index) {
                                    final item = _learnedTranslations[index];
                                    return Card(
                                      margin: const EdgeInsets.all(8),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.teal.withValues(alpha: 0.2),
                                          child: const Icon(
                                            Icons.group,
                                            color: Colors.teal,
                                            size: 20,
                                          ),
                                        ),
                                        title: Text(
                                          item['original'] ?? 'Unknown',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Text(
                                              item['suggested'] ?? '',
                                              style: const TextStyle(fontSize: 14, color: Colors.teal),
                                            ),
                                            const SizedBox(height: 4),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.teal.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.trending_up, size: 10, color: Colors.teal),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Confidence: ${item['confidence'] ?? 0}',
                                                        style: const TextStyle(fontSize: 14, color: Colors.teal),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.repeat, size: 10, color: Colors.blue),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Used: ${item['times_suggested'] ?? 0} times',
                                                        style: const TextStyle(fontSize: 14, color: Colors.blue),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.copy, size: 18, color: Colors.teal),
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: item['suggested'] ?? ''));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Copied community translation!'),
                                                duration: Duration(seconds: 1),
                                              ),
                                            );
                                          },
                                        ),
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Community Translation'),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Original: ${item['original']}',
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text('Suggested: ${item['suggested']}'),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Confidence: ${item['confidence']} | Used ${item['times_suggested']} times',
                                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                  ),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('Close'),
                                                ),
                                                ElevatedButton.icon(
                                                  onPressed: () {
                                                    Clipboard.setData(ClipboardData(text: item['suggested'] ?? ''));
                                                    Navigator.pop(context);
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Copied!'), duration: Duration(seconds: 1)),
                                                    );
                                                  },
                                                  icon: const Icon(Icons.copy, size: 16),
                                                  label: const Text('Copy'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null) return 'Unknown date';
    try {
      final date = DateTime.parse(timestamp);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                cursorColor: Colors.white,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Search translations...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: _runFilter,
              )
            : const Text(
                'History',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        backgroundColor: _lightBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // SEARCH TOGGLE BUTTON
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    _filteredHistory = _history;
                  }
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isSearching ? Icons.close : Icons.search,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          // COMMUNITY BUTTON
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: _showLearnedTranslations,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.group,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Community',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_history.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GestureDetector(
                onTap: _isDeleting ? null : _clearAllHistory,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.delete_sweep,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Delete All',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: _isLoading ? null : _loadHistory,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Refresh',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading history...'),
          ],
        ),
      );
    }

    if (_history.isNotEmpty && _filteredHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No results for "${_searchController.text}"',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No translations yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Translate some words to see them here',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.translate),
              label: const Text('Go Translate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredHistory.length,
      itemBuilder: (context, index) {
        final item = _filteredHistory[index];
        final isLearned = item['is_user_suggestion'] == true;
        return Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Dismissible(
                key: Key(item['id']),
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _deleteItem(item['id']),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ORIGINAL TEXT SECTION
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isLearned ? Colors.teal.shade50 : Colors.grey.shade50,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isLearned ? Colors.teal.withValues(alpha: 0.2) : _lightBlue.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'ORIGINAL',
                                      style: TextStyle(fontSize: 14, color: isLearned ? Colors.teal : _darkBlue),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['original'] ?? 'Unknown',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    
                    // TRANSLATED TEXT SECTION
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isLearned ? Colors.teal.shade100 : Colors.green[50],
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isLearned ? Colors.teal.withValues(alpha: 0.3) : Colors.green[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'TRANSLATION (${item['language']?.toUpperCase() ?? 'UNKNOWN'})',
                                      style: TextStyle(fontSize: 14, color: isLearned ? Colors.teal : Colors.green[800]),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.copy, size: 16, color: _darkBlue),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: item['translated'] ?? ''));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Copied!'), duration: Duration(seconds: 1)),
                                  );
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['translated'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isLearned ? FontWeight.w600 : FontWeight.w500,
                              color: isLearned ? Colors.teal.shade800 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12, // Horizontal spacing between items
                            runSpacing: 8, // Vertical spacing between lines
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min, // Important for Wrap to size correctly
                                children: [
                                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(item['timestamp']),
                                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              if (isLearned)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text( // Changed from Row to Text as it's a single element
                                    'Community',
                                    style: TextStyle(fontSize: 14, color: Colors.teal),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}