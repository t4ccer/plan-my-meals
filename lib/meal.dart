import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/services.dart';
import 'package:sqlite3/sqlite3.dart';
import 'dart:developer' as developer;

import 'product.dart';
import 'utils.dart';

class MealsManager {
  Database db;
  final menu = MealMenu();
  var current = -1;

  MealsManager({
    required this.db,
  });

  void addMeal(Meal meal) {
    final m = db.prepare('INSERT INTO meals (name, servings) VALUES (?, ?)');
    m.execute([meal.name, meal.servings]);
    m.dispose();

    final id = db.lastInsertRowId;
    _addIngredients(id, meal.ingredients);
  }

  void _addIngredients(int mealId, List<Ingredient> ingredients) {
    final ingr = db.prepare(
        "INSERT INTO ingredients (meal_id, product_id, servings) VALUES (?, ?, ?)");
    for (var i in ingredients) {
      if (i.servings < 1) continue;
      ingr.execute([mealId, i.product.id, i.servings]);
    }
    ingr.dispose();
  }

  void updateMeal(Meal meal) {
    final m =
        db.prepare('UPDATE meals SET name = ?, servings = ? WHERE id = ?');
    m.execute([meal.name, meal.servings, meal.id]);
    m.dispose();

    final i = db.prepare('DELETE FROM ingredients WHERE meal_id = ?');
    i.execute([meal.id]);
    i.dispose();

    _addIngredients(meal.id, meal.ingredients);
  }

  void removeMeal(int id) {
    final m = db.prepare('DELETE FROM meals WHERE id = ?');
    m.execute([id]);
    m.dispose();

    final i = db.prepare('DELETE FROM ingredients WHERE meal_id = ?');
    i.execute([id]);
    i.dispose();

    final q = db.prepare('DELETE FROM planned_meals WHERE meal_id = ?');
    q.execute([id]);
    q.dispose();
  }

  // TODO: It is n + 1, use join, idk how
  List<Meal> getMeals() {
    final ResultSet mealsRows = db.select('SELECT * FROM meals');
    List<Meal> lst = [];
    for (final mealRow in mealsRows) {
      final meal = Meal(
        id: mealRow['id'],
        name: mealRow['name'],
        servings: mealRow['servings'].round(),
        ingredients: getIngredients(mealRow['id']),
      );
      developer.log(meal.toString(), name: 'tmm.db.getMeals');
      lst.add(meal);
    }
    return lst;
  }

