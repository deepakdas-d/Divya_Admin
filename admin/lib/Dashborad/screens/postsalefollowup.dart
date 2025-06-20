import 'package:flutter/material.dart';

class postsalefollowup extends StatefulWidget {
  const postsalefollowup({super.key});

  @override
  State<postsalefollowup> createState() => _postsalefollowupState();
}

class _postsalefollowupState extends State<postsalefollowup> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
          child: Column(
            children: [
              Center(child: Text('Postsale followup page'))
            ],
          ),
        ),
    );
  }
}