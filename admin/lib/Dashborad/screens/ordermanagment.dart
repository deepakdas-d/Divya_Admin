import 'package:flutter/material.dart';

class ordermanagement extends StatefulWidget {
  const ordermanagement({super.key});

  @override
  State<ordermanagement> createState() => _ordermanagementState();
}

class _ordermanagementState extends State<ordermanagement> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
          child: Column(
            children: [
              Center(child: Text('ordermanagement page'))
            ],
          ),
        ),
    );
  }
}