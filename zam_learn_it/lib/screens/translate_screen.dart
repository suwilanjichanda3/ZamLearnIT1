import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/api_service.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  String _translatedText = '';
  String _selectedLanguage = 'bemba';
  bool _isLoading = false;
  bool _isConnected = true;
  bool _isSpeaking = false;
  List<String> _languages = ['bemba', 'nyanja'];
  List<Map<String, dynamic>> _history = [];
  
  // Text-to-Speech instance
  final FlutterTts _flutterTts = FlutterTts();
  
  // Light blue color
  final Color _lightBlue = const Color(0xFF87CEEB); // Sky blue
  final Color _darkBlue = const Color(0xFF2196F3);
  
  @override
  void initState() {
    super.initState();
    _checkConnection();
    _loadLanguages();
    _loadHistory();
    _initTts();
  }
  
  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    _flutterTts.stop();
    super.dispose();
  }
  
  // Initialize Text-to-Speech settings
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);
    
    // Set up completion handler
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
    
    _flutterTts.setErrorHandler((msg) {
      setState(() {
        _isSpeaking = false;
      });
      _showSnackBar('Speech error: $msg', Colors.red);
    });
  }
  
  // Speak text function
  Future<void> _speakText(String text, String languageCode) async {
    if (text.isEmpty) {
      _showSnackBar('No text to read', Colors.orange);
      return;
    }
    
    try {
      setState(() {
        _isSpeaking = true;
      });
      
      // Set language for speech
      if (languageCode == 'bemba' || languageCode == 'nyanja') {
        // For Zambian languages, use English as fallback or appropriate locale
        await _flutterTts.setLanguage("en-US");
      } else {
        await _flutterTts.setLanguage("en-US");
      }
      
      await _flutterTts.speak(text);
    } catch (e) {
      setState(() {
        _isSpeaking = false;
      });
      _showSnackBar('Could not speak text', Colors.red);
    }
  }
  
  // Stop speaking
  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    setState(() {
      _isSpeaking = false;
    });
  }
  
  Future<void> _checkConnection() async {
    final connected = await ApiService.checkHealth();
    setState(() {
      _isConnected = connected;
    });
    if (!connected) {
      _showSnackBar('Cannot connect to translation server', Colors.red);
    }
  }
  
  Future<void> _loadLanguages() async {
    final langs = await ApiService.getLanguages();
    setState(() {
      _languages = langs;
    });
  }
  
  Future<void> _loadHistory() async {
    final history = await ApiService.getHistory();
    setState(() {
      _history = history;
    });
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
  
  Future<void> _translate() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showSnackBar('Please enter some text', Colors.orange);
      return;
    }
    
    if (!_isConnected) {
      _showSnackBar('No connection to translation server', Colors.red);
      return;
    }
    
    setState(() => _isLoading = true);
    
    final result = await ApiService.translateText(text, _selectedLanguage);
    
    setState(() => _isLoading = false);
    
    if (result['success'] == true) {
      setState(() => _translatedText = result['translated_text']);
      await _loadHistory();
      _showSnackBar('Translation saved!', Colors.green);
    } else {
      _showSnackBar(result['error'] ?? 'Translation failed', Colors.red);
    }
  }
  
  void _showHistoryDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
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
                    const Text(
                      'Translation History',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _history.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No translations yet',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your translations will appear here',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final item = _history[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            elevation: 2,
                            child: ListTile(
                              // REMOVED THE LEADING CIRCLE AVATAR ICON
                              title: Text(
                                item['original'] ?? item['original_text'] ?? 'Unknown',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    item['translated'] ?? item['translated_text'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13, color: _darkBlue),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _lightBlue.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item['language']?.toUpperCase() ?? 'UNKNOWN',
                                      style: TextStyle(fontSize: 10, color: _darkBlue, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.volume_up, size: 20, color: _darkBlue),
                                    onPressed: () => _speakText(item['translated'] ?? '', item['language'] ?? 'bemba'),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.copy, size: 20, color: _darkBlue),
                                    onPressed: () {
                                      _showSnackBar('Copied to clipboard!', Colors.grey);
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                _textController.text = item['original'] ?? item['original_text'] ?? '';
                                setState(() {
                                  _translatedText = item['translated'] ?? item['translated_text'] ?? '';
                                  _selectedLanguage = item['language'] ?? 'bemba';
                                });
                                Navigator.pop(context);
                                _textFocusNode.requestFocus();
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _lightBlue,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Center(
                child: Text(
                  'Select Language',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const Divider(),
            ..._languages.map((lang) => ListTile(
                  title: Text(
                    lang.toUpperCase(),
                    style: TextStyle(
                      fontWeight: _selectedLanguage == lang ? FontWeight.bold : FontWeight.normal,
                      color: _selectedLanguage == lang ? _darkBlue : Colors.black87,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  trailing: _selectedLanguage == lang ? Icon(Icons.check, color: _darkBlue, size: 20) : null,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ZamLearnIT',
          style: TextStyle(
            fontSize: 24, 
            fontWeight: FontWeight.bold, 
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: _lightBlue,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, size: 22, color: Colors.white),
            onPressed: _showHistoryDialog,
            tooltip: 'History',
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Icon(
              _isConnected ? Icons.wifi : Icons.wifi_off,
              color: _isConnected ? Colors.white : Colors.red,
              size: 18,
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Language Selector Widget
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  margin: const EdgeInsets.only(top: 30, bottom: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: _lightBlue.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Translate to ',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                      GestureDetector(
                        onTap: _showLanguagePicker,
                        child: Row(
                          children: [
                            Text(
                              _selectedLanguage.toUpperCase(),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _darkBlue,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.arrow_drop_down, color: _darkBlue, size: 22),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Input Section with Voice Input
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: 180,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _lightBlue.withOpacity(0.1),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Input Text',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _darkBlue),
                            ),
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
                                  onPressed: () async {},
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
                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Translate Button
              Center(
                child: Container(
                  width: 200,
                  height: 50,
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  child: ElevatedButton(
                    onPressed: (_isLoading || !_isConnected) ? null : _translate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Translate',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),
              
              // Output Section with Voice Playback
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: 160,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _lightBlue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _lightBlue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _lightBlue.withOpacity(0.15),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Translation (${_selectedLanguage.toUpperCase()})',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _darkBlue),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_translatedText.isNotEmpty)
                                  IconButton(
                                    icon: Icon(
                                      _isSpeaking ? Icons.stop : Icons.volume_up,
                                      size: 18,
                                      color: _darkBlue,
                                    ),
                                    onPressed: _isSpeaking
                                        ? _stopSpeaking
                                        : () => _speakText(_translatedText, _selectedLanguage),
                                    tooltip: _isSpeaking ? 'Stop' : 'Listen to translation',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                if (_translatedText.isNotEmpty)
                                  const SizedBox(width: 8),
                                if (_translatedText.isNotEmpty)
                                  IconButton(
                                    icon: Icon(Icons.copy, size: 18, color: _darkBlue),
                                    onPressed: () {
                                      _showSnackBar('Copied to clipboard!', Colors.grey);
                                    },
                                    tooltip: 'Copy',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            _translatedText.isEmpty
                                ? 'Translation will appear here...'
                                : _translatedText,
                            style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Voice Input Button (Optional - requires speech_recognition package)
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.mic, color: _darkBlue, size: 28),
                        onPressed: () {
                          _showSnackBar('Voice input coming soon!', Colors.orange);
                        },
                        tooltip: 'Voice Input (Coming Soon)',
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.volume_up, color: _darkBlue, size: 28),
                        onPressed: () {
                          if (_textController.text.isNotEmpty) {
                            _speakText(_textController.text, 'english');
                          } else {
                            _showSnackBar('No text to read', Colors.orange);
                          }
                        },
                        tooltip: 'Read input text',
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}