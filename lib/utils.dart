import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
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
  var productsManager = ProductManager();
  var mealsManager = MealsManager();
  late Database _db;

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<String> get _dbFile async {
    final path = await _localPath;
    return '$path/db.db';
  }

  void openDB() async {
    final db = await _dbFile;
    _db = sqlite3.open(db);

    _db.execute('''
    CREATE TABLE IF NOT EXISTS products (
      id INTEGER NOT NULL PRIMARY KEY,
      name TEXT NOT NULL,
      servings INTEGER NOT NULL,
      price INTEGER NOT NULL
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
      ''');
  }

  void addProduct(Product product) {
    final p = _db.prepare(
        'INSERT INTO products (name, servings, price) VALUES (?, ?, ?)');
    p.execute([product.name, product.servings, product.priceCents]);
    p.dispose();
  }

  void updateProduct(Product product) {
    final p = _db.prepare(
        'UPDATE products SET name = ?, servings = ?, price = ? WHERE id = ?');
    p.execute([product.name, product.servings, product.priceCents, product.id]);
    p.dispose();
  }

  void removeProduct(int id) {
    final p = _db.prepare('DELETE FROM products WHERE id = ?');
    p.execute([id]);
    p.dispose();
  }

  List<Product> getProducts() {
    final ResultSet res = _db.select('SELECT * FROM products');
    List<Product> lst = [];
    for (final row in res) {
      var product = Product(
        name: row['name'],
        servings: row['servings'].round(),
        price: Decimal.fromInt(row['price']) / Decimal.fromInt(100),
        id: row['id'],
      );
      lst.add(product);
    }
    return lst;
  }

  void addMeal(Meal meal) {
    final m = _db.prepare('INSERT INTO meals (name, servings) VALUES (?, ?)');
    m.execute([meal.name, meal.servings]);
    m.dispose();

    final id = _db.lastInsertRowId;
    _addIngredients(id, meal.ingredients);
  }

  void _addIngredients(int mealId, List<Ingredient> ingredients) {
    final ingr = _db.prepare(
        "INSERT INTO ingredients (meal_id, product_id, servings) VALUES (?, ?, ?)");
    for (var i in ingredients) {
      if (i.servings < 1) continue;
      ingr.execute([mealId, i.product.id, i.servings]);
    }
    ingr.dispose();
  }

  void updateMeal(Meal meal) {
    final m =
        _db.prepare('UPDATE meals SET name = ?, servings = ? WHERE id = ?');
    m.execute([meal.name, meal.servings, meal.id]);
    m.dispose();

    final i = _db.prepare('DELETE FROM ingredients WHERE meal_id = ?');
    i.execute([meal.id]);
    i.dispose();

    _addIngredients(meal.id, meal.ingredients);
  }

  void removeMeal(int id) {
    final m = _db.prepare('DELETE FROM meals WHERE id = ?');
    m.execute([id]);
    m.dispose();

    final i = _db.prepare('DELETE FROM ingredients WHERE meal_id = ?');
    i.execute([id]);
    i.dispose();
  }

  // TODO use join, idk how
  List<Meal> getMeals() {
    final ResultSet mealsRows = _db.select('SELECT * FROM meals');
    List<Meal> lst = [];
    for (final mealRow in mealsRows) {
      final meal = Meal(
        id: mealRow['id'],
        name: mealRow['name'],
        servings: mealRow['servings'].round(),
        ingredients: _getIngredients(mealRow['id']),
      );
      developer.log(meal.toString(), name: 'tmm.db.getMeals');
      lst.add(meal);
    }
    return lst;
  }

  List<Ingredient> _getIngredients(int mealId) {
    final ingrdientsRows = _db.select(
        'SELECT  products.id AS productId, products.name AS productName, products.servings AS productServings, products.price AS productPrice, ingredients.servings AS ingredientServings  FROM ingredients INNER JOIN products ON products.id=ingredients.product_id WHERE ingredients.meal_id = ? ',
        [mealId]);
    developer.log(ingrdientsRows.toString(), name: 'tmm.db.getIngredients');
    List<Ingredient> res = [];
    for (var row in ingrdientsRows) {
      var ingr = Ingredient(
        product: Product(
          name: row['productName'],
          price: Decimal.fromInt(row['productPrice']) / Decimal.fromInt(100),
          servings: row['productServings'],
          id: row['productId'],
        ),
        servings: row['ingredientServings'],
      );
      developer.log(ingr.toString(), name: 'tmm.db.getIngredients');
      res.add(ingr);
    }
    return res;
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
