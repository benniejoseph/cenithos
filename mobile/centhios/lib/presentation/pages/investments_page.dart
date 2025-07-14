import 'package:flutter/material.dart';

class InvestmentsPage extends StatelessWidget {
  const InvestmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        Center(
          child: Text(
            'Investments Page',
            style: TextStyle(color: Colors.white),
          ),
        ),
        SizedBox(height: 100),
      ],
    );
  }
}
