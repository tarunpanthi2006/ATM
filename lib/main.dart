import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:firebase_core/firebase_core.dart';

// Note: Ensure you have called Firebase.initializeApp() in your main if using real hardware
void main() async {
  // 1. You MUST have this line first
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 2. This starts the connection to your google-services.json
    await Firebase.initializeApp(); 
  } catch (e) {
    print("Firebase init error: $e");
  }
  
  runApp(CampusAssistApp());
}

class CampusAssistApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F111A),
      ),
      home: RoleSelectionScreen(),
    );
  }
}

// --- NEW: ROLE SELECTION SCREEN ---
class RoleSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("CampusAssist", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            Text("Digital Bridge for Accessibility", style: GoogleFonts.poppins(fontSize: 14, color: Colors.white54)),
            const SizedBox(height: 60),
            _roleButton(context, "I am a Student", Icons.person, Colors.tealAccent, CommunicationScreen()),
            const SizedBox(height: 20),
            _roleButton(context, "I am a Caretaker", Icons.medical_services, Colors.orangeAccent, CaretakerScreen()),
          ],
        ),
      ),
    );
  }

  Widget _roleButton(BuildContext context, String title, IconData icon, Color color, Widget nextScreen) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.05),
        side: BorderSide(color: color, width: 2),
        minimumSize: const Size(280, 75),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      icon: Icon(icon, color: color, size: 28),
      label: Text(title, style: GoogleFonts.poppins(color: color, fontSize: 18, fontWeight: FontWeight.w600)),
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => nextScreen)),
    );
  }
}

// --- NEW: CARETAKER SCREEN (PHASE 1) ---
class CaretakerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Responder Dashboard", style: GoogleFonts.poppins()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('active_emergencies')
            .where('status', isEqualTo: 'HELP_NEEDED')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 60),
                  const SizedBox(height: 10),
                  Text("All students are safe", style: GoogleFonts.poppins(color: Colors.white54)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                        const SizedBox(width: 10),
                        Text("EMERGENCY: ${data['student_name']}", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 50)),
                      onPressed: () {
                        FirebaseFirestore.instance.collection('active_emergencies').doc(docs[index].id).update({
                          'status': 'ACCEPTED',
                        });
                      },
                      child: const Text("I AM COMING", style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- STUDENT COMMUNICATION SCREEN (YOUR ORIGINAL CODE + IMPROVEMENTS) ---
class CommunicationScreen extends StatefulWidget {
  @override
  _CommunicationScreenState createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  final FlutterTts flutterTts = FlutterTts();
  String lastSpoken = "Waiting for input...";
  bool isEmergencyActive = false;

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
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Location permissions are denied');
    }
    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
                        crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85,
                      ),
                      itemCount: phrases.length,
                      itemBuilder: (context, index) {
                        return AnimationConfiguration.staggeredGrid(
                          position: index, duration: const Duration(milliseconds: 500), columnCount: 3,
                          child: ScaleAnimation(child: FadeInAnimation(child: _buildGlassCard(index))),
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
          Text("Hello there,", style: GoogleFonts.poppins(color: Colors.white60, fontSize: 14)),
          Text("Assistive Voice", style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
            child: Row(
              children: [
                const Icon(Icons.volume_up, color: Colors.tealAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(lastSpoken, style: GoogleFonts.poppins(color: Colors.tealAccent, fontSize: 13))),
              ],
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(p['icon'], color: p['color'], size: 24),
            const SizedBox(height: 8),
            Text(p['label'], style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSButton() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: InkWell(
        onTap: () async {
          _speak("Emergency initiated. Alerting caretakers.");
          try {
            Position position = await _determinePosition();
            await FirebaseFirestore.instance.collection('active_emergencies').add({
              'student_name': 'Rahul (Demo)',
              'latitude': position.latitude,
              'longitude': position.longitude,
              'status': 'HELP_NEEDED',
              'timestamp': FieldValue.serverTimestamp(),
            });
            setState(() => lastSpoken = "SOS Sent! Waiting for responder...");
          } catch (e) {
            _speak("Error sending SOS.");
          }
        },
        child: Container(
          height: 65,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)]),
          ),
          child: Center(child: Text("EMERGENCY SOS", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18))),
        ),
      ),
    );
  }
}