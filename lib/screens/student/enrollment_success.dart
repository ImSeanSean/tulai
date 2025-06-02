import 'package:flutter/material.dart';
import 'package:tulai/widgets/appbar.dart';

class EnrollmentSuccess extends StatelessWidget {
  const EnrollmentSuccess({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person,
                  size: 100, color: Theme.of(context).primaryColor),
              const SizedBox(height: 20),
              const Text(
                "Your enrollment has been successfully submitted!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, ModalRoute.withName('/'));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.only(
                      top: 14, bottom: 14, left: 24, right: 24),
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
