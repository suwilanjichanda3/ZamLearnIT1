import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/firestore_service.dart';
import '../services/speech_service.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  final FirestoreService _firestoreService = FirestoreService();
  final SpeechService _speechService = SpeechService();
  
  String _translatedText = '';
  String _selectedLanguage = 'bemba';
  bool _isLoading = false;
  bool _isConnected = true;
  bool _isListening = false;
  List<String> _languages = ['bemba', 'nyanja'];
  List<Map<String, dynamic>> _history = [];
  
  final Color _lightBlue = const Color(0xFF87CEEB);
  final Color _darkBlue = const Color(0xFF2196F3);
  
  @override
  void initState() {
    super.initState();
    _checkConnection();
    _loadHistory();
    _initSpeech();
  }
  
  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    _speechService.stopListening();
    super.dispose();
  }
  
  Future<void> _initSpeech() async {
    final available = await _speechService.initialize();
    if (available) {
      print('✅ Speech recognition initialized');
    } else {
      print('❌ Speech recognition not available');
    }
  }
  
  Future<void> _startVoiceInput() async {
    if (!_speechService.isAvailable) {
      _showSnackBar('Speech recognition not available on this device', Colors.red);
      return;
    }
    
    setState(() => _isListening = true);
    _showSnackBar('🎤 Listening... Speak English now', Colors.blue);
    
    await _speechService.startListening(
      onResult: (text) {
        print('Voice result: "$text"');
        setState(() {
          _textController.text = text;
          _isListening = false;
        });
        _showSnackBar('✓ Recognized: "$text"', Colors.green);
        
        // Auto-translate after voice input
        Future.delayed(const Duration(milliseconds: 300), () {
          _translate();
        });
      },
      onError: (error) {
        print('Voice error: $error');
        setState(() => _isListening = false);
        _showSnackBar('Error: $error', Colors.red);
      },
    );
  }
  
  Future<void> _stopVoiceInput() async {
    await _speechService.stopListening();
    setState(() => _isListening = false);
    _showSnackBar('Listening stopped', Colors.orange);
  }
  
  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('Copied to clipboard!', Colors.grey);
  }
  
  Future<void> _checkConnection() async {
    final connected = await ApiService.checkHealth();
    setState(() => _isConnected = connected);
    if (!connected) {
      _showSnackBar('Cannot connect to translation server', Colors.red);
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
  
  Future<void> _translate() async {
    final text = _textController.text.trim();
    print('Translating: "$text"');
    
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
      final translated = result['translated_text'];
      print('Translation result: "$translated"');
      setState(() => _translatedText = translated);
      
      // Save to Firebase
      await _firestoreService.saveTranslation(
        original: text,
        translated: translated,
        language: _selectedLanguage,
      );
      
      await _loadHistory();
      _showSnackBar('Translation saved to Firebase!', Colors.green);
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
                              Text('No translations yet', style: TextStyle(fontSize: 14, color: Colors.grey)),
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
                                            color: _lightBlue.withOpacity(0.15),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZamLearnIT', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: _lightBlue,
        actions: [
          IconButton(icon: const Icon(Icons.history, color: Colors.white), onPressed: _showHistoryDialog),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Icon(_isConnected ? Icons.wifi : Icons.wifi_off, color: _isConnected ? Colors.white : Colors.red, size: 18),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.only(bottom: 20),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                
                // Language Selector
                Center(
                  child: GestureDetector(
                    onTap: _showLanguagePicker,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _lightBlue.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Translate to ', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                          Text(_selectedLanguage.toUpperCase(), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _darkBlue)),
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_drop_down, color: _darkBlue, size: 22),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // Input Section with Voice Input Button
                Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _lightBlue.withOpacity(0.1),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Input Text', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _darkBlue)),
                            Row(
                              children: [
                                // VOICE INPUT BUTTON
                                IconButton(
                                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none, size: 18, color: _isListening ? Colors.red : _darkBlue),
                                  onPressed: _isListening ? _stopVoiceInput : _startVoiceInput,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 8),
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
                            hintText: 'Type or speak English text...',
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
                        : const Text('Translate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // Output Section
                Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: 140,
                  decoration: BoxDecoration(
                    color: _lightBlue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _lightBlue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _lightBlue.withOpacity(0.15),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Translation (${_selectedLanguage.toUpperCase()})', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _darkBlue)),
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
                            style: const TextStyle(fontSize: 14, height: 1.3, color: Colors.black87),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}