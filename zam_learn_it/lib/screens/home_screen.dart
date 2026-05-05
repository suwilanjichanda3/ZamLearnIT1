import 'package:flutter/material.dart';
import 'translate_screen.dart';
import 'history_page.dart';
import 'dart:io';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('How to Use ZamLearnIT'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpStep('1', 'Type or speak', 'Enter English text by typing or using the microphone button'),
              const Divider(),
              _buildHelpStep('2', 'Select language', 'Choose Bemba or Nyanja as your target language'),
              const Divider(),
              _buildHelpStep('3', 'Translate', 'Tap the Translate button to get your translation'),
              const Divider(),
              _buildHelpStep('4', 'Save & History', 'Translations are automatically saved. View them in History'),
              const Divider(),
              _buildHelpStep('5', 'Voice Input', 'Tap the microphone icon to speak instead of typing'),
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

  Widget _buildHelpStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

          // DARK OVERLAY
          Container(
            color: Colors.black.withOpacity(0.4),
          ),

          // MAIN CONTENT
          SafeArea(
            child: Column(
              children: [
                // TOP BAR
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                      Text("🇿🇲", style: TextStyle(fontSize: 24)),
                    ],
                  ),
                ),

                const Spacer(),

                // CENTER CONTENT - BUTTONS
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Welcome Text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "Welcome to Zambia's Leading Translation App!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.045,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Segoe Script',
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              blurRadius: 10,
                              color: Colors.black54,
                              offset: Offset(3, 3),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    const Text(
                      "Learn...... Translate...... Grow.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black38,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 50),

                    // TRANSLATE BUTTON (Main action - largest)
                    SizedBox(
                      width: 220,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
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
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // HISTORY BUTTON
                    SizedBox(
                      width: 200,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
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
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // HELP BUTTON
                    SizedBox(
                      width: 180,
                      height: 45,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          foregroundColor: Colors.blue,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        onPressed: () => _showHelpDialog(context),
                        icon: const Icon(Icons.help_outline, size: 18),
                        label: const Text(
                          "Help",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // EXIT BUTTON (Smaller, subtle)
                    SizedBox(
                      width: 120,
                      height: 38,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.85),
                          foregroundColor: Colors.white,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(19),
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
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // FOOTER
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.phone, color: Colors.blue, size: 14),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              "0770473106 / 0967702012",
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 10,
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
                          color: Colors.blue.withOpacity(0.7),
                          fontSize: 9,
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