import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:decimal/decimal.dart';

void main() => runApp(const MyApp());

enum Section { HOME, PRODUCTS, PRODUCT_ADD, MEALS, SHOPPING_LISTS }

class ProductMenu {
  TextEditingController productName = TextEditingController();
  TextEditingController productServings = TextEditingController();
  TextEditingController productPrice = TextEditingController();

  void clear() {
    productName.text = '';
    productServings.text = '';
    productPrice.text = '';
  }

  bool isReady() {
    return (productName.text != '' &&
        productServings.text != '' &&
        productPrice.text != '');
  }

  Product getProduct() {
    return Product(
      name: productName.text,
      servings: int.parse(productServings.text),
      price: Decimal.parse(productPrice.text),
    );
  }
}

class Product {
  String name;
  int servings;
  Decimal price;

  Decimal get pricePerServing => price / Decimal.fromInt(servings);

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
  final Map<String, Product> _products = {};
  final ProductMenu _productMenu = ProductMenu();
  String _currentProduct = "";

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
            var key = _products.keys.elementAt(index);
            var product = _products[key];
            if (product == null) return const SizedBox.shrink();
            return Card(
                child: ListTile(
                  title: Text("${product.name} (\$${product.pricePerServing.toStringAsFixed(2)}/serv)"),
              onTap: () {
                setState(() {
                  _currentProduct = key;
                  _productMenu.productName.text = product.name;
                  _productMenu.productServings.text =
                      product.servings.toString();
                  _productMenu.productPrice.text = product.price.toString();
                  _section = Section.PRODUCT_ADD;
                });
              },
            ));
          },
        );
        _floatingButton = FloatingActionButton(
          onPressed: () {
            setState(() {
              _currentProduct = "";
              _section = Section.PRODUCT_ADD;
            });
          },
          backgroundColor: Colors.blue,
          tooltip: 'Add product',
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
                  controller: _productMenu.productName,
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
                  controller: _productMenu.productServings,
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
                  controller: _productMenu.productPrice,
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
                          if (!_productMenu.isReady()) return;

                          if (_currentProduct != "") {
                            setState(() {
                              _products[_currentProduct] =
                                  _productMenu.getProduct();
                              _section = Section.PRODUCTS;
                            });
                            _productMenu.clear();
                            return;
                          }

                          // ignore: iterable_contains_unrelated_type
                          if (_products.containsKey(_productMenu.productName.text)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Product with that name already exists')));
                            return;
                          }
                          var newProduct = _productMenu.getProduct();
                          setState(() {
                            _products[newProduct.name] = newProduct;
                            _productMenu.clear();
                            _section = Section.PRODUCTS;
                          });
                        },
                        child: Text(
                            _iff(_currentProduct != "", 'Save product',
                                'Add product'),
                            textScaleFactor: 1.25),
                      ),
                      _createIf(
                          _currentProduct != "",
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: const StadiumBorder(),
                                primary: Colors.red,
                              ),
                              onPressed: () {
                                setState(() {
                                  _products.remove(_currentProduct);
                                  _productMenu.clear();
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
              _productMenu.clear();
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
