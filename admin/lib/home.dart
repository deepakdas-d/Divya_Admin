import 'package:admin/Auth/sigin.dart';
import 'package:admin/Screens/Complaint/ComplaintPage.dart';
import 'package:admin/Screens/LeadReport/LeadReportPage.dart';
import 'package:admin/Screens/Maker/MakerManagementPage.dart';
import 'package:admin/Screens/Orders/Order_report.dart';
import 'package:admin/Screens/PostSaleFollowUp/postsalefollowup.dart';
import 'package:admin/Screens/Sales/listsalesmen.dart';
import 'package:admin/Screens/product/listproducts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => Signin()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargeScreen = screenSize.width > 900;

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(255, 40, 100, 196),
                    Color.fromARGB(255, 45, 110, 202),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFEAB308)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenSize.width * 0.05,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Manage your business',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: screenSize.width * 0.035,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.home_outlined,
              title: 'Home',
              onTap: () {
                Navigator.pop(context); // Close drawer
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () {
                Navigator.pop(context);
                // Add navigation to settings page if needed
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.feedback_outlined,
              title: 'Send Feedback',
              onTap: () async {
                Navigator.pop(context);
                const url = 'mailto:feedback@example.com?subject=Feedback';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not open email client'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () async {
                Navigator.pop(context);
                const url = 'https://example.com/privacy-policy';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not open privacy policy'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            const Divider(
              color: Color(0xFFE2E8F0),
              thickness: 1,
              indent: 16,
              endIndent: 16,
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.logout_outlined,
              title: 'Logout',
              iconColor: const Color(0xFFEF4444),
              onTap: () {
                logout(context);
              },
            ),
          ],
        ),
      ),
      body: Builder(
        builder: (context) {
          final screenSize = MediaQuery.of(context).size;

          return SafeArea(
            child: Column(
              children: [
                _buildHeader(context, screenSize),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(top: screenSize.height * 0.02),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(screenSize.width * 0.04),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeSection(context, screenSize),
                          SizedBox(height: screenSize.height * 0.025),
                          _buildStatsCards(context, screenSize),
                          SizedBox(height: screenSize.height * 0.03),
                          _buildSalesChart(context, screenSize),
                          SizedBox(height: screenSize.height * 0.03),
                          Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: screenSize.width * 0.05,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(height: screenSize.height * 0.02),
                          _buildDashboardGrid(
                            context,
                            screenSize,
                            isTablet,
                            isLargeScreen,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final screenSize = MediaQuery.of(context).size;
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? const Color(0xFF1E293B),
        size: screenSize.width * 0.06,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: screenSize.width * 0.04,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1E293B),
        ),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.06,
        vertical: screenSize.height * 0.005,
      ),
      tileColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selectedTileColor: const Color(0xFFF59E0B).withOpacity(0.1),
    );
  }

  Widget _buildHeader(BuildContext context, Size screenSize) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.05,
        vertical: screenSize.height * 0.015,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Scaffold.of(context).openDrawer();
            },
            child: Container(
              width: screenSize.width * 0.11,
              height: screenSize.width * 0.11,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFEAB308)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.menu,
                color: Colors.white,
                size: screenSize.width * 0.045,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'DASHBOARD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenSize.width * 0.045,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: screenSize.width * 0.03,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: screenSize.width * 0.11,
            height: screenSize.width * 0.11,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: screenSize.width * 0.05,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, Size screenSize) {
    return Container(
      padding: EdgeInsets.all(screenSize.width * 0.04),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenSize.width * 0.05,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: screenSize.height * 0.005),
                Text(
                  'Manage your business efficiently',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: screenSize.width * 0.035,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.dashboard_outlined,
            color: Colors.white,
            size: screenSize.width * 0.08,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context, Size screenSize) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Sales',
            '₹2,45,670',
            Icons.trending_up,
            const Color(0xFF10B981),
            '+12.5%',
            screenSize,
          ),
        ),
        SizedBox(width: screenSize.width * 0.03),
        Expanded(
          child: _buildStatCard(
            'Active Orders',
            '147',
            Icons.shopping_cart,
            const Color(0xFF3B82F6),
            '+8.2%',
            screenSize,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String change,
    Size screenSize,
  ) {
    return Container(
      padding: EdgeInsets.all(screenSize.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: screenSize.width * 0.05),
              ),
              Text(
                change,
                style: TextStyle(
                  color: const Color(0xFF10B981),
                  fontSize: screenSize.width * 0.03,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: screenSize.height * 0.01),
          Text(
            value,
            style: TextStyle(
              fontSize: screenSize.width * 0.055,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: screenSize.width * 0.032,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart(BuildContext context, Size screenSize) {
    return Container(
      height: screenSize.height * 0.25,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(screenSize.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sales Growth',
                      style: TextStyle(
                        fontSize: screenSize.width * 0.045,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Last 6 months',
                      style: TextStyle(
                        fontSize: screenSize.width * 0.032,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '↗ 24.5%',
                    style: TextStyle(
                      color: const Color(0xFF10B981),
                      fontSize: screenSize.width * 0.032,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenSize.height * 0.02),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: const Color(0xFFE2E8F0),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = [
                            'Jan',
                            'Feb',
                            'Mar',
                            'Apr',
                            'May',
                            'Jun',
                          ];
                          if (value.toInt() < months.length) {
                            return Text(
                              months[value.toInt()],
                              style: TextStyle(
                                color: const Color(0xFF64748B),
                                fontSize: screenSize.width * 0.028,
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 2),
                        const FlSpot(1, 4),
                        const FlSpot(2, 3),
                        const FlSpot(3, 5),
                        const FlSpot(4, 4),
                        const FlSpot(5, 6),
                      ],
                      isCurved: true,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                      ),
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 5,
                            color: const Color(0xFF3B82F6),
                            strokeWidth: 3,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF3B82F6).withOpacity(0.1),
                            const Color(0xFF3B82F6).withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardGrid(
    BuildContext context,
    Size screenSize,
    bool isTablet,
    bool isLargeScreen,
  ) {
    int crossAxisCount = isLargeScreen
        ? 4
        : isTablet
        ? 3
        : 2;
    double childAspectRatio = isTablet ? 1.2 : 1.1;

    final List<DashboardItem> items = [
      DashboardItem(
        'Sales Management',
        Icons.analytics_outlined,
        const Color(0xFF3B82F6),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SalesManagementPage()),
          );
        },
      ),
      DashboardItem(
        'Maker Management',
        Icons.people_outline,
        const Color(0xFF10B981),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MakerManagementPage()),
          );
        },
      ),
      DashboardItem(
        'Lead Report',
        Icons.phone_outlined,
        const Color(0xFFF59E0B),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LeadReport()),
          );
        },
      ),
      DashboardItem(
        'Order Report',
        Icons.receipt_long_outlined,
        const Color(0xFF8B5CF6),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => OrderReport()),
          );
        },
      ),
      DashboardItem(
        'Follow Up Report',
        Icons.assignment_outlined,
        const Color(0xFFEF4444),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Postsalefollowup()),
          );
        },
      ),
      DashboardItem(
        'Product Adding',
        Icons.add_business_outlined,
        const Color(0xFF06B6D4),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProductListPage()),
          );
        },
      ),
      DashboardItem(
        'Complaint Page',
        Icons.feedback_outlined,
        const Color(0xFFEC4899),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ComplaintPage()),
          );
        },
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: screenSize.width * 0.03,
        mainAxisSpacing: screenSize.width * 0.03,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildDashboardCard(
          item.title,
          item.icon,
          item.color,
          screenSize,
          context,
          item.onTap,
        );
      },
    );
  }

  Widget _buildDashboardCard(
    String title,
    IconData icon,
    Color color,
    Size screenSize,
    BuildContext context,
    VoidCallback? onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap:
              onTap ??
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Opening $title...'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
          child: Padding(
            padding: EdgeInsets.all(screenSize.width * 0.04),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: screenSize.width * 0.13,
                  height: screenSize.width * 0.13,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.2), width: 1),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: screenSize.width * 0.06,
                  ),
                ),
                SizedBox(height: screenSize.height * 0.015),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenSize.width * 0.035,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  DashboardItem(this.title, this.icon, this.color, {this.onTap});
}
