import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/firestore_service.dart';
import 'package:share_plus/share_plus.dart' if (dart.library.html) 'package:share_plus/share_plus_web.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _filteredHistory = [];
  bool _isLoading = true;
  bool _isDeleting = false;
  final TextEditingController _searchController = TextEditingController();

  final Color _lightBlue = const Color(0xFF87CEEB);
  final Color _darkBlue = const Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.addListener(_filterHistory);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterHistory);
    _searchController.dispose();
    super.dispose();
  }

  void _filterHistory() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredHistory = _history;
      });
    } else {
      setState(() {
        _filteredHistory = _history.where((item) {
          final original = item['original']?.toLowerCase() ?? '';
          final translated = item['translated']?.toLowerCase() ?? '';
          return original.contains(query) || translated.contains(query);
        }).toList();
      });
    }
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
        title: const Text(
          'Translation History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _lightBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _isDeleting ? null : _clearAllHistory,
              tooltip: 'Clear all history',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadHistory,
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search translations...',
                  prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ),
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

    if (_filteredHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_searchController.text.isEmpty ? Icons.history : Icons.search_off, 
                 size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty 
                ? 'No translations yet'
                : 'No matching translations',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isEmpty
                ? 'Translate some words to see them here'
                : 'Try a different search term',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            if (_searchController.text.isNotEmpty)
              TextButton(
                onPressed: () => _searchController.clear(),
                child: const Text('Clear search'),
              ),
            const SizedBox(height: 24),
            if (_searchController.text.isEmpty)
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
                    // Original Text Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
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
                                  color: _lightBlue.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'ORIGINAL',
                                  style: TextStyle(fontSize: 10, color: _darkBlue),
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
                    
                    // Translated Text Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
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
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'TRANSLATION (${item['language']?.toUpperCase() ?? 'UNKNOWN'})',
                                  style: TextStyle(fontSize: 10, color: Colors.green[800]),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.share, size: 16, color: _darkBlue),
                                    onPressed: () {
                                      Share.share(
                                        '${item['language']?.toUpperCase()} Translation:\n\nOriginal: ${item['original']}\nTranslation: ${item['translated']}\n\n- From ZamLearnIT App',
                                        subject: 'ZamLearnIT Translation',
                                      );
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
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
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['translated'] ?? '',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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