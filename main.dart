import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'cameras.dart';
import 'user_detail_screen.dart';
import 'registered_users_screen.dart';
import 'new_analysis_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

/// ---------------- APP ----------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Posture Mobile',
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

/// ---------------- CONSTANTS ----------------
const appBarColor = Color.fromARGB(255, 34, 36, 51);
const backgroundImage = AssetImage('assets/images/arkaplan.png');

final buttonStyle = ElevatedButton.styleFrom(
  minimumSize: const Size(250, 62.5),
  backgroundColor: Colors.white,
  foregroundColor: Colors.black,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
);

/// ---------------- HOME PAGE ----------------
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  void _navigate(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Posture Mobile',
          style: TextStyle(fontSize: 30, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: appBarColor,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: backgroundImage, fit: BoxFit.cover),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () => _navigate(context, const NewUserInputScreen()),
                style: buttonStyle,
                child: const Text(
                  'Postural Disorder Test',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed:
                    () => _navigate(context, const RegisteredUsersScreen()),
                style: buttonStyle,
                child: const Text(
                  'Recorded Data',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _navigate(context, const NewAnalysisScreen()),
                style: buttonStyle,
                child: const Text(
                  'Daily Posture Disorder',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------- NEW USER INPUT ----------------
class NewUserInputScreen extends StatefulWidget {
  const NewUserInputScreen({super.key});

  @override
  State<NewUserInputScreen> createState() => _NewUserInputScreenState();
}

class _NewUserInputScreenState extends State<NewUserInputScreen> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _continue(BuildContext context) {
    final username = _ctrl.text.trim();

    if (username.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter date!')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserDetailScreen(username: username)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Enter date: "GG.AA.YYYY"',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: appBarColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/arkaplan.png',
                fit: BoxFit.cover,
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      labelText: 'GG.AA.YYYY',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _continue(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
