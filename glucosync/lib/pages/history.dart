import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:glucosync/pages/profile.dart';
import 'package:glucosync/pages/dashboard.dart';
import 'package:glucosync/supabase_config.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int _selectedIndex = 1;

  // Stream for all readings
  final _readingsStream = supabase
      .from('glucose_readings')
      .stream(primaryKey: ['id']).order('created_at', ascending: false);

  @override
  void initState() {
    super.initState();
    _readingsStream.listen(
      (data) {
        if (data.isNotEmpty) {
          print('History Stream Data: $data');
        } else {
          print('History Stream: No data received');
        }
      },
      onError: (e) => print('History Stream Error: $e'),
    );
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Dashboard()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final height = size.height - padding.top - padding.bottom;
    final width = size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Glucose History',
          style: TextStyle(
            color: Colors.black87,
            fontSize: width * 0.05,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _readingsStream,
        builder: (context, snapshot) {
          List<Map<String, dynamic>> readings = [];
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            readings = snapshot.data!; // No filtering, use all data
          } else if (snapshot.hasError) {
            print('History Snapshot Error: ${snapshot.error}');
          } else {
            print('History Snapshot: No data or error');
          }
          // Compute stats
          double average = 0.0;
          double highest = 0.0;
          double lowest = double.infinity;
          if (readings.isNotEmpty) {
            final glucoseValues = readings.map((r) {
              final value = r['glucose']?.toDouble();
              if (value == null) {
                print('Warning: Null glucose value found in reading: $r');
                return 120.0; // Fallback only if null, with warning
              }
              return value;
            }).toList();
            average = glucoseValues.isNotEmpty
                ? glucoseValues.reduce((a, b) => a + b) / glucoseValues.length
                : 0.0;
            highest = glucoseValues.isNotEmpty
                ? glucoseValues.reduce((a, b) => a > b ? a : b)
                : 0.0;
            lowest = glucoseValues.isNotEmpty
                ? glucoseValues.reduce((a, b) => a < b ? a : b)
                : double.infinity;
          }
          return SingleChildScrollView(
            child: Column(
              children: [
                // Statistics Cards (no filter chips)
                Padding(
                  padding: EdgeInsets.all(width * 0.05),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatCard('Average', average.toStringAsFixed(0),
                          'mg/dL', width, height),
                      SizedBox(width: width * 0.04),
                      _buildStatCard('Highest', highest.toStringAsFixed(0),
                          'mg/dL', width, height),
                      SizedBox(width: width * 0.04),
                      _buildStatCard('Lowest', lowest.toStringAsFixed(0),
                          'mg/dL', width, height),
                    ],
                  ),
                ),
                // Readings List
                Container(
                  margin: EdgeInsets.symmetric(horizontal: width * 0.05),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: readings.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No readings available'),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: readings.length,
                          separatorBuilder: (context, index) => Divider(
                            color: Colors.grey.withOpacity(0.2),
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final reading = readings[index];
                            final glucose =
                                reading['glucose']?.toDouble() ?? 120.0;
                            final absorbance =
                                reading['absorbance']?.toDouble() ?? 1.0;
                            final timestamp =
                                DateTime.parse(reading['created_at']);
                            print(
                                'Reading $index: Glucose = $glucose, Absorbance = $absorbance');
                            return ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: width * 0.05,
                                vertical: height * 0.01,
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    glucose.toStringAsFixed(0),
                                    style: TextStyle(
                                      fontSize: width * 0.045,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF15B392),
                                    ),
                                  ),
                                  Text(
                                    ' mg/dL',
                                    style: TextStyle(
                                      fontSize: width * 0.035,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Absorbance: ${absorbance.toStringAsFixed(4)}',
                                    style: TextStyle(
                                      fontSize: width * 0.035,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMM d, yyyy - h:mm a')
                                        .format(timestamp),
                                    style: TextStyle(
                                      fontSize: width * 0.03,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: _getStatusIcon(glucose.toInt()),
                            );
                          },
                        ),
                ),
                SizedBox(height: height * 0.02),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF15B392),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String unit,
    double width,
    double height,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(width * 0.03),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: width * 0.03,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: height * 0.005),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: width * 0.045,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: width * 0.01),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: width * 0.025,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getStatusIcon(int value) {
    IconData icon;
    Color color;
    if (value < 70) {
      icon = Icons.arrow_downward;
      color = Colors.red;
    } else if (value > 170) {
      icon = Icons.arrow_upward;
      color = Colors.orange;
    } else {
      icon = Icons.check_circle;
      color = Colors.green;
    }
    return Icon(icon, color: color);
  }
}
