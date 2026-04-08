import 'package:flutter/material.dart';
import 'translate_screen.dart';
import 'history_screen.dart';
import 'dart:io';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND IMAGE - Fixed for mobile
          SizedBox.expand(
            child: Image.asset(
              "assets/images/school.png",
              fit: BoxFit.cover,  // This will cover the screen properly
            ),
          ),

          // DARK OVERLAY
          Container(
            color: Colors.black.withOpacity(0.4),
          ),

          // MAIN CONTENT WITH TOP BAR AND FOOTER
          SafeArea(
            child: Column(
              children: [
                // TOP BAR / HEADER - White (Smaller for mobile)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.white,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "ZamLearnIT",
                        style: TextStyle(
                          fontSize: 28,  // Reduced from 56 to 28 for mobile
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(width: 6),
                      // Zambian flag emoji
                      Text(
                        "🇿🇲",
                        style: TextStyle(fontSize: 24),  // Reduced from 40 to 24
                      ),
                    ],
                  ),
                ),

                // SPACER - pushes content to center
                const Spacer(),

                // CENTER CONTENT
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title - Responsive text size
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "Welcome to Zambia's Leading Translation App!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.045, // Responsive font size
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

                    const SizedBox(height: 40),  // Reduced from 50

                    // Translate Button - Same size
                    SizedBox(
                      width: 200,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          elevation: 8,
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
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),  // Reduced from 20

                    // History Button
                    SizedBox(
                      width: 200,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HistoryScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "History",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),  // Reduced from 30
                    

                    // Exit Button
                    SizedBox(
                      width: 140,  // Reduced from 175
                      height: 40,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.9),
                          foregroundColor: Colors.white,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
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
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // FOOTER - White (Smaller for mobile)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.email,
                            color: Colors.blue,
                            size: 14,  // Reduced from 18
                          ),
                          const SizedBox(width: 6),
                          Flexible(  // Added Flexible to prevent overflow
                            child: Text(
                              "suwichanda@zamlearnit.com",
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 10,  // Reduced from 12
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),  // Reduced from 20
                          const Icon(
                            Icons.phone,
                            color: Colors.blue,
                            size: 14,  // Reduced from 18
                          ),
                          const SizedBox(width: 6),
                          Flexible(  // Added Flexible to prevent overflow
                            child: Text(
                              "0770473106 / 0967702012",
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 10,  // Reduced from 12
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),  // Reduced from 8
                      Text(
                        "© 2026 ZamLearnIT - All Rights Reserved",
                        style: TextStyle(
                          color: Colors.blue.withOpacity(0.7),
                          fontSize: 9,  // Reduced from 10
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