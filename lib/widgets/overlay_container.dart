// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import 'package:od_demo_2/models/recognition.dart';

class OverlayContainer extends StatelessWidget {
  const OverlayContainer({
    Key? key,
    required this.result,
  }) : super(key: key);

  final List<Recognition> result;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: MediaQuery.of(context).size.width * 0.05, // 5% from the left
      top: MediaQuery.of(context).size.height * 0.3, // 25% from the top
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9, // 90% of screen width
        height: 50, // fixed height of 100 pixels
        // decoration: BoxDecoration(
        //   color: Colors.black.withOpacity(0.5),
        //   borderRadius: BorderRadius.circular(16),
        // ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var item in result)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(4),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white54,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 200, 200, 200),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
