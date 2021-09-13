import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'product.dart';
import 'sections.dart';
import 'meal.dart';
import 'utils.dart';
import "drawer.dart";

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Plan My Meals",
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/products': (context) => const ProductsPage(),
      },
    );
  }
}

class _MyHomePageState extends State<HomePage> {
  var _section = Section.HOME;

  final _productManager = ProductManager();
  final _mealManager = MealManager();

  @override
  Widget build(BuildContext context) {
    Widget _body, _floatingButton;
    String _title = "Plan My Meals";
    _floatingButton = const SizedBox.shrink();

    switch (_section) {
      case Section.HOME:
        _body = const Center(child: Text('Main page'));
        break;

      case Section.PRODUCTS:
        _title = "My products";
        _body = ListView.builder(
          itemCount: _productManager.products.length,
          itemBuilder: (context, index) {
            var key = _productManager.products.keys.elementAt(index);
            var product = _productManager.products[key];
            if (product == null) return const SizedBox.shrink();
            return Card(
                child: ListTile(
              title: Text(
                  "${product.name} (\$${product.pricePerServing.toStringAsFixed(2)}/serv)"),
              onTap: () {
                setState(() {
                  _productManager.currentProduct = key;
                  _productManager.menu.name.text = product.name;
                  _productManager.menu.servings.text =
                      product.servings.toString();
                  _productManager.menu.price.text = product.price.toString();
                  _section = Section.PRODUCT_ADD;
                });
              },
            ));
          },
        );
        _floatingButton = FloatingActionButton(
          onPressed: () {
            setState(() {
              _productManager.currentProduct = "";
              _section = Section.PRODUCT_ADD;
            });
          },
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add),
        );
        break;

      case Section.PRODUCT_ADD:
        _title = 'My products';
        _body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: TextFormField(
                  controller: _productManager.menu.name,
                  decoration: const InputDecoration(
                    labelText: 'Product name',
                    hintText: 'Canned beans',
                  ),
                )),
            Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  controller: _productManager.menu.servings,
                  decoration: const InputDecoration(
                    labelText: 'Servings',
                    hintText: '2',
                  ),
                )),
            Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  inputFormatters: [DecimalTextInputFormatter()],
                  controller: _productManager.menu.price,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    hintText: '\$3.49',
                  ),
                )),
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Column(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            shape: const StadiumBorder()),
                        onPressed: () {
                          if (!_productManager.menu.isReady()) return;
                          if (_productManager.currentProduct != "") {
                            setState(() {
                              _productManager.products[
                                      _productManager.currentProduct] =
                                  _productManager.menu.getProduct();
                              _section = Section.PRODUCTS;
                            });
                            _productManager.menu.clear();
                            return;
                          }
                          if (_productManager.products
                              .containsKey(_productManager.menu.name.text)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Product with that name already exists')));
                            return;
                          }
                          var newProduct = _productManager.menu.getProduct();
                          setState(() {
                            _productManager.products[newProduct.name] =
                                newProduct;
                            _productManager.menu.clear();
                            _section = Section.PRODUCTS;
                          });
                        },
                        child: Text(
                            _iff(_productManager.currentProduct != "",
                                'Save product', 'Add product'),
                            textScaleFactor: 1.25),
                      ),
                      _createIf(
                          _productManager.currentProduct != "",
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: const StadiumBorder(),
                                primary: Colors.red,
                              ),
                              onPressed: () {
                                setState(() {
                                  _productManager.products
                                      .remove(_productManager.currentProduct);
                                  _productManager.menu.clear();
                                  _section = Section.PRODUCTS;
                                });
                              },
                              child: const Text('Remove product',
                                  textScaleFactor: 1.25),
                            ),
                          )),
                    ],
                  ),
                )),
          ],
        );
        _floatingButton = FloatingActionButton(
          onPressed: () {
            setState(() {
              _productManager.menu.clear();
              _section = Section.PRODUCTS;
            });
          },
          backgroundColor: Colors.blue,
          child: const Icon(Icons.arrow_back_ios_new),
        );
        break;

      case Section.MEALS:
        _title = 'My meals';
        _body = ListView.builder(
          itemCount: _mealManager.meals.length,
          itemBuilder: (context, index) {
            var key = _mealManager.meals.keys.elementAt(index);
            var meal = _mealManager.meals[key];
            if (meal == null) return const SizedBox.shrink();
            return Card(
                child: ListTile(
              title: Text("${meal.name} (\$${meal.price.toStringAsFixed(2)})"),
              onTap: () {
                setState(() {
                  _mealManager.currentMeal = key;
                  _mealManager.menu.name.text = meal.name;
                  for (var ingredient in meal.ingredients) {
                    _mealManager.menu.ingredients[ingredient.product.name] =
                        ingredient;
                  }
                  _section = Section.MEAL_ADD;
                });
              },
            ));
          },
        );
        _floatingButton = FloatingActionButton(
          onPressed: () {
            setState(() {
              _mealManager.currentMeal = "";
              _section = Section.MEAL_ADD;
            });
          },
          backgroundColor: Colors.blue,
          tooltip: 'My meals',
          child: const Icon(Icons.add),
        );
        break;

      case Section.MEAL_ADD:
        _title = 'My meals';
        _body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: TextFormField(
                  controller: _mealManager.menu.name,
                  decoration: const InputDecoration(
                    labelText: 'Meal name',
                    hintText: 'Spaghetti carbonara',
                  ),
                )),
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Container(
                    width: 200,
                    child: Column(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 36),
                            shape: const StadiumBorder(),
                            primary: Colors.blue,
                          ),
                          onPressed: () {
                            setState(() {
                              _productManager.products
                                  .remove(_productManager.currentProduct);
                              _productManager.menu.clear();
                              _section = Section.MEAL_ADD_INGREDIENT;
                            });
                          },
                          child: const Text('Add ingredients',
                              textScaleFactor: 1.25),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: const StadiumBorder(),
                            minimumSize: const Size(double.infinity, 36),
                          ),
                          onPressed: () {
                            if (!_mealManager.menu.isReady()) return;
                            if (_mealManager.currentMeal != "") {
                              setState(() {
                                _mealManager.meals[_mealManager.currentMeal] =
                                    _mealManager.menu.getMeal();
                                _section = Section.MEALS;
                              });
                              _mealManager.menu.clear();
                              return;
                            }
                            if (_mealManager.meals
                                .containsKey(_mealManager.menu.name.text)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Meal with that name already exists')));
                              return;
                            }
                            var newMeal = _mealManager.menu.getMeal();
                            setState(() {
                              _mealManager.meals[newMeal.name] = newMeal;
                              _mealManager.menu.clear();
                              _section = Section.MEALS;
                            });
                          },
                          child: Text(
                              _iff(_productManager.currentProduct != "",
                                  'Save meal', 'Add meal'),
                              textScaleFactor: 1.25),
                        ),
                        _createIf(
                            _productManager.currentProduct != "",
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: const StadiumBorder(),
                                  primary: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    // _productManager.products.remove(_productManager.currentProduct);
                                    // _productManager.menu.clear();
                                    _section = Section.MEALS;
                                  });
                                },
                                child: const Text('Remove meal',
                                    textScaleFactor: 1.25),
                              ),
                            )),
                      ],
                    ),
                  ),
                )),
          ],
        );
        _floatingButton = FloatingActionButton(
          onPressed: () {
            setState(() {
              _mealManager.menu.clear();
              _section = Section.MEALS;
            });
          },
          backgroundColor: Colors.blue,
          tooltip: 'Back',
          child: const Icon(Icons.arrow_back_ios_new),
        );
        break;

      case Section.MEAL_ADD_INGREDIENT:
        _title = 'My meals';
        _body = ListView.builder(
          itemCount: _productManager.products.length,
          itemBuilder: (context, index) {
            var key = _productManager.products.keys.elementAt(index);
            var product = _productManager.products[key];
            if (product == null) return const SizedBox.shrink();
            return Card(
                child: ListTile(
              title: Text(
                  "${product.name} (\$${product.pricePerServing.toStringAsFixed(2)}/serv)"),
              onTap: () {
                setState(() {
                  _productManager.currentProduct = key;
                  _productManager.menu.name.text = product.name;
                  _productManager.menu.servings.text =
                      product.servings.toString();
                  _productManager.menu.price.text = product.price.toString();
                  _section = Section.PRODUCT_ADD;
                });
              },
            ));
          },
        );
        _floatingButton = FloatingActionButton(
          onPressed: () {
            setState(() {
              _productManager.currentProduct = "";
              _section = Section.PRODUCT_ADD;
            });
          },
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add),
        );
        break;

      case Section.SHOPPING_LISTS:
        _title = 'Shopping lists';
        _body = const Center(child: Text('Shopping lists page'));
        break;
    }

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: _body,
      floatingActionButton: _floatingButton,
      drawer: _drawer(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _MyHomePageState();
}

T _iff<T>(cond, T a, T b) {
  if (cond) {
    return a;
  } else {
    return b;
  }
}

Widget _createIf(cond, widget) {
  if (cond) {
    return widget;
  } else {
    return const SizedBox.shrink();
  }
}
