import 'package:flutter/material.dart';
import 'package:glucosync/pages/login.dart';
import 'package:glucosync/pages/profile.dart';
import 'package:glucosync/pages/history.dart';
import 'package:glucosync/supabase_config.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String userName = '';
  bool isLoading = true;
  int _selectedIndex = 0;

  // Stream for latest reading
  final _latestReadingStream = supabase
      .from('glucose_readings')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .limit(1);

  // Stream for weekly trend (last 7 readings)
  final _trendStream = supabase
      .from('glucose_readings')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .limit(7);

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _latestReadingStream.listen(
      (data) {
        if (data.isNotEmpty) {
          print('Latest Stream Data: ${data.first}');
        } else {
          print('Latest Stream: No data received');
        }
      },
      onError: (e) {
        print('Latest Stream Error: $e');
        if (mounted) setState(() => isLoading = false);
      },
    );
    _trendStream.listen(
      (data) {
        if (data.isNotEmpty) {
          print('Trend Stream Data: $data');
        } else {
          print('Trend Stream: No data received');
        }
      },
      onError: (e) {
        print('Trend Stream Error: $e');
        if (mounted) setState(() => isLoading = false);
      },
    );
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final profile =
            await supabase.from('profiles').select().eq('id', user.id).single();
        setState(() {
          userName = profile['name'] ?? 'User';
          isLoading = false;
        });
      } else {
        setState(() {
          userName = 'User';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Profile Load Error: $e');
      if (mounted) {
        setState(() {
          userName = 'User';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true && mounted) {
      await supabase.auth.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed out successfully'),
            backgroundColor: Color(0xFF15B392),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const Login()),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HistoryPage()),
      );
    } else if (index == 2) {
      Navigator.push(
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
    String currentDate = DateFormat('EEEE, d MMMM').format(DateTime.now());
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final height = size.height - padding.top - padding.bottom;
    final width = size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(width * 0.05),
                      height: height * 0.15,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back,',
                                    style: TextStyle(
                                      fontSize: width * 0.035,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    userName,
                                    style: TextStyle(
                                      fontSize: width * 0.06,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF15B392),
                                    ),
                                  ),
                                  Text(
                                    currentDate,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: width * 0.035,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () => _onItemTapped(2),
                                child: CircleAvatar(
                                  radius: width * 0.06,
                                  backgroundColor: const Color(0xFF15B392),
                                  child: Text(
                                    userName.isNotEmpty
                                        ? userName[0].toUpperCase()
                                        : 'U',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: width * 0.05,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: height * 0.02),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _latestReadingStream,
                      builder: (context, snapshot) {
                        double glucose = 120.0; // Default fallback
                        double absorbance = 1.0;
                        int hr = 72; // Default HR
                        int spo2 = 97; // Default SpO2
                        String status = 'Normal';
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          final reading = snapshot.data!.first;
                          glucose = reading['glucose']?.toDouble() ?? 120.0;
                          absorbance = reading['absorbance']?.toDouble() ?? 1.0;
                          hr = reading['hr']?.toInt() ?? 72; // Fetch HR
                          spo2 = reading['spo2']?.toInt() ?? 97; // Fetch SpO2
                          print(
                              'Fetched Glucose: $glucose, Absorbance: $absorbance, HR: $hr, SpO2: $spo2');

                          // Updated status logic
                          if (glucose <= 70) {
                            status = 'Lower';
                          } else if (glucose > 70 && glucose <= 140) {
                            status = 'Normal';
                          } else if (glucose > 140 && glucose < 180) {
                            status = 'Slight High';
                          } else if (glucose >= 180) {
                            status = 'Higher';
                          }
                        } else if (snapshot.hasError) {
                          print('Latest Snapshot Error: ${snapshot.error}');
                        } else {
                          print('Latest Snapshot: No data or error');
                        }
                        return Container(
                          margin:
                              EdgeInsets.symmetric(horizontal: width * 0.05),
                          padding: EdgeInsets.all(width * 0.05),
                          height: height * 0.20,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF15B392), Color(0xFF1BD4AF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF15B392).withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Current Glucose',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: width * 0.04,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: width * 0.03,
                                      vertical: height * 0.008,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: width * 0.03,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    glucose.toStringAsFixed(0),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: width * 0.12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: width * 0.02),
                                  Padding(
                                    padding:
                                        EdgeInsets.only(bottom: height * 0.01),
                                    child: Text(
                                      'mg/dL',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: width * 0.04,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Absorbance: ${absorbance.toStringAsFixed(4)}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: width * 0.035,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: height * 0.02),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _trendStream,
                      builder: (context, snapshot) {
                        List<FlSpot> trendData = const [
                          FlSpot(0, 120),
                          FlSpot(1, 130),
                          FlSpot(2, 125),
                          FlSpot(3, 140),
                          FlSpot(4, 135),
                          FlSpot(5, 128),
                          FlSpot(6, 132),
                        ];
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          trendData = snapshot.data!
                              .asMap()
                              .entries
                              .map((entry) => FlSpot(
                                    entry.key.toDouble(),
                                    entry.value['glucose']?.toDouble() ?? 120.0,
                                  ))
                              .toList()
                              .reversed
                              .toList();
                        } else if (snapshot.hasError) {
                          print('Trend Snapshot Error: ${snapshot.error}');
                        }
                        return Container(
                          margin: EdgeInsets.all(width * 0.05),
                          padding: EdgeInsets.all(width * 0.05),
                          height: height * 0.35,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daily Trend',
                                style: TextStyle(
                                  fontSize: width * 0.045,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: height * 0.02),
                              Expanded(
                                child: LineChart(
                                  LineChartData(
                                    gridData: const FlGridData(show: false),
                                    titlesData: FlTitlesData(
                                      leftTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            const days = [
                                              'Latest',
                                              '',
                                              '',
                                              '',
                                              '',
                                              '',
                                              'Oldest'
                                            ];
                                            if (value >= 0 &&
                                                value < days.length) {
                                              return Text(
                                                days[value.toInt()],
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: width * 0.03,
                                                ),
                                              );
                                            }
                                            return const Text('');
                                          },
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: trendData,
                                        isCurved: true,
                                        color: const Color(0xFF15B392),
                                        barWidth: width * 0.008,
                                        dotData: const FlDotData(show: false),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: const Color(0xFF15B392)
                                              .withOpacity(0.1),
                                        ),
                                      ),
                                    ],
                                    minY: 40,
                                    maxY: 280,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: StreamBuilder<List<Map<String, dynamic>>>(
                              stream: _latestReadingStream,
                              builder: (context, snapshot) {
                                int hr = 72; // Default HR
                                if (snapshot.hasData &&
                                    snapshot.data!.isNotEmpty) {
                                  final reading = snapshot.data!.first;
                                  hr = reading['hr']?.toInt() ?? 72; // Fetch HR
                                }
                                return _buildHealthCard(
                                  'Heart Rate',
                                  hr.toString(),
                                  'BPM',
                                  Icons.favorite,
                                  Colors.redAccent,
                                  width,
                                  height,
                                );
                              },
                            ),
                          ),
                          SizedBox(width: width * 0.04),
                          Expanded(
                            child: StreamBuilder<List<Map<String, dynamic>>>(
                              stream: _latestReadingStream,
                              builder: (context, snapshot) {
                                int spo2 = 97; // Default SpO2
                                if (snapshot.hasData &&
                                    snapshot.data!.isNotEmpty) {
                                  final reading = snapshot.data!.first;
                                  spo2 = reading['spo2']?.toInt() ??
                                      97; // Fetch SpO2
                                }
                                return _buildHealthCard(
                                  'SpO2',
                                  spo2.toString(),
                                  '%',
                                  Icons.health_and_safety,
                                  Colors.blueAccent,
                                  width,
                                  height,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: height * 0.04),
                  ],
                ),
              ),
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

  Widget _buildHealthCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
    double width,
    double height,
  ) {
    return Container(
      height: height * 0.12,
      padding: EdgeInsets.all(width * 0.04),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: width * 0.05),
              SizedBox(width: width * 0.02),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: width * 0.035,
                ),
              ),
            ],
          ),
          SizedBox(height: height * 0.01),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: width * 0.06,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: width * 0.01),
              Padding(
                padding: EdgeInsets.only(bottom: height * 0.005),
                child: Text(
                  unit,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: width * 0.03,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
