import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // ← ADD THIS IMPORT
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  bool _isConnected = true;
  
  // Colors matching your app theme
  final Color _lightBlue = const Color(0xFF87CEEB);
  final Color _darkBlue = const Color(0xFF2196F3);
  
  @override
  void initState() {
    super.initState();
    _loadHistory();
    _checkConnection();
  }
  
  // Check if backend is connected
  Future<void> _checkConnection() async {
    final connected = await ApiService.checkHealth();
    setState(() {
      _isConnected = connected;
    });
    if (!connected) {
      _showSnackBar('Cannot connect to server', Colors.red);
    }
  }
  
  // Load history from API
  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });
    
    final history = await ApiService.getHistory();
    
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }
  
  // Copy text to clipboard
  Future<void> _copyToClipboard(String text, String type) async {
    await Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('$type copied to clipboard', Colors.grey);
  }
  
  // Delete a single history item
  Future<void> _deleteHistoryItem(int id, int index) async {
    final success = await ApiService.deleteHistoryItem(id);
    if (success) {
      setState(() {
        _history.removeAt(index);
      });
      _showSnackBar('Translation deleted', Colors.green);
    } else {
      _showSnackBar('Failed to delete', Colors.red);
    }
  }
  
  // Clear all history
  Future<void> _clearAllHistory() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to delete all translations?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ApiService.clearAllHistory();
              if (success) {
                setState(() {
                  _history.clear();
                });
                _showSnackBar('All history cleared', Colors.green);
              } else {
                _showSnackBar('Failed to clear history', Colors.red);
              }
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  // Format timestamp for display
  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 7) {
        return '${(difference.inDays / 7).floor()}w ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return timestamp;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Translation History",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _lightBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAllHistory,
              tooltip: 'Clear all history',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    // Show connection error
    if (!_isConnected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No connection to server',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _checkConnection();
                _loadHistory();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _darkBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    // Show loading indicator
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
    
    // Show empty state
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No translations yet',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            Text(
              'Your translations will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _darkBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('Start Translating'),
            ),
          ],
        ),
      );
    }
    
    // Show history list with swipe-to-delete
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        final id = item['id'];
        final original = item['original'] ?? item['original_text'] ?? 'Unknown';
        final translated = item['translated'] ?? item['translated_text'] ?? '';
        final language = item['language'] ?? 'bemba';
        final timestamp = item['timestamp'];
        
        return Dismissible(
          key: Key(id.toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) {
            _deleteHistoryItem(id, index);
          },
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _lightBlue.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with language badge and timestamp
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _lightBlue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            language.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _darkBlue,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            if (timestamp != null)
                              Text(
                                _formatTimestamp(timestamp),
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                              ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.copy, size: 16, color: Colors.grey.shade500),
                              onPressed: () => _copyToClipboard(original, 'Original text'),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Copy original',
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Original English text
                    Text(
                      original,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Arrow down icon
                    Icon(Icons.arrow_downward, size: 14, color: Colors.grey.shade400),
                    
                    const SizedBox(height: 8),
                    
                    // Translated text with copy button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            translated,
                            style: TextStyle(
                              fontSize: 15,
                              color: _darkBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.copy, size: 16, color: _darkBlue),
                          onPressed: () => _copyToClipboard(translated, 'Translation'),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Copy translation',
                        ),
                      ],
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