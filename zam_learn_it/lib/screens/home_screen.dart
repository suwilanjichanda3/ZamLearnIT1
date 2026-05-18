import 'package:flutter/material.dart';
import 'translate_screen.dart';
import 'history_page.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Settings state
  bool _isDarkMode = false;
  double _brightness = 0.4; // 0.0 = darker, 1.0 = lighter
  int _appRating = 0;

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
                // Dark Mode Toggle
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
                        activeThumbColor: Colors.blue,
                      ),
                    ),
                    const Icon(Icons.dark_mode, size: 20),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Brightness Control
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
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 24),

                // About Us Section
                const Text(
                  'About Us',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.grey[850] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Contact: 0770473106, 0967702012',
                        style: TextStyle(fontSize: 13),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Email: suwilanjichanda3@gmail.com',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Rating Section
                const Text(
                  'Rate This App',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(
                    5,
                    (index) => IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: Icon(
                        Icons.star,
                        size: 28,
                        color: index < _appRating ? Colors.amber : Colors.grey,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          _appRating = index + 1;
                        });
                        setState(() {
                          _appRating = index + 1;
                        });
                      },
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    _appRating > 0
                        ? 'You rated this app $_appRating of 5'
                        : 'Tap a star to rate this app',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Preview Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preview',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sample Text',
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white70 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
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

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('How to Use ZamLearnIT'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('• Type English text in the input field'),
              SizedBox(height: 8),
              Text('• Select Bemba or Nyanja as target language'),
              SizedBox(height: 8),
              Text('• Tap Translate to get your translation'),
              SizedBox(height: 8),
              Text('• View all translations in History'),
              SizedBox(height: 8),
              Text('• Suggest better translations to help others'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Apply brightness overlay based on settings
    final overlayColor = _isDarkMode 
        ? Colors.black.withValues(alpha: _brightness + 0.3)
        : Colors.black.withValues(alpha: _brightness);
    
    // Text color based on mode
    final textColor = _isDarkMode ? Colors.white : Colors.white;
    final subtitleColor = _isDarkMode ? Colors.white70 : Colors.white70;
    
    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND IMAGE
          SizedBox.expand(
            child: Image.asset(
              "assets/images/school.png",
              fit: BoxFit.cover,
            ),
          ),

          // DYNAMIC OVERLAY - Changes with brightness and dark mode
          Container(
            color: overlayColor,
          ),

          // MAIN CONTENT
          SafeArea(
            child: Column(
              children: [
                // TOP BAR - WHITE with Settings button and Zambian flag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            "ZamLearnIT",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            "🇿🇲",
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        ),
                        onPressed: () => _showSettingsDialog(context),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.settings, size: 20),
                            SizedBox(height: 2),
                            Text(
                              'Settings',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // TAGLINE
                Center(
                  child: Text(
                    "Translate.... Learn.... Grow....",
                    style: TextStyle(
                      fontSize: 18,
                      color: subtitleColor,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // WELCOME TEXT
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    "Welcome to Zambia's Leading Translation App!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      shadows: const [
                        Shadow(
                          blurRadius: 8,
                          color: Colors.black45,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                // TRANSLATE BUTTON
                Center(
                  child: SizedBox(
                    width: 170,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TranslateScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Translate",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // HISTORY BUTTON
                Center(
                  child: SizedBox(
                    width: 170,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HistoryPage(),
                          ),
                        );
                      },
                      child: const Text(
                        "History",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // HELP BUTTON - WHITE with question mark
                Center(
                  child: SizedBox(
                    width: 170,
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2196F3),
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: () => _showHelpDialog(context),
                      icon: const Icon(Icons.question_mark, size: 18),
                      label: const Text(
                        "Help",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // EXIT BUTTON
                Center(
                  child: SizedBox(
                    width: 108,
                    height: 36,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.85),
                        foregroundColor: Colors.white,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("Exit App"),
                              content: const Text("Are you sure you want to exit?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () => exit(0),
                                  child: const Text("Exit", style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: const Text(
                        "Exit",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // FOOTER
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.email, color: Colors.blue, size: 14),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              "suwichanda@zamlearnit.com",
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.phone, color: Colors.blue, size: 14),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              "0770473106 / 0967702012",
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "© 2026 ZamLearnIT - All Rights Reserved",
                        style: TextStyle(
                          color: Colors.blue.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}