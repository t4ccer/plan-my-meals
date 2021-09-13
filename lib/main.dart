import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:decimal/decimal.dart';

void main() => runApp(const MyApp());

enum Section { HOME, PRODUCTS, PRODUCT_ADD, MEALS, SHOPPING_LISTS }

class Product {
  String name;
  int servings;
  Decimal price;

  Product({
    required this.name,
    required this.servings,
    required this.price,
  });
}

class Ingredient {
  late Product product;
  late int servings;
}

class Meal {
  late List<Ingredient> ingredients;
}

class DecimalTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final regEx = RegExp(r"^\d*\.?(\d{0,2})");
    String newString = regEx.stringMatch(newValue.text) ?? "";
    return newString == newValue.text ? newValue : oldValue;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const appTitle = 'Drawer Demo';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(), // TODO: Dark theme is ugly, change it
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class _MyHomePageState extends State<HomePage> {
  Section _section = Section.HOME;
  final _products = <Product>[]; //TODO use map or sth
  final TextEditingController _addProductName = TextEditingController();
  final TextEditingController _addProductServings = TextEditingController();
  final TextEditingController _addProductPrice = TextEditingController();
  int _currentProduct = -1;

  @override
  Widget build(BuildContext context) {
    Widget _body, _floatingButton;
    String _title = "Plan My Meals";
    _floatingButton = const SizedBox.shrink();

    Widget _addDrawerEntry(context, name, icon, section) {
      return ListTile(
        leading: Icon(icon),
        title: Text(name),
        onTap: () {
          Navigator.pop(context);
          setState(() {
            _section = section;
          });
        },
      );
    }

    switch (_section) {
      case Section.HOME:
        _body = const Center(child: Text('Main page'));
        break;

      case Section.PRODUCTS:
        _title = "My products";
        _body = ListView.builder(
          itemCount: _products.length,
          itemBuilder: (context, index) {
            return Card(
                child: ListTile(
                    title: Text(_products[index].name),
                    onTap: () {
                      setState(() {
                        _currentProduct = index;
                        _addProductName.text = _products[index].name;
                        _addProductServings.text =
                            _products[index].servings.toString();
                        _addProductPrice.text =
                            _products[index].price.toString();
                        _section = Section.PRODUCT_ADD;
                      });
                    }));
          },
        );
        _floatingButton = FloatingActionButton(
          onPressed: () {
            setState(() {
              _currentProduct = -1;
              _section = Section.PRODUCT_ADD;
            });
          },
          backgroundColor: Colors.blue,
          tooltip: 'Add product',
          child: const Icon(Icons.add),
        );
        break;

      case Section.PRODUCT_ADD:
        _title = 'Add new product';
        _body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: TextFormField(
                  controller: _addProductName,
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
                  controller: _addProductServings,
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
                  controller: _addProductPrice,
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
                          if (_currentProduct >= 0) {
                            setState(() {
                              _products[_currentProduct] = (Product(
                                name: _addProductName.text,
                                servings: int.parse(_addProductServings.text),
                                price: Decimal.parse(_addProductPrice.text),
                              ));
                              _addProductName.text = '';
                              _addProductServings.text = '';
                              _addProductPrice.text = '';
                              _section = Section.PRODUCTS;
                            });
                            return;
                          }

                          if (_addProductName.text == '') return;
                          // ignore: iterable_contains_unrelated_type
                          if (_products.contains(_addProductName.text)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Product with that name already exists')));
                            return;
                          }
                          setState(() {
                            _products.add(Product(
                              name: _addProductName.text,
                              servings: int.parse(_addProductServings.text),
                              price: Decimal.parse(_addProductPrice.text),
                            ));
                            _addProductName.text = '';
                            _addProductServings.text = '';
                            _addProductPrice.text = '';
                            _section = Section.PRODUCTS;
                          });
                        },
                        child: Text(
                            _iff(_currentProduct >= 0, 'Save product',
                                'Add product'),
                            textScaleFactor: 1.25),
                      ),
                      _createIf(
                          _currentProduct >= 0,
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: const StadiumBorder(),
                                primary: Colors.red,
                              ),
                              onPressed: () {
                                setState(() {
                                  _products.removeAt(_currentProduct);
                                  _addProductName.text = '';
                                  _addProductServings.text = '';
                                  _addProductPrice.text = '';
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
              _addProductName.text = '';
              _addProductServings.text = '';
              _addProductPrice.text = '';
              _section = Section.PRODUCTS;
            });
          },
          tooltip: 'Back',
          backgroundColor: Colors.blue,
          child: const Icon(Icons.arrow_back_ios_new),
        );
        break;

      case Section.MEALS:
        _title = 'My meals';
        _body = const Center(child: Text('Meals page'));
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
      drawer: Drawer(
          child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.fill,
                  image: AssetImage('img/drawer-header.png'),
                ),
              ),
              child: Stack(children: const <Widget>[
                Positioned(
                    bottom: 12.0,
                    left: 16.0,
                    child: Text("Plan My Meals",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.0,
                            fontWeight: FontWeight.w500))),
              ])),
          _addDrawerEntry(context, 'Home', Icons.home, Section.HOME),
          _addDrawerEntry(context, 'Meal planner', Icons.calendar_today_rounded,
              Section.HOME),
          _addDrawerEntry(context, 'Shopping lists', Icons.checklist_outlined,
              Section.SHOPPING_LISTS),
          _addDrawerEntry(
              context, 'Stock manager', Icons.now_widgets, Section.HOME),
          _addDrawerEntry(
              context, 'Products', Icons.favorite, Section.PRODUCTS),
          _addDrawerEntry(context, 'Meals', Icons.fastfood, Section.MEALS),
          _addDrawerEntry(context, 'Settings', Icons.settings, Section.HOME),
        ],
      )),
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
