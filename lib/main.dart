import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'OD Demo',
        theme: ThemeData.dark(),
        home: const HomeView(),
      );
}
