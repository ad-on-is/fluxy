import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

final light = ThemeData.light().copyWith(
  primaryColor: const Color.fromARGB(255, 254, 100, 11),
  switchTheme: const SwitchThemeData(
    thumbColor: WidgetStatePropertyAll(Color.fromARGB(255, 254, 100, 11)),
    trackColor: WidgetStatePropertyAll(Color.fromARGB(50, 254, 100, 11)),
    trackOutlineColor: WidgetStatePropertyAll(Colors.transparent),
  ),
  elevatedButtonTheme: const ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor:
          WidgetStatePropertyAll(Color.fromARGB(200, 254, 100, 11)),
      foregroundColor: WidgetStatePropertyAll(Colors.white),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    iconColor: Color.fromARGB(255, 210, 15, 57),
    labelStyle: TextStyle(color: Color.fromARGB(255, 223, 142, 29)),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Color.fromARGB(190, 254, 100, 11)),
    ),
  ),
);
final dark = ThemeData.dark().copyWith(
  textTheme: ThemeData.dark().textTheme.apply(
        displayColor: const Color.fromARGB(255, 127, 132, 156),
        bodyColor: const Color.fromARGB(255, 205, 214, 244),
      ),
  scaffoldBackgroundColor: const Color.fromARGB(255, 24, 24, 37),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color.fromARGB(255, 17, 17, 27),
  ),
  bottomAppBarTheme:
      const BottomAppBarTheme(color: Color.fromARGB(255, 17, 17, 27)),
  primaryColor: const Color.fromARGB(255, 250, 179, 135),
  cardTheme: const CardTheme(color: Color.fromARGB(255, 17, 17, 27)),
  switchTheme: const SwitchThemeData(
    thumbColor: WidgetStatePropertyAll(Color.fromARGB(255, 250, 179, 135)),
    trackColor: WidgetStatePropertyAll(Color.fromARGB(50, 250, 179, 135)),
    trackOutlineColor: WidgetStatePropertyAll(Colors.transparent),
  ),
  elevatedButtonTheme: const ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor:
          WidgetStatePropertyAll(Color.fromARGB(255, 250, 179, 135)),
      foregroundColor: WidgetStatePropertyAll(Colors.black),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    iconColor: Color.fromARGB(255, 243, 139, 168),
    labelStyle: TextStyle(color: Color.fromARGB(255, 249, 226, 175)),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Color.fromARGB(190, 250, 179, 135)),
    ),
  ),
);
