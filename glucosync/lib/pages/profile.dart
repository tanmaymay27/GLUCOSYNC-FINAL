import 'package:flutter/material.dart';
import 'package:glucosync/supabase_config.dart';
import 'package:glucosync/pages/history.dart';
import 'package:glucosync/pages/dashboard.dart';
import 'package:glucosync/pages/login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = '';
  String userEmail = '';
  bool isLoading = true;
  final int _selectedIndex = 2; // Profile tab is selected

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Dashboard()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HistoryPage()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        print('No user found in auth state');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const Login()),
          );
        }
        return;
      }

      print('Loading profile for user ID: ${user.id}');
      print('User email: ${user.email}');

      // Try to fetch existing profile
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        print('No profile found, creating new profile');
        // Create new profile
        final newProfile = {
          'id': user.id,
          'name': user.email?.split('@')[0] ?? 'User',
          'email': user.email,
          'updated_at': DateTime.now().toIso8601String(),
        };

        await supabase.from('profiles').upsert(newProfile);

        if (mounted) {
          setState(() {
            userName = newProfile['name']!;
            userEmail = newProfile['email'] ?? '';
            isLoading = false;
          });
        }
      } else {
        print('Profile found: $data');
        if (mounted) {
          setState(() {
            userName = data['name'] ?? user.email?.split('@')[0] ?? 'User';
            userEmail = user.email ?? '';
            isLoading = false;
          });
        }
      }
    } catch (e, stackTrace) {
      print('Error loading profile: $e');
      print('Stack trace: $stackTrace');

      // Handle specific Postgres exceptions
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('relation "profiles" does not exist')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database setup required. Please contact support.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  isLoading = true;
                });
                _loadUserProfile();
              },
            ),
          ),
        );
      }

      // Set fallback values
      if (mounted) {
        setState(() {
          final user = supabase.auth.currentUser;
          userName = user?.email?.split('@')[0] ?? 'User';
          userEmail = user?.email ?? '';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProfile(String name) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('profiles').upsert({
        'id': user.id,
        'name': name.trim(),
        'email': user.email,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context);
        _loadUserProfile(); // Reload profile data
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Color(0xFF15B392),
          ),
        );
      }
    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
      try {
        await supabase.auth.signOut();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const Login()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error signing out'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF15B392)),
            onPressed: _signOut,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFF15B392),
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          userEmail,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Profile Options
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildProfileOption(
                          'Personal Information',
                          Icons.person_outline,
                          () {
                            // Show edit profile dialog
                            _showEditProfileDialog();
                          },
                        ),
                        _buildProfileOption(
                          'Health Records',
                          Icons.favorite_border,
                          () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const HistoryPage()),
                            );
                          },
                        ),
                        _buildProfileOption(
                          'Notifications',
                          Icons.notifications_none,
                          () {},
                        ),
                        _buildProfileOption(
                          'Privacy Settings',
                          Icons.lock_outline,
                          () {},
                        ),
                        _buildProfileOption(
                          'Help & Support',
                          Icons.help_outline,
                          () {},
                        ),
                        _buildProfileOption(
                          'About App',
                          Icons.info_outline,
                          () {},
                        ),
                      ],
                    ),
                  ),

                  // Version Info
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
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

  Widget _buildProfileOption(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF15B392).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF15B392),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: userName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              userEmail,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _updateProfile(nameController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