  List<Ingredient> getIngredients(int mealId) {
    final ingrdientsRows = db.select(
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

class Ingredient {
  Product product;
  int servings;

  Ingredient({
    required this.product,
    required this.servings,
  });

  @override
  String toString() {
    return 'Ingredient{product: $product, servings: $servings}';
  }
}

class MealMenu {
  var name = TextEditingController();
  var servings = TextEditingController();
  var ingredientInput = TextEditingController();
  Map<int, Ingredient> ingredients = {};

  void clear() {
    name.text = '';
    ingredientInput.text = '';
    servings.text = '';
    ingredients = {};
  }

  bool isReady() {
    return (name.text != '' &&
        servings.text != '' &&
        ingredients.isNotEmpty &&
        ingredients.values.any((i) => i.servings > 0));
  }

  Meal getMeal() {
    return Meal(
      name: name.text,
      ingredients: ingredients.values.toList(),
      servings: int.parse(servings.text),
    );
  }
}

class Meal {
  int id;
  String name;
  int servings;
  List<Ingredient> ingredients;

  Decimal get price {
    Decimal acc = Decimal.fromInt(0);
    for (var ingredient in ingredients) {
      acc += ingredient.product.pricePerServing *
          Decimal.fromInt(ingredient.servings);
    }
    return acc;
  }

  Meal({
    required this.name,
    required this.servings,
    required this.ingredients,
    this.id = -1,
  });

  @override
  String toString() {
    return 'Meal{id: $id, name: $name, servings: $servings, price: $price, ingredients: $ingredients}';
  }
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
    final MealsManager _mealsManager = _state.mealsManager as MealsManager;
    final List<Meal> _meals = _mealsManager.getMeals();

    return Scaffold(
      appBar: AppBar(title: const Text("My meals")),
      body: ListView.builder(
        itemCount: _meals.length,
        itemBuilder: (context, index) {
          var meal = _meals[index];
          return Card(
              child: ListTile(
            title: Text("${meal.name} (\$${meal.price.toStringAsFixed(2)})"),
            onTap: () {
              setState(() {
                _mealsManager.menu.clear();
                _mealsManager.current = meal.id;
                _mealsManager.menu.name.text = meal.name;
                _mealsManager.menu.servings.text = meal.servings.toString();
                for (var ingredient in meal.ingredients) {
                  _mealsManager.menu.ingredients[ingredient.product.id] =
                      ingredient;
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
            _mealsManager.current = -1;
          });
          Navigator.pushNamed(context, '/meals/add', arguments: _state)
              .then((_) => setState(() {}));
        },
      ),
    );
  }
}

class MealsAddPage extends StatefulWidget {
  const MealsAddPage({Key? key}) : super(key: key);

  @override
  State<MealsAddPage> createState() => _MealsAddPageState();
}

class _MealsAddPageState extends State<MealsAddPage> {
  @override
  Widget build(BuildContext context) {
    final _state = ModalRoute.of(context)!.settings.arguments as AppState;
    final _mealsManager = _state.mealsManager as MealsManager;
    final _productsManager = _state.productsManager as ProductManager;
    final _products = _productsManager.getProducts();

    return Scaffold(
      appBar: AppBar(title: const Text("Add meal")),
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16.0,
              ),
              child: TextFormField(
                controller: _mealsManager.menu.name,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(8.0),
                  labelText: 'Meal name',
                  hintText: 'Spaghetti carbonara',
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: TextFormField(
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                controller: _mealsManager.menu.servings,
                decoration: const InputDecoration(
                  labelText: 'Servings',
                  hintText: '2',
                ),
              ),
            ),
            // TODO: Make this search work
            // Padding(
            //   padding: const EdgeInsets.symmetric(
            //     vertical: 8.0,
            //     horizontal: 16.0,
            //   ),
            //   child: TextFormField(
            //     controller: _mealsManager.menu.ingredientInput,
            //     decoration: InputDecoration(
            //       contentPadding: const EdgeInsets.all(8.0),
            //       border: OutlineInputBorder(
            //         borderRadius: BorderRadius.circular(16.0),
            //       ),
            //       labelText: 'Search',
            //       hintText: 'Rice',
            //       suffixIcon: InkWell(
            //         child: const Icon(
            //           Icons.clear,
            //         ),
            //         onTap: () {
            //           setState(() {
            //             _mealsManager.menu.ingredientInput.text = '';
            //           });
            //         },
            //       ),
            //     ),
            //   ),
            // ),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: Colors.grey, //TODO: Match it with other borders
                  ),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 20.0,
                    maxHeight: 250.0,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListView.builder(
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        var product = _products[index];
                        var amount = 0;

                        if (_mealsManager.menu.ingredients
                            .containsKey(product.id)) {
                          amount = _mealsManager
                              .menu.ingredients[product.id]!.servings;
                        }

                        Widget _trailing = const SizedBox.shrink();
                        if (amount > 0) {
                          _trailing = IconButton(
                            icon: const Icon(Icons.remove),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _mealsManager.menu.ingredients[product.id]!
                                    .servings -= 1;
                              });
                            },
                          );
                        }

                        return Card(
                          child: ListTile(
                            title: Text(
                                "${amount.toString()}x ${product.name} (\$${product.pricePerServing.toStringAsFixed(2)})"),
                            trailing: _trailing,
                            leading: IconButton(
                              icon: const Icon(Icons.add),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                if (_mealsManager.menu.ingredients
                                    .containsKey(product.id)) {
                                  setState(() {
                                    _mealsManager.menu.ingredients[product.id]!
                                        .servings += 1;
                                  });
                                } else {
                                  setState(() {
                                    _mealsManager.menu.ingredients[product.id] =
                                        Ingredient(
                                      product: product,
                                      servings: 1,
                                    );
                                  });
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Column(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          shape: const StadiumBorder()),
                      onPressed: () {
                        if (!_mealsManager.menu.isReady()) return;
                        var meal = _mealsManager.menu.getMeal();
                        meal.id = _mealsManager.current;
                        setState(() {
                          // If updating existing product
                          if (_mealsManager.current != -1) {
                            _mealsManager.updateMeal(meal);
                          } else {
                            _mealsManager.addMeal(meal);
                          }
                          _mealsManager.menu.clear();
                        });
                        Navigator.pop(context);
                      },
                      child: Text(
                        iff(_mealsManager.current != -1, 'Save meal',
                            'Add meal'),
                        textScaleFactor: 1.25,
                      ),
                    ),
                    createIf(
                      _mealsManager.current != -1,
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: const StadiumBorder(),
                            primary: Colors.red,
                          ),
                          onPressed: () {
                            setState(() {
                              _mealsManager.removeMeal(_mealsManager.current);
                              _mealsManager.menu.clear();
                            });
                            Navigator.pop(context);
                          },
                          child:
                              const Text('Remove meal', textScaleFactor: 1.25),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
