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
  double _fontSize = 14.0;

  final Color _lightGreen = const Color(0xFF81C784);
  final Color _darkGreen = const Color(0xFF388E3C);

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
                        activeColor: Colors.green,
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
                const SizedBox(height: 24),
                const Text(
                  'Font Size',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.text_fields, size: 20),
                    Expanded(
                      child: Slider(
                        value: _fontSize,
                        min: 12.0,
                        max: 22.0,
                        divisions: 10,
                        onChanged: (value) {
                          setDialogState(() {
                            _fontSize = value;
                          });
                          setState(() {
                            _fontSize = value;
                          });
                        },
                        activeColor: Colors.green,
                      ),
                    ),
                    const Icon(Icons.format_size, size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Text size: ${_fontSize.toStringAsFixed(0)}',
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
    final modalCardColor = _isDarkMode ? Colors.grey[850]! : Colors.white;
    final modalTextColor = _isDarkMode ? Colors.white : Colors.black87;
    final modalLabelFontSize = (_fontSize * 0.9).clamp(11.0, 18.0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.teal,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Community Translations',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Row(
                              children: [
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
                                        color: modalCardColor,
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
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: _fontSize,
                                              color: modalTextColor,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 4),
                                              Text(
                                                item['suggested'] ?? '',
                                                style: TextStyle(fontSize: _fontSize, color: Colors.teal),
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
                                                          style: TextStyle(fontSize: modalLabelFontSize * 0.9, color: Colors.teal),
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
                                                          style: TextStyle(fontSize: modalLabelFontSize * 0.9, color: Colors.blue),
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
                  ),
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
    final brightnessFactor = ((_brightness - 0.2) / 0.6).clamp(0.0, 1.0);
    final backgroundColor = _isDarkMode
        ? Color.lerp(Colors.black, Colors.grey[850]!, brightnessFactor)!
        : Color.lerp(Colors.white, Colors.grey[100]!, brightnessFactor)!;
    final surfaceColor = _isDarkMode ? Colors.grey[900]! : Colors.grey.shade50;
    final cardColor = _isDarkMode ? Colors.grey[850]! : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = _isDarkMode ? Colors.grey[300]! : Colors.grey.shade700;
    final labelFontSize = (_fontSize * 0.9).clamp(11.0, 18.0);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // TOP BAR with title ABOVE buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: _lightGreen,
              child: Column(
                children: [
                  // Title row with back button
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const TranslateScreen()),
                          );
                        },
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            "History",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.home, color: Colors.white, size: 24),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const TranslateScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Action buttons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: _showLearnedTranslations,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.group, color: Colors.white, size: 22),
                            const SizedBox(height: 2),
                            Text(
                              'Community',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: labelFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (_history.isNotEmpty)
                        GestureDetector(
                          onTap: _isDeleting ? null : _clearAllHistory,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.delete_sweep, color: Colors.white, size: 22),
                              const SizedBox(height: 2),
                              Text(
                                'Delete All',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: labelFontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: _isLoading ? null : _loadHistory,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.refresh, color: Colors.white, size: 22),
                            const SizedBox(height: 2),
                            Text(
                              'Refresh',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: labelFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
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
                style: TextStyle(fontSize: _fontSize, color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search translations...',
                  hintStyle: TextStyle(color: secondaryTextColor),
                  prefixIcon: Icon(Icons.search, color: secondaryTextColor),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: secondaryTextColor),
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
                  fillColor: surfaceColor,
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
    );
  }

  Widget _buildBody() {
    final textColor = _isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = _isDarkMode ? Colors.grey[300]! : Colors.grey.shade700;
    final cardColor = _isDarkMode ? Colors.grey[850]! : Colors.white;
    final fontSize = _fontSize;

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
            Icon(Icons.search_off, size: 64, color: secondaryTextColor),
            const SizedBox(height: 16),
            Text(
              'No results for "${_searchController.text}"',
              style: TextStyle(fontSize: fontSize, color: secondaryTextColor),
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
              style: TextStyle(fontSize: fontSize, color: secondaryTextColor),
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
              color: cardColor,
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
                                  style: TextStyle(
                                    fontSize: fontSize * 0.85,
                                    color: isLearned ? Colors.teal : _darkGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['original'] ?? 'Unknown',
                            style: TextStyle(fontSize: fontSize, color: textColor),
                          ),
                        ],
                      ),
                    ),
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
                                  style: TextStyle(
                                    fontSize: fontSize * 0.85,
                                    color: isLearned ? Colors.teal : _darkGreen,
                                  ),
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
                              fontSize: fontSize,
                              fontWeight: isLearned ? FontWeight.w600 : FontWeight.w500,
                              color: isLearned ? Colors.teal.shade800 : textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 12, color: secondaryTextColor),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(item['timestamp']),
                                style: TextStyle(fontSize: fontSize * 0.75, color: secondaryTextColor),
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