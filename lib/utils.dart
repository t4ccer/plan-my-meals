import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:plan_my_meals/planner.dart';
import 'dart:developer' as developer;
import 'package:sqlite3/sqlite3.dart';

import 'product.dart';
import 'meal.dart';

class DecimalTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final regEx = RegExp(r"^\d*\.?(\d{0,2})");
    String newString = regEx.stringMatch(newValue.text) ?? "";
    return newString == newValue.text ? newValue : oldValue;
  }
}

class AppState {
  Database? _db;
  ProductManager? productsManager;
  MealsManager? mealsManager;
  MealPlanner? planner;

  AppState() {
    _openDB();
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<String> get _dbFile async {
    final path = await _localPath;
    return '$path/db.db';
  }

  void _openDB() async {
    final db = await _dbFile;
    _db = sqlite3.open(db);
    _db!.execute('''
    CREATE TABLE IF NOT EXISTS products (
      id INTEGER NOT NULL PRIMARY KEY,
      name TEXT NOT NULL,
      servings INTEGER NOT NULL,
      price INTEGER NOT NULL,
      amount INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS meals (
      id INTEGER NOT NULL PRIMARY KEY,
      name TEXT NOT NULL,
      servings INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS ingredients (
      meal_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      servings INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS planned_meals (
      id INTEGER NOT NULL PRIMARY KEY,
      meal_id INTEGER NOT NULL,
      date INTEGER NOT NULL,
      done INTEGER NOT NULL
    );
      ''');
    productsManager = ProductManager(db: _db!);
    mealsManager = MealsManager(db: _db!);
    planner = MealPlanner(
      db: _db!,
      mealsManager: mealsManager!,
      productsManager: productsManager!,
    );
  }
}

T iff<T>(cond, T a, T b) {
  if (cond) {
    return a;
  } else {
    return b;
  }
}

Widget createIf(cond, widget) {
  if (cond) {
    return widget;
  } else {
    return const SizedBox.shrink();
  }
}
