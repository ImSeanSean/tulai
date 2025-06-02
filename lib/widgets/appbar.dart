import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: AppBar(
        toolbarHeight: 80,
        leading: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Image.asset(
            'assets/images/deped-logo.png',
            width: 60,
            height: 60,
            fit: BoxFit.contain,
          ),
        ),
        title: RichText(
          text: TextSpan(
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 30,
              color: Theme.of(context).splashColor,
            ),
            children: const [
              TextSpan(
                  text: 'ALS ', style: TextStyle(color: Color(0xffD00C0C))),
              TextSpan(
                  text: 'Enrollment ',
                  style: TextStyle(color: Color.fromARGB(255, 29, 107, 51))),
              TextSpan(
                  text: 'System', style: TextStyle(color: Color(0xff141EB3))),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Image.asset(
              'assets/images/als-logo.png',
              width: 60,
              height: 60,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}
