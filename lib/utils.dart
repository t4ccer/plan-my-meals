import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'product.dart';
import 'meal.dart';

class DecimalTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final regEx = RegExp(r"^\d*\.?(\d{0,2})");
    String newString = regEx.stringMatch(newValue.text) ?? "";
    return newString == newValue.text ? newValue : oldValue;
  }
}

class AppState {
  var productsManager = ProductManager();
  var mealsManager = MealsManager();
}

T iff<T>(cond, T a, T b) {
  if (cond) {
    return a;
  } else {
    return b;
  }
}

Widget createIf(cond, widget) {
  if (cond) {
    return widget;
  } else {
    return const SizedBox.shrink();
  }
}
