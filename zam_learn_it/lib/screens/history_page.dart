import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'translate_screen.dart';
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

  // Settings state
  bool _isDarkMode = false;
  double _brightness = 0.4;

  final Color _lightGreen = const Color(0xFF81C784);  // Light Green
  final Color _darkGreen = const Color(0xFF388E3C);   // Dark Green for accents

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadLearnedTranslations();
    _searchController.addListener(_filterHistory);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterHistory);
    _searchController.dispose();
    super.dispose();
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.settings, color: Colors.blue),
              SizedBox(width: 8),
              Text('Settings'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Dark Mode',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.light_mode, size: 20, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Switch(
                        value: _isDarkMode,
                        onChanged: (value) {
                          setDialogState(() {
                            _isDarkMode = value;
                          });
                          setState(() {
                            _isDarkMode = value;
                          });
                        },
                        activeThumbColor: Colors.green,
                      ),
                    ),
                    const Icon(Icons.dark_mode, size: 20),
                  ],
                ),
                const SizedBox(height: 24),
                
                const Text(
                  'Screen Brightness',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.brightness_low, size: 20),
                    Expanded(
                      child: Slider(
                        value: _brightness,
                        min: 0.2,
                        max: 0.8,
                        divisions: 10,
                        onChanged: (value) {
                          setDialogState(() {
                            _brightness = value;
                          });
                          setState(() {
                            _brightness = value;
                          });
                        },
                        activeColor: Colors.green,
                      ),
                    ),
                    const Icon(Icons.brightness_high, size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Brightness: ${((_brightness - 0.2) / 0.6 * 100).toInt()}%',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await _firestoreService.getHistoryOnce();
      setState(() {
        _history = history;
        _filteredHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading history: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterHistory() {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() {
        _filteredHistory = _history;
      });
    } else {
      setState(() {
        _filteredHistory = _history.where((item) =>
            (item['original']?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
            (item['translated']?.toLowerCase().contains(query.toLowerCase()) ?? false)).toList();
      });
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

  Future<void> _loadLearnedTranslations() async {
    setState(() => _isLoadingLearned = true);
    try {
      final suggestions = await _firestoreService.getGlobalSuggestions();
      setState(() {
        _learnedTranslations = suggestions;
        _isLoadingLearned = false;
      });
    } catch (e) {
      print('Error loading learned translations: $e');
      setState(() => _isLoadingLearned = false);
    }
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
                                        'Suggest improvements to help the community!',
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
                                              style: const TextStyle(fontSize: 13, color: Colors.teal),
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
                                                        style: const TextStyle(fontSize: 10, color: Colors.teal),
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
                                                        style: const TextStyle(fontSize: 10, color: Colors.blue),
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
    // Keep history page background white (no grey/black tint overlay).
    final overlayColor = Colors.transparent;


    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(color: overlayColor),
          SafeArea(
            child: Column(
              children: [
                // TOP BAR with Settings - Light Green background, centered title
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: _lightGreen,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Back to Translate
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TranslateScreen()),
                          );
                        },
                      ),
                      Expanded(
                        child: Center(

                          child: const Text(
                            "History",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Community Button
                          GestureDetector(
                            onTap: _showLearnedTranslations,
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.group,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Community',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Delete All Button
                          if (_history.isNotEmpty)
                            GestureDetector(
                              onTap: _isDeleting ? null : _clearAllHistory,
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.delete_sweep,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Delete All',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(width: 12),
                          // Refresh Button
                          GestureDetector(
                            onTap: _isLoading ? null : _loadHistory,
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Refresh',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Settings Button
                          IconButton(
                            icon: const Icon(Icons.settings, color: Colors.white, size: 24),
                            onPressed: () => _showSettingsDialog(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // SEARCH BAR
                Container(
                  margin: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search translations...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                _filterHistory();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                
                // MAIN CONTENT
                Expanded(
                  child: _buildBody(),
                ),
              ],
            ),
          ),
        ],
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
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
                _filterHistory();
              },
              child: const Text('Clear search'),
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
                                  color: isLearned ? Colors.teal.withValues(alpha: 0.2) : _lightGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'ORIGINAL',
                                  style: TextStyle(fontSize: 12, color: isLearned ? Colors.teal : _darkGreen),
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
                                child: Text(
                                  'TRANSLATION (${item['language']?.toUpperCase() ?? 'UNKNOWN'})',
                                  style: TextStyle(fontSize: 12, color: isLearned ? Colors.teal : _darkGreen),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.copy, size: 16, color: _darkGreen),
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
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(item['timestamp']),
                                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                              ),
                              if (isLearned) ...[
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Community',
                                    style: TextStyle(fontSize: 9, color: Colors.teal),
                                  ),
                                ),
                              ],
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