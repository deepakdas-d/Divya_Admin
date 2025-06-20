
import 'package:admin/Dashborad/screens/complaint.dart';
import 'package:admin/Dashborad/screens/followup.dart';
import 'package:admin/Dashborad/screens/leadmanagment.dart';
import 'package:admin/Dashborad/screens/ordermanagment.dart' show ordermanagement;
import 'package:admin/Dashborad/screens/postsalefollowup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(child: Image.asset("assets/images/logo.png")),
          DrawerListTile(
            title: "Lead Management",
            svgSrc: "assets/icons/Documents.svg",
            press: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => leadmanagment()),
              );
            },
          ),
          DrawerListTile(
            title: "Follow Up",
            svgSrc: "assets/icons/doc_file.svg",
            press: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => followup()),
              );
            },
          ),
          DrawerListTile(
            title: "Post Sale Follow Up",
            svgSrc: "assets/icons/menu_task.svg",
            press: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => postsalefollowup()),
              );
            },
          ),
          DrawerListTile(
            title: "Order Management",
            svgSrc: "assets/icons/drop_box.svg",
            press: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ordermanagement()),
              );
            },
          ),
          DrawerListTile(
            title: "Complaint",
            svgSrc: "assets/icons/unknown.svg",
            press: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Complaint()),
              );
            },
          ),
          DrawerListTile(
            title: "Logout",
            svgSrc: "assets/icons/logout.svg",
            press: () {},
          ),
        ],
      ),
    );
  }
}

class DrawerListTile extends StatelessWidget {
  const DrawerListTile({
    Key? key,
    // For selecting those three line once press "Command+D"
    required this.title,
    required this.svgSrc,
    required this.press,
  }) : super(key: key);

  final String title, svgSrc;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: press,
      horizontalTitleGap: 0.0,
      leading: SvgPicture.asset(
        svgSrc,
        colorFilter: ColorFilter.mode(Colors.white54, BlendMode.srcIn),
        height: 16,
      ),
      title: Text(title, style: TextStyle(color: Colors.white54)),
    );
  }
}
