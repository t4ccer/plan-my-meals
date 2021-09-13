import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';

import 'product.dart';

class MealsManager{
  final Map<String, Meal> meals = {};
  final menu = MealMenu();
  var currentMeal = "";
}

class Ingredient {
  late Product product;
  late int servings;
}

class MealMenu {
  var name = TextEditingController();
  var ingredientInput = TextEditingController();
  Map<String, Ingredient> ingredients = {};

  void clear() {
    name.text = '';
    ingredientInput.text = '';
    ingredients = {};
  }

  bool isReady() {
    return (name.text != '' && ingredients.isNotEmpty);
  }

  Meal getMeal() {
    return Meal(name: name.text, ingredients: ingredients.values.toList());
  }
}

class Meal {
  String name;
  List<Ingredient> ingredients;

  Decimal get price {
    var acc = Decimal.fromInt(0);
    for (var ingredient in ingredients) {
      acc += ingredient.product.pricePerServing *
          Decimal.fromInt(ingredient.servings);
    }
    return acc;
  }

  Meal({
    required this.name,
    required this.ingredients,
  });
}
