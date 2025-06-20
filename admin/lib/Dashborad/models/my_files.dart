
import 'package:admin/Dashborad/screens/complaint.dart';
import 'package:admin/Dashborad/screens/followup.dart';
import 'package:admin/Dashborad/screens/leadmanagment.dart';
import 'package:admin/Dashborad/screens/ordermanagment.dart';
import 'package:admin/Dashborad/screens/postsalefollowup.dart';
import 'package:flutter/material.dart';



class CloudStorageInfo {
  final String? svgSrc, title;
  final int? percentage;
  final Color? color;
  final void Function(BuildContext context)?
  onTap; // <-- Add navigation function

  CloudStorageInfo({
    this.svgSrc,
    this.title,
    this.percentage,
    this.color,
    this.onTap,
  });
}

List<CloudStorageInfo> demoMyFiles = [
  CloudStorageInfo(
    title: "Lead Management",

    svgSrc: "assets/icons/Documents.svg",

    color: Color.fromARGB(255, 255, 110, 19),
    percentage: 100,
    onTap: (context) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => leadmanagment()),
      );
    },
  ),
  CloudStorageInfo(
    title: "Follow Up",

    svgSrc: "assets/icons/doc_file.svg",

    color: Color(0xFFFFA113),
    percentage: 100,
    onTap: (context) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => followup()));
    },
  ),
  CloudStorageInfo(
    title: "Post Sale Follow Up",

    svgSrc: "assets/icons/menu_task.svg",

    color: Color.fromARGB(255, 164, 173, 255),
    percentage: 100,
    onTap: (context) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => postsalefollowup()),
      );
    },
  ),
  CloudStorageInfo(
    title: "Order Management",

    svgSrc: "assets/icons/drop_box.svg",

    color: Color.fromARGB(255, 164, 229, 255),
    percentage: 100,
    onTap: (context) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ordermanagement()),
      );
    },
  ),
  CloudStorageInfo(
    title: "Complaint",

    svgSrc: "assets/icons/unknown.svg",

    color: Color.fromARGB(255, 229, 15, 0),
    percentage: 100,
    onTap: (context) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => Complaint()));
    },
  ),
];
