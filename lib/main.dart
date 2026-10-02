import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vega_ai/app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay styling for seamless immersion
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const VegaApp());
}
