import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/services.dart';

import 'utils.dart';

class ProductManager {
  var menu = ProductMenu();
  int current = -1;
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
      id: -1,
    );
  }
}

class Product {
  int id;
  String name;
  int servings;
  Decimal price;
  int get priceCents =>
      double.parse((price * Decimal.fromInt(100)).toStringAsFixed(2)).round();

  Decimal get pricePerServing => price / Decimal.fromInt(servings);

  Product({
    required this.name,
    required this.servings,
    required this.price,
    this.id = -1,
  });

  @override
  String toString() {
    return "Product{id: $id, name: $name, servings: $servings, price: $price, priceCents: $priceCents, pricePerServing: $pricePerServing }";
  }
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
    final _products = _state.getProducts();

    return Scaffold(
      appBar: AppBar(title: const Text("My products")),
      body: ListView.builder(
        itemCount: _products.length,
        itemBuilder: (context, index) {
          var product = _products[index];
          return Card(
              child: ListTile(
            title: Text(
                "${product.name} (\$${product.pricePerServing.toStringAsFixed(2)}/serv)"),
            onTap: () {
              setState(() {
                _productManager.current = product.id;
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
            _productManager.current = -1;
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
              controller: _productManager.menu.servings,
              decoration: const InputDecoration(
                labelText: 'Servings',
                hintText: '2',
              ),
            ),
          ),
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
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Column(
                children: [
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(shape: const StadiumBorder()),
                    onPressed: () {
                      if (!_productManager.menu.isReady()) return;
                      var product = _productManager.menu.getProduct();
                      product.id = _productManager.current;
                      setState(() {
                        // If updating existing product
                        if (_productManager.current != -1) {
                          _state.updateProduct(product);
                        } else {
                          _state.addProduct(product);
                        }
                        _productManager.menu.clear();
                      });
                      Navigator.pop(context);
                    },
                    child: Text(
                      iff(_productManager.current != -1, 'Save product',
                          'Add product'),
                      textScaleFactor: 1.25,
                    ),
                  ),
                  createIf(
                    _productManager.current != -1,
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const StadiumBorder(),
                          primary: Colors.red,
                        ),
                        onPressed: () {
                          setState(() {
                            _state.removeProduct(_productManager.current);
                            _productManager.menu.clear();
                          });
                          Navigator.pop(context);
                        },
                        child:
                            const Text('Remove product', textScaleFactor: 1.25),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
