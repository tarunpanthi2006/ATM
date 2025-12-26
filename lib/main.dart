import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

void main() => runApp(CampusAssistApp());

class CampusAssistApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F111A), // Sleeker deep dark
      ),
      home: CommunicationScreen(),
    );
  }
}

class CommunicationScreen extends StatefulWidget {
  @override
  _CommunicationScreenState createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  final FlutterTts flutterTts = FlutterTts();
  String lastSpoken = "Waiting for input...";

  final List<Map<String, dynamic>> phrases = [
    {'icon': Icons.water_drop, 'label': 'Water', 'msg': 'I need water', 'color': Colors.blueAccent},
    {'icon': Icons.fastfood, 'label': 'Food', 'msg': 'I am hungry', 'color': Colors.orangeAccent},
    {'icon': Icons.wc, 'label': 'Restroom', 'msg': 'Where is the restroom?', 'color': Colors.blueGrey},
    {'icon': Icons.book, 'label': 'Library', 'msg': 'Take me to the library', 'color': Colors.greenAccent},
    {'icon': Icons.home, 'label': 'Hostel', 'msg': 'I want to go to my room', 'color': Colors.purpleAccent},
    {'icon': Icons.chat_bubble, 'label': 'Talk', 'msg': 'I want to chat', 'color': Colors.pinkAccent},
    {'icon': Icons.battery_alert, 'label': 'Charge', 'msg': 'My phone is dying', 'color': Colors.amberAccent},
    {'icon': Icons.directions_walk, 'label': 'Walk', 'msg': 'I want to go outside', 'color': Colors.tealAccent},
  ];

  Future<void> _speak(String text) async {
    setState(() => lastSpoken = text);
    await flutterTts.setPitch(1.2);
    await flutterTts.speak(text);
  }
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    } 

    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Subtle Glow at the bottom (Replacing the green top one)
          Positioned(
            bottom: -150,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withOpacity(0.05),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                
                Expanded(
                  child: AnimationLimiter(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: phrases.length,
                      itemBuilder: (context, index) {
                        return AnimationConfiguration.staggeredGrid(
                          position: index,
                          duration: const Duration(milliseconds: 500),
                          columnCount: 3,
                          child: ScaleAnimation(
                            child: FadeInAnimation(
                              child: _buildGlassCard(index),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                _buildSOSButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Hello there,", style: GoogleFonts.poppins(color: Colors.white60, fontSize: 14)),
                  Text("Assistive Voice", style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold)),
                ],
              ),
              const Icon(Icons.account_circle_outlined, color: Colors.white38, size: 30),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.volume_up, color: Colors.tealAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(lastSpoken, 
                        style: GoogleFonts.poppins(color: Colors.tealAccent, fontStyle: FontStyle.italic, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(int index) {
    var p = phrases[index];
    return GestureDetector(
      onTap: () => _speak(p['msg']),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: p['color'].withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(p['icon'], color: p['color'], size: 24),
                ),
                const SizedBox(height: 8),
                Text(p['label'], style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSOSButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
      child: Column(
        children: [
          const Text("In case of emergency, tap the button below", 
            style: TextStyle(color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 8),
          Container(
            height: 65,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)]),
              boxShadow: [
                BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 15, spreadRadius: 1, offset: const Offset(0, 4))
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                // --- UPDATED ONTAP LOGIC ---
                onTap: () async {
                _speak("Emergency initiated. Alerting caretakers.");
  
                try {
                // 1. Get the GPS Location (You already built this part!)
               position = await _determinePosition();
    
                  // 2. Send to Firebase (The New Cloud Part)
                  // This creates a new entry in a collection called 'active_emergencies'
    await FirebaseFirestore.instance.collection('active_emergencies').add({
      'student_name': 'User_Demo', // You can change this to a real name later
      'latitude': position.latitude,
      'longitude': position.longitude,
      'status': 'HELP_NEEDED',
      'timestamp': FieldValue.serverTimestamp(), // This saves the exact time
    });

    setState(() {
      lastSpoken = "SOS Sent! Lat: ${position.latitude.toStringAsFixed(2)}, Lon: ${position.longitude.toStringAsFixed(2)}";
    });

  } catch (e) {
    print("Cloud Error: $e");
    _speak("Check your internet connection.");
  }
},
              ),
            ),
          ),
        ],
      ),
    );
  }
}