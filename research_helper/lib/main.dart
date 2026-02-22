import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:research_helper/MODELS/message.dart';
import 'package:research_helper/MODELS/project.dart';
import 'package:research_helper/PAGES/homepage.dart';
import 'package:research_helper/SERVICES/dioClient.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Dioclient.init();
  Hive.registerAdapter(MessageAdapter());
  Hive.registerAdapter(ProjectAdapter());
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId');
  if (userId == null) {
   await prefs.setString('userId', Uuid().v4());
  }
  await Hive.openBox<Project>('projects');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      home: HomePage(),
    );
  }
}
