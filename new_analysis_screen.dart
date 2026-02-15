import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NewAnalysisScreen extends StatefulWidget {
  const NewAnalysisScreen({Key? key}) : super(key: key);

  @override
  _NewAnalysisScreenState createState() => _NewAnalysisScreenState();
}

class _NewAnalysisScreenState extends State<NewAnalysisScreen> {
  Map<String, dynamic> mpu1 = {};
  Map<String, dynamic> mpu2 = {};
  int tiltCountRaw = 0;
  int latestTiltBeforeMidnight = 0;
  int tiltCountStartOfDay = 0;
  int tiltCountToday = 0;
  String currentDateKey = "";
  Timer? timer;

  Map<String, int> dailyTiltMap = {};

  @override
  void initState() {
    super.initState();
    currentDateKey = _getTodayKey();
    _loadTiltStartOfDay();
    _loadDailyTiltData();
    _checkAndSavePreviousDayIfMissing();
    timer = Timer.periodic(Duration(seconds: 1), (_) => _fetchSensorData());
    _scheduleMidnightSave();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Future<void> _loadTiltStartOfDay() async {
    final prefs = await SharedPreferences.getInstance();
    tiltCountStartOfDay = prefs.getInt("tilt_start_$currentDateKey") ?? 0;
  }

  Future<void> _loadDailyTiltData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final Map<String, int> loaded = {};

    for (var key in keys) {
      if (key.startsWith("tilt_saved_")) {
        final date = key.replaceFirst("tilt_saved_", "");
        loaded[date] = prefs.getInt(key) ?? 0;
      }
    }

    setState(() {
      dailyTiltMap = loaded;
    });
  }

  Future<void> _fetchSensorData() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.4.1/data'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        final newDateKey = _getTodayKey();

        if (currentDateKey != newDateKey) {
          currentDateKey = newDateKey;
          tiltCountStartOfDay = data['tiltCountToday'] ?? 0;
          await prefs.setInt("tilt_start_$currentDateKey", tiltCountStartOfDay);
        }

        setState(() {
          mpu1 = data['mpu1'];
          mpu2 = data['mpu2'];
          tiltCountRaw = data['tiltCountToday'] ?? 0;
          tiltCountToday = tiltCountRaw - tiltCountStartOfDay;
          if (tiltCountToday < 0) tiltCountToday = 0;
        });
      }
    } catch (e) {
      print('Connection error: $e');
    }
  }

  void _scheduleMidnightSave() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = nextMidnight.difference(now);

    Timer(durationUntilMidnight, () async {
      final prefs = await SharedPreferences.getInstance();

      final todayKey = _getTodayKey();
      final saveKey = "tilt_saved_$todayKey";
      final todayCount = tiltCountRaw - tiltCountStartOfDay;

      await prefs.setInt(saveKey, todayCount);
      print("Daily data recorded: $saveKey → $todayCount");

      currentDateKey = _getTodayKey();
      tiltCountStartOfDay = tiltCountRaw;
      await prefs.setInt("tilt_start_$currentDateKey", tiltCountStartOfDay);

      setState(() {
        tiltCountToday = 0;
      });

      await _loadDailyTiltData();
      _scheduleMidnightSave(); // ertesi gün için tekrar kur
    });
  }

  Future<void> _checkAndSavePreviousDayIfMissing() async {
    final prefs = await SharedPreferences.getInstance();
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    final yKey =
        "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";
    final saveKey = "tilt_saved_$yKey";

    if (!prefs.containsKey(saveKey)) {
      final start = prefs.getInt("tilt_start_$yKey") ?? 0;
      final diff = tiltCountRaw - start;
      await prefs.setInt(saveKey, diff);
      print("Missing day corrected $saveKey → $diff");
      await _loadDailyTiltData();
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
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Accel: X=${data['accelX']}, Y=${data['accelY']}, Z=${data['accelZ']}',
            ),
            Text(
              'Gyro : X=${data['gyroX']}, Y=${data['gyroY']}, Z=${data['gyroZ']}',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Daily Posture Disorder')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                children: [
                  Text(
                    "Number of incorrect postures",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "$tiltCountToday",
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
          sensorCard("Sensor 1 Data:", mpu1),
          sensorCard("Sensor 2 Data:", mpu2),
          Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Past Daily Counts",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          ...(dailyTiltMap.entries.toList()
                ..sort((a, b) => b.key.compareTo(a.key)))
              .map(
                (e) => ListTile(
                  title: Text(e.key),
                  trailing: Text(
                    "${e.value}",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              )
              .toList(),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}
