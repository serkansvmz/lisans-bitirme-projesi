import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Device Analysis Result',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: SensorDataScreen(),
    ),
  );
}

class SensorDataScreen extends StatefulWidget {
  const SensorDataScreen({Key? key}) : super(key: key);

  @override
  SensorDataScreenState createState() => SensorDataScreenState();
}

class SensorDataScreenState extends State<SensorDataScreen> {
  Map<String, dynamic> mpu1 = {};
  Map<String, dynamic> mpu2 = {};

  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => fetchSensorData(),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> fetchSensorData() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.4.1/data'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          mpu1 = data['mpu1'];
          mpu2 = data['mpu2'];
        });
      } else {
        print('Error while retrieving data: ${response.statusCode}');
      }
    } catch (e) {
      print('Connection error: $e');
    }
  }

  Widget sensorCard(String title, Map<String, dynamic> data) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'Data could not be retrieved!',
          style: TextStyle(fontSize: 18, color: Colors.grey[700]),
        ),
      );
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Accel: X=${data['accelX']}, Y=${data['accelY']}'),
            Text('Gyro : X=${data['gyroX']}, Y=${data['gyroY']}'),
          ],
        ),
      ),
    );
  }

  Widget postureStatus() {
    final x1 = (mpu1['accelX'] as num?)?.toDouble() ?? 0.0;
    final x2 = (mpu2['accelX'] as num?)?.toDouble() ?? 0.0;

    if (x1 < 0.85 || x2 < 0.85) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Text(
          '⚠️ Your posture is bad, please fix it!',
          style: const TextStyle(
            fontSize: 18,
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Text(
          '✅ You have a good posture!',
          style: const TextStyle(
            fontSize: 18,
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Device Analysis Result',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 34, 36, 51),
      ),
      body: ListView(
        children: [
          sensorCard("Sensor 1 Data:", mpu1),
          sensorCard("Sensor 2 Data:", mpu2),
          postureStatus(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
