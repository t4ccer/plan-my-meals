import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';

class ProductManager {
  var menu = ProductMenu();
  var products = {};
  var currentProduct = "";
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

