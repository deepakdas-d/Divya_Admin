import 'package:admin/Admin/product/product_adding.dart';
import 'package:admin/Auth/sigin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    // Optional: Navigate back to login screen after logout
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => Sigin()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            onPressed: () {
              logout(context);
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to the Dashboard',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print('Navigating to ProductDetailsScreen'); // Debug print
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProductDetailsScreen(),
                  ),
                );
              },
              child: const Text('Click Me'),
            ),
          ],
        ),
      ),
    );
  }
}
