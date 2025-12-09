import 'package:flutter/material.dart';
import 'start_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:month_year_picker/month_year_picker.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // Required for month_year_picker
      localizationsDelegates: const [
        MonthYearPickerLocalizations.delegate,
      ],

      // Start screen first
      home: const StartPage(),
    );
  }
}
