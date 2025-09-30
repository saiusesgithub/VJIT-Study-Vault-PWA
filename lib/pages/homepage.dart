import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vjitstudyvault/pages/lab_materials.dart';
import 'package:vjitstudyvault/pages/sem_materials_page.dart';
import 'package:vjitstudyvault/pages/settings_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int? year;
  int? semester;
  String? branch;
  bool _prefsLoaded = false;
  int currentIndex = 0;
  // Remove pages list, build with up-to-date data in build()

  List<dynamic> _materials = [];
  bool _materialsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    setState(() {
      _materialsLoaded = false;
    });

    try {
      // Load materials using http package instead of Dio
      final url = 'https://vjitstudyvaultjson.pages.dev/public/materials.json';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Cache-Control': 'no-cache',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        // Parse the materials JSON directly
        final Map<String, dynamic> jsonData = json.decode(response.body);
        
        setState(() {
          _materials = jsonData['items'] ?? [];
          _materialsLoaded = true;
        });
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to load materials');
      }
    } catch (e) {
      setState(() {
        _materials = [];
        _materialsLoaded = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Materials Loading Failed', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Error: ${e.toString()}',
                  style: TextStyle(fontSize: 12),
                ),
                Text(
                  'URL: https://vjitstudyvaultjson.pages.dev/public/materials.json',
                  style: TextStyle(fontSize: 10),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: _loadMaterials,
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      year = prefs.getInt('year');
      semester = prefs.getInt('semester');
      branch = prefs.getString('branch');
      _prefsLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefsLoaded || !_materialsLoaded) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading materials...'),
              if (_materialsLoaded && _materials.isEmpty)
                Container(
                  margin: EdgeInsets.all(20),
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text('DEBUG INFO:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Materials loaded: $_materialsLoaded'),
                      Text('Materials count: ${_materials.length}'),
                      Text('URL: https://vjitstudyvaultjson.pages.dev/public/materials.json'),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadMaterials,
                        child: Text('Retry Loading'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }
    Widget body;
    switch (currentIndex) {
      case 0:
        body = SemMaterialsPage(
          year: year,
          semester: semester,
          branch: branch,
          materials: _materials,
          materialsLoaded: _materialsLoaded,
          loadMaterials: _loadMaterials,
        );
        break;
      case 1:
        body = const LabMaterialsPage();
        break;
      case 2:
        body = SettingsPage(loadMaterials: _loadMaterials);
        break;
      default:
        body = const SizedBox.shrink();
    }
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logos/vjit_logo.png', height: 32, width: 32),
            const SizedBox(width: 8),
            const Text(
              'VJIT STUDY VAULT',
              style: TextStyle(fontFamily: 'Orbitron'),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Sem Materials',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.science),
            label: 'Lab Materials',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: currentIndex,
        onTap: (int index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }

  String numberWithSuffix(int? year) {
    if (year == null) return '';
    switch (year) {
      case 1:
        return '1st';
      case 2:
        return '2nd';
      case 3:
        return '3rd';
      case 4:
        return '4th';
      default:
        return '$year';
    }
  }
}
