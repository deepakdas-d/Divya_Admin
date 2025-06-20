import 'package:flutter/material.dart';

class followup extends StatefulWidget {
  const followup({super.key});

  @override
  State<followup> createState() => _followupState();
}

class _followupState extends State<followup> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(children: [Center(child: Text('Follow Up page'))]),
      ),
    );
  }
}
