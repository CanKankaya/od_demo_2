import 'package:flutter/material.dart';

class DebugContainer extends StatelessWidget {
  const DebugContainer({
    Key? key,
    required this.debugText,
  }) : super(key: key);

  final String? debugText;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: MediaQuery.of(context).size.width * 0.05, // 5% from the left
      bottom: MediaQuery.of(context).size.height * 0.1, // 25% from the top
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              "Debug Container",
              style: TextStyle(
                color: Color.fromARGB(255, 200, 200, 200),
                fontSize: 20,
              ),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.9, // 90% of screen width
            height: 150,
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white54,
                width: 2,
              ),
            ),
            child: Text(
              debugText ?? 'No data',
              style: const TextStyle(
                color: Color.fromARGB(255, 200, 200, 200),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
