import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';

import 'product.dart';
import 'utils.dart';

class MealsManager {
  final Map<String, Meal> meals = {};
  final menu = MealMenu();
  var current = "";
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

class MealsPage extends StatefulWidget {
  const MealsPage({Key? key}) : super(key: key);

  @override
  State<MealsPage> createState() => _MealsPageState();
}

class _MealsPageState extends State<MealsPage> {
  @override
  Widget build(BuildContext context) {
    final _state = ModalRoute.of(context)!.settings.arguments as AppState;
    final _mealsManager = _state.mealsManager;

    return Scaffold(
      appBar: AppBar(title: const Text("My meals")),
      body: ListView.builder(
        itemCount: _mealsManager.meals.length,
        itemBuilder: (context, index) {
          var key = _mealsManager.meals.keys.elementAt(index);
          var meal = _mealsManager.meals[key];
          if (meal == null) return const SizedBox.shrink();
          return Card(
              child: ListTile(
            title: Text("${meal.name} (\$${meal.price})"),
            onTap: () {
              setState(() {
                _mealsManager.current = key;
                _mealsManager.menu.name.text = meal.name;
                _mealsManager.menu.ingredientInput.text = '';
                for (var i in meal.ingredients) {
                  _mealsManager.menu.ingredients[i.product.name] = i;
                }
              });
              Navigator.pushNamed(context, '/meals/add', arguments: _state)
                  .then((_) => setState(() {}));
            },
          ));
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          setState(() {
            _mealsManager.menu.clear();
            _mealsManager.current = '';
          });
          Navigator.pushNamed(context, '/meals/add', arguments: _state)
              .then((_) => setState(() {}));
        },
      ),
    );
  }
}
