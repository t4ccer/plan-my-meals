import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/services.dart';

import 'product.dart';
import 'utils.dart';

class MealsManager {
  final menu = MealMenu();
  var current = -1;
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
    final _mealsManager = _state.mealsManager;
    final _meals = _state.getMeals();

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
                _mealsManager.current = meal.id;
                _mealsManager.menu.name.text = meal.name;
                _mealsManager.menu.servings.text = meal.servings.toString();
                _mealsManager.menu.ingredientInput.text = '';
                for (var i in meal.ingredients) {
                  _mealsManager.menu.ingredients[i.product.id] = i;
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
    final _mealsManager = _state.mealsManager;
    final _productManager = _state.productsManager;
    final _products = _state.getProducts();

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
                            _state.updateMeal(meal);
                          } else {
                            _state.addMeal(meal);
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
                              _state.removeMeal(_mealsManager.current);
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
