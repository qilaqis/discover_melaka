import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

          // Stream builder for events from Firebase
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('events')
                .where('month', isEqualTo: selectedMonth)
                .orderBy('date')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildSampleEvents(); // Show sample events if no data
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  return _buildEventCard(
                    title: data['title'] ?? 'Untitled Event',
                    date: data['date'] ?? 'No date',
                    description: data['description'] ?? 'No description',
                    icon: _getEventIcon(data['type'] ?? 'general'),
                  );
                }).toList(),
              );
            },
          ),
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

  IconData _getEventIcon(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'festival':
        return Icons.festival;
      case 'food':
        return Icons.restaurant;
      case 'cultural':
        return Icons.theater_comedy;
      case 'celebration':
        return Icons.celebration;
      case 'nightlife':
        return Icons.nightlife;
      default:
        return Icons.event;
    }
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