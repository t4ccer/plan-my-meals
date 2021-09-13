import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/services.dart';
import 'package:plan_my_meals/utils.dart';

import 'utils.dart';

class ProductManager {
  var menu = ProductMenu();
  var products = {};
  var current = "";
}

class ProductMenu {
  var name = TextEditingController();
  var servings = TextEditingController();
  var price = TextEditingController();

  void clear() {
    name.text = '';
    servings.text = '';
    price.text = '';
  }

  bool isReady() {
    return (name.text != '' && servings.text != '' && price.text != '');
  }

  Product getProduct() {
    return Product(
      name: name.text,
      servings: int.parse(servings.text),
      price: Decimal.parse(price.text),
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

class ProductsPage extends StatefulWidget {
  const ProductsPage({Key? key}) : super(key: key);

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  @override
  Widget build(BuildContext context) {
    final _state = ModalRoute.of(context)!.settings.arguments as AppState;
    final _productManager = _state.productsManager;

    return Scaffold(
      appBar: AppBar(title: const Text("My products")),
      body: ListView.builder(
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
                _productManager.current = key;
                _productManager.menu.name.text = product.name;
                _productManager.menu.servings.text =
                    product.servings.toString();
                _productManager.menu.price.text = product.price.toString();
              });
              Navigator.pushNamed(context, '/products/add', arguments: _state)
                  .then((_) => setState(() {}));
            },
          ));
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          setState(() {
            _productManager.menu.clear();
            _productManager.current = '';
          });
          Navigator.pushNamed(context, '/products/add', arguments: _state)
              .then((_) => setState(() {}));
        },
      ),
    );
  }
}

class ProductsAddPage extends StatefulWidget {
  const ProductsAddPage({Key? key}) : super(key: key);

  @override
  State<ProductsAddPage> createState() => _ProductsAddPageState();
}

class _ProductsAddPageState extends State<ProductsAddPage> {
  @override
  Widget build(BuildContext context) {
    final _state = ModalRoute.of(context)!.settings.arguments as AppState;
    final _productManager = _state.productsManager;

    return Scaffold(
      appBar: AppBar(title: const Text("Add product")),
      body: Column(
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

                        setState(() {
                          if (_productManager.current != '') {
                            _productManager.products
                                .remove(_productManager.current);
                          }

                          var product = _productManager.menu.getProduct();
                          _productManager.products[product.name] = product;
                          _productManager.menu.clear();
                        });
                        Navigator.pop(context);
                      },
                      child: Text(
                          iff(_productManager.current != '', 'Save product',
                              'Add product'),
                          textScaleFactor: 1.25),
                    ),
                    createIf(
                        _productManager.current != '',
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
                                    .remove(_productManager.current);
                                _productManager.menu.clear();
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Remove product',
                                textScaleFactor: 1.25),
                          ),
                        )),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
