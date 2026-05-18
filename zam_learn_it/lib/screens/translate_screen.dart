import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'history_page.dart';
import '../services/api_service.dart';
import '../services/firestore_service.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _suggestionController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  final FocusNode _suggestionFocusNode = FocusNode();
  final FirestoreService _firestoreService = FirestoreService();
  
  String _translatedText = '';
  String _selectedLanguage = 'bemba';
  bool _isLoading = false;
  bool _isConnected = true;
  bool _isSubmitting = false;
  bool _isUsingLearned = false;
  final List<String> _languages = ['bemba', 'nyanja'];
  List<Map<String, dynamic>> _history = [];
  
  // Settings state
  bool _isDarkMode = false;
  double _brightness = 0.4;
  double _fontSize = 14.0;
  
  final Color _lightBlue = const Color(0xFF87CEEB);
  final Color _darkBlue = const Color.fromARGB(255, 13, 108, 186);
  
  @override
  void initState() {
    super.initState();
    _checkConnection();
    _loadHistory();
  }
  
  @override
  void dispose() {
    _textController.dispose();
    _suggestionController.dispose();
    _textFocusNode.dispose();
    _suggestionFocusNode.dispose();
    super.dispose();
  }
  
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.settings, color: Color.fromARGB(255, 6, 88, 155)),
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
                        activeColor: Colors.blue,
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
                        activeColor: Colors.blue,
                      ),
                    ),
                    const Icon(Icons.brightness_high, size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Brightness: ${((_brightness - 0.2) / 0.6 * 100).toInt()}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
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
                        activeColor: Colors.blue,
                      ),
                    ),
                    const Icon(Icons.format_size, size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Text size: ${_fontSize.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
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
  
  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('Copied to clipboard!', Colors.grey);
  }
  
  Future<void> _checkConnection() async {
    final connected = await ApiService.checkHealth();
    setState(() => _isConnected = connected);
    if (!connected) {
      _showSnackBar('Cannot connect to server', Colors.red);
    }
  }
  
  Future<void> _loadHistory() async {
    try {
      final history = await _firestoreService.getHistoryOnce();
      setState(() {
        _history = history;
      });
      print("✅ Loaded ${_history.length} translations from Firebase");
    } catch (e) {
      print("❌ Error loading history: $e");
    }
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
  
  void _showMiddleToast(String message, Color color) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            margin: const EdgeInsets.symmetric(horizontal: 30),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color.fromARGB(255, 172, 219, 247),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () => overlayEntry.remove());
  }

  void _showHistoryDropdown() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color.fromARGB(255, 152, 213, 244),
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
                        color: _lightBlue,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Translation History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.refresh, color: Colors.white),
                                onPressed: () async {
                                  await _loadHistory();
                                  setModalState(() {});
                                  _showSnackBar('History refreshed!', Colors.green);
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
                      child: _history.isEmpty
                          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.history, size: 48, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No translations yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                            ]))
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: _history.length,
                              itemBuilder: (context, index) {
                                final item = _history[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  child: ListTile(
                                    title: Text(
                                      item['original'] ?? 'Unknown',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item['translated'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _lightBlue.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            item['language']?.toUpperCase() ?? 'UNKNOWN',
                                            style: TextStyle(fontSize: 10, color: _darkBlue),
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(Icons.copy, size: 18, color: _darkBlue),
                                      onPressed: () => _copyToClipboard(item['translated'] ?? ''),
                                    ),
                                    onTap: () {
                                      _textController.text = item['original'] ?? '';
                                      setState(() {
                                        _translatedText = item['translated'] ?? '';
                                        _selectedLanguage = item['language'] ?? 'bemba';
                                      });
                                      Navigator.pop(context);
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
  
  Future<void> _submitSuggestion() async {
    final suggestion = _suggestionController.text.trim();
    final originalText = _textController.text.trim();
    final currentTranslation = _translatedText;
    
    if (suggestion.isEmpty) {
      _showSnackBar('Please enter your suggestion', Colors.orange);
      return;
    }
    
    if (originalText.isEmpty || currentTranslation.isEmpty) {
      _showSnackBar('No translation to improve', Colors.orange);
      return;
    }
    
    setState(() => _isSubmitting = true);
    
    try {
      final result = await _firestoreService.saveGlobalSuggestion(
        original: originalText,
        currentTranslation: currentTranslation,
        suggestedTranslation: suggestion,
        language: _selectedLanguage,
        note: '',
      );
      
      if (result['success'] == true) {
        _suggestionController.clear();
        setState(() {
          _translatedText = suggestion;
          _isUsingLearned = true;
        });
        await _loadHistory();
        _showSnackBar('🌍 Suggestion saved! All users will benefit.', Colors.green);
        _showSnackBar('🎓 Thank you for helping improve translations!', Colors.teal);
      } else {
        _showSnackBar('Could not save suggestion', Colors.orange);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
  
  Future<void> _translate() async {
    final text = _textController.text.trim().toLowerCase();
    
    if (text.isEmpty) {
      _showSnackBar('Please enter some text', Colors.orange);
      return;
    }
    if (!_isConnected) {
      _showSnackBar('No connection to server', Colors.red);
      return;
    }
    
    setState(() {
      _isLoading = true;
      _isUsingLearned = false;
    });
    
    String translated;
    bool isLearned = false;
    
    try {
      final globalSuggestion = await _firestoreService.getGlobalSuggestion(text, _selectedLanguage);
      
      if (globalSuggestion != null && globalSuggestion.isNotEmpty) {
        translated = globalSuggestion;
        isLearned = true;
        _isUsingLearned = true;
        
        await _firestoreService.saveTranslation(
          original: text,
          translated: translated,
          language: _selectedLanguage,
          isUserSuggestion: true,
        );
      } else {
        throw Exception('No global suggestion found');
      }
    } catch (e) {
      final result = await ApiService.translateText(text, _selectedLanguage);
      
      if (result['success'] != true) {
        setState(() => _isLoading = false);
        _showSnackBar(result['error'] ?? 'Translation failed', Colors.red);
        return;
      }
      translated = result['translated_text'];
      
      await _firestoreService.saveTranslation(
        original: text,
        translated: translated,
        language: _selectedLanguage,
        isUserSuggestion: false,
      );
    }
    
    setState(() {
      _translatedText = translated;
      _isLoading = false;
    });
    
    await _loadHistory();
    
    if (isLearned) {
      _showMiddleToast('🌍 Using community-improved translation: "$translated"', Colors.teal);
    } else {
      _showMiddleToast('Translation saved! 💡 Suggest improvement to help others.', Colors.green);
    }
  }
  
  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _lightBlue, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
              child: const Center(child: Text('Select Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
            ),
            const Divider(),
            ..._languages.map((lang) => ListTile(
              title: Text(lang.toUpperCase(), textAlign: TextAlign.center),
              trailing: _selectedLanguage == lang ? Icon(Icons.check, color: _darkBlue) : null,
              onTap: () {
                setState(() => _selectedLanguage = lang);
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final brightnessFactor = ((_brightness - 0.2) / 0.6).clamp(0.0, 1.0);
    final backgroundColor = _isDarkMode
        ? Color.lerp(Colors.black, Colors.grey[850]!, brightnessFactor)!
        : Color.lerp(Colors.white, Colors.grey[100]!, brightnessFactor)!;
    final surfaceColor = _isDarkMode ? Colors.grey[900]! : Colors.grey.shade50;
    final cardColor = _isDarkMode ? Colors.grey[850]! : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = _isDarkMode ? Colors.black : Colors.black;
    final borderColor = _isDarkMode ? Colors.grey[700]! : Colors.grey.shade200;
    final headerFontSize = (_fontSize + 4).clamp(18.0, 24.0);
    final labelFontSize = (_fontSize * 0.9).clamp(11.0, 18.0);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // TOP BAR with title above the action buttons
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  color: _lightBlue,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const HomeScreen()),
                              );
                            },
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                "Translate",
                                style: TextStyle(
                                  fontSize: headerFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                          // Next/Forward Arrow Button
                          IconButton(
                            icon: const Icon(Icons.arrow_forward, color: Colors.black, size: 24),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const HistoryPage()),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: _showHistoryDropdown,
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: Colors.black,
                                  size: 22,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'History',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              // Connection status info
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isConnected ? Icons.wifi : Icons.wifi_off,
                                  color: _isConnected ? Colors.black : Colors.red,
                                  size: 22,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isConnected ? 'Connected' : 'Offline',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => _showSettingsDialog(context),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.settings, color: Colors.black, size: 22),
                                SizedBox(height: 2),
                                Text(
                                  'Settings',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Community Learned Badge
                if (_isUsingLearned)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, size: 14, color: Colors.teal),
                        const SizedBox(width: 6),
                        Text(
                          'Using community-improved translation',
                          style: TextStyle(fontSize: labelFontSize * 0.85, color: Colors.teal),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 10),
                
                // Language Selector
                Center(
                  child: GestureDetector(
                    onTap: _showLanguagePicker,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _lightBlue.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Translate to ', style: TextStyle(fontSize: labelFontSize, fontWeight: FontWeight.bold, color: secondaryTextColor)),
                          Text(_selectedLanguage.toUpperCase(), style: TextStyle(fontSize: headerFontSize - 2, fontWeight: FontWeight.bold, color: _darkBlue)),
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_drop_down, color: _darkBlue, size: 22),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // Input Section - Text only (no voice input)
                Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: 150,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _lightBlue.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Input Text', style: TextStyle(fontSize: labelFontSize, fontWeight: FontWeight.w600, color: _darkBlue)),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.clear, size: 18, color: Colors.grey.shade600),
                                  onPressed: () => _textController.clear(),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.paste, size: 18, color: Colors.grey.shade600),
                                  onPressed: () async {
                                    final ClipboardData? data = await Clipboard.getData('text/plain');
                                    if (data != null && data.text != null) {
                                      _textController.text = data.text!;
                                      _showSnackBar('Text pasted!', Colors.green);
                                    }
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _textFocusNode,
                          maxLines: null,
                          expands: true,
                          decoration: InputDecoration(
                            hintText: 'Type English text...',
                            hintStyle: TextStyle(fontSize: _fontSize - 1, fontWeight: FontWeight.bold, color: secondaryTextColor.withOpacity(0.75)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          style: TextStyle(fontSize: _fontSize, color: textColor),
                          cursorColor: _darkBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // Translate Button
                SizedBox(
                  width: 180,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: (_isLoading || !_isConnected) ? null : _translate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Translate', style: TextStyle(fontSize: _fontSize * 1.1, fontWeight: FontWeight.w600)),
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // Output Section
                Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: 140,
                  decoration: BoxDecoration(
                    color: _lightBlue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _lightBlue.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _lightBlue.withValues(alpha: 0.15),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Translation (${_selectedLanguage.toUpperCase()})', style: TextStyle(fontSize: labelFontSize, fontWeight: FontWeight.w600, color: _darkBlue)),
                            if (_translatedText.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.copy, size: 16, color: _darkBlue),
                                onPressed: () => _copyToClipboard(_translatedText),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            _translatedText.isEmpty ? 'Translation will appear here...' : _translatedText,
                            style: TextStyle(fontSize: _fontSize, height: 1.3, color: textColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // SUGGESTION SECTION
                if (_translatedText.isNotEmpty)
                  Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.amber[100],
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.feedback, size: 16, color: Colors.amber),
                              SizedBox(width: 8),
                              Text('Suggest a Better Translation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        const Text('Current:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(_translatedText, style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _suggestionController,
                                focusNode: _suggestionFocusNode,
                                maxLines: 2,
                                decoration: InputDecoration(
                                  hintText: 'Enter a better translation suggestion...',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isSubmitting ? null : _submitSuggestion,
                                  icon: _isSubmitting
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.send, size: 16),
                                  label: Text(_isSubmitting ? 'Submitting...' : 'Submit Suggestion'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  'Your suggestion helps everyone! 🌍',
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}