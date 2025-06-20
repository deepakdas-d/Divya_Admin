import 'package:flutter/material.dart';

class leadmanagment extends StatefulWidget {
  const leadmanagment({super.key});

  @override
  State<leadmanagment> createState() => _leadmanagmentState();
}

class _leadmanagmentState extends State<leadmanagment> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
          child: Column(
            children: [
              Center(child: Text('lead managment page'))
            ],
          ),
        ),
    );
  }
}