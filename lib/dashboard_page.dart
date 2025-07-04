import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'src/widgets.dart';
import 'app_state.dart';

// Calendar Page Class - Inline Definition
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String selectedMonth = 'JAN';

  final List<Map<String, String>> months = [
    {'short': 'JAN', 'full': 'JANUARY'},
    {'short': 'FEB', 'full': 'FEBRUARY'},
    {'short': 'MAR', 'full': 'MARCH'},
    {'short': 'APR', 'full': 'APRIL'},
    {'short': 'MAY', 'full': 'MAY'},
    {'short': 'JUN', 'full': 'JUNE'},
    {'short': 'JULY', 'full': 'JULY'},
    {'short': 'AUG', 'full': 'AUGUST'},
    {'short': 'SEP', 'full': 'SEPTEMBER'},
    {'short': 'OCT', 'full': 'OCTOBER'},
    {'short': 'NOV', 'full': 'NOVEMBER'},
    {'short': 'DEC', 'full': 'DECEMBER'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            // Handle menu action
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.brown,
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Month selector buttons
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // First row of months
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: months.take(6).map((month) {
                    return _buildMonthButton(month['short']!);
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // Second row of months
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: months.skip(6).map((month) {
                    return _buildMonthButton(month['short']!);
                  }).toList(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.grey),

          // Selected month events
          Expanded(
            child: _buildMonthEventsView(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildMonthButton(String month) {
    bool isSelected = selectedMonth == month;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMonth = month;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          month,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthEventsView() {
    String fullMonthName = months.firstWhere(
          (month) => month['short'] == selectedMonth,
      orElse: () => {'full': 'JANUARY'},
    )['full']!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fullMonthName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _buildSampleEvents(),
        ],
      ),
    );
  }

  Widget _buildSampleEvents() {
    // Sample events for demonstration
    if (selectedMonth == 'JAN') {
      return Column(
        children: [
          _buildEventCard(
            title: 'Pesta Ponggal Melaka',
            date: '24 January 2025',
            description: 'Traditional Tamil harvest festival celebration',
            icon: Icons.celebration,
          ),
          _buildEventCard(
            title: '2025 Melaka Chinese New Year Decoration Carnival',
            date: '14 January - 12 February 2025',
            description: 'Celebrate Chinese New Year with traditional decorations and cultural performances',
            icon: Icons.festival,
          ),
          _buildEventCard(
            title: '2025 Chinese New Year Eve Countdown Gala',
            date: '28 January 2025',
            description: 'Welcome the Year of the Snake with spectacular countdown celebration',
            icon: Icons.nightlife,
          ),
        ],
      );
    } else if (selectedMonth == 'FEB') {
      return Column(
        children: [
          _buildEventCard(
            title: 'Melaka Valentine Festival',
            date: '14 February 2025',
            description: 'Romantic celebration at historic Melaka locations',
            icon: Icons.favorite,
          ),
          _buildEventCard(
            title: 'Heritage Food Festival',
            date: '22 February 2025',
            description: 'Taste authentic Peranakan and Melaka cuisine',
            icon: Icons.restaurant,
          ),
        ],
      );
    } else {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.event_available,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No events scheduled for ${selectedMonth.toLowerCase()}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Check back later for upcoming events!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildEventCard({
    required String title,
    required String date,
    required String description,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavButton(
            icon: Icons.home,
            label: 'Home',
            isActive: false,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _buildNavButton(
            icon: Icons.search,
            label: 'Search',
            isActive: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search page coming soon!')),
              );
            },
          ),
          _buildNavButton(
            icon: Icons.calendar_today,
            label: 'Calendar',
            isActive: true, // This is the current page
            onTap: () {
              // Already on calendar page
            },
          ),
          _buildNavButton(
            icon: Icons.person,
            label: 'Profile',
            isActive: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile page coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.deepOrange.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.deepOrange : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.deepOrange : Colors.grey[600],
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.deepOrange,
                child: Text(
                  (currentUser?.displayName?.isNotEmpty == true
                      ? currentUser!.displayName![0].toUpperCase()
                      : currentUser?.email?[0].toUpperCase() ?? 'G'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                currentUser?.displayName ?? currentUser?.email ?? 'Guest',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.person_outline, color: Colors.deepOrange),
                title: const Text('Update Profile'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to update profile page
                  // Navigator.of(context).pushNamed('/profile');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Update Profile feature coming soon!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.pop(context);
                  _signOut();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Melaka Events'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.deepOrange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentUser?.displayName ?? currentUser?.email ?? 'Guest',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.deepOrange.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Favorites and About buttons - separate section
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.favorite_outline,
                      label: 'Favorites',
                      onTap: () {
                        // Navigate to favorites page
                        // Navigator.of(context).pushNamed('/favorites');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Favorites page coming soon!')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.info_outline,
                      label: 'About',
                      onTap: () {
                        // Navigate to about page
                        // Navigator.of(context).pushNamed('/about');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('About page coming soon!')),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Events section
              Text(
                'Upcoming Events',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Sample events
              Expanded(
                child: ListView(
                  children: [
                    EventCard(
                      title: 'Melaka Heritage Festival',
                      description:
                      'Celebrate the rich cultural heritage of Melaka with traditional performances, local cuisine, and historical exhibitions.',
                      date: DateTime.now().add(const Duration(days: 7)),
                      location: 'Jonker Street, Melaka',
                      attendingStatus: Attending.yes,
                      onAttendingChanged: (status) {
                        // Handle status change
                      },
                    ),
                    EventCard(
                      title: 'Nyonya Peranakan Culture Show',
                      description:
                      'Experience the unique Peranakan culture through traditional dances, music, and authentic Nyonya cuisine.',
                      date: DateTime.now().add(const Duration(days: 14)),
                      location: 'Peranakan Museum, Melaka',
                      attendingStatus: Attending.maybe,
                      onAttendingChanged: (status) {
                        // Handle status change
                      },
                    ),
                    EventCard(
                      title: 'River Cruise Night Market',
                      description:
                      'Enjoy a scenic river cruise followed by exploring the vibrant night market with local delicacies.',
                      date: DateTime.now().add(const Duration(days: 21)),
                      location: 'Melaka River, Melaka',
                      attendingStatus: Attending.no,
                      onAttendingChanged: (status) {
                        // Handle status change
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // Removed the floatingActionButton
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Home Button
            _buildNavButton(
              icon: Icons.home,
              label: 'Home',
              isActive: true, // This is the current page
              onTap: () {
                // Already on home/dashboard page
              },
            ),
            // Search Button
            _buildNavButton(
              icon: Icons.search,
              label: 'Search',
              isActive: false,
              onTap: () {
                // Navigate to search page
                // Navigator.of(context).pushNamed('/search');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Search page coming soon!')),
                );
              },
            ),
            // Calendar Button - Updated with navigation
            _buildNavButton(
              icon: Icons.calendar_today,
              label: 'Calendar',
              isActive: false,
              onTap: () {
                // Navigate to calendar page
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CalendarPage(),
                  ),
                );
              },
            ),
            // Profile Button
            _buildNavButton(
              icon: Icons.person,
              label: 'Profile',
              isActive: false,
              onTap: _showProfileMenu,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: Colors.grey.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.deepOrange.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.deepOrange : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.deepOrange : Colors.grey[600],
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}