import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'product.dart';
import 'sections.dart';
import 'meal.dart';
import 'utils.dart';
import 'drawer.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Plan My Meals",
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/products': (context) => const ProductsPage(),
        '/products/add': (context) => const ProductsAddPage(),
        '/meals': (context) => const MealsPage(),
        '/meals/add': (context) => const MealsAddPage(),
      },
    );
  }
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final _state = AppState();
    _state.openDB();

    return Scaffold(
      appBar: AppBar(title: const Text("Plan My Meals")),
      body: const Center(child: Text('Home page')),
      drawer: drawer(context, _state),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}
