import 'package:flutter/material.dart';

Widget drawer(context, state) {
  Widget _drawerEntry(name, icon, route) {
    return ListTile(
      leading: Icon(icon),
      title: Text(name),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route, arguments: state);
      },
    );
  }

  return Drawer(
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
      ListTile(
        leading: const Icon(Icons.home),
        title: const Text('Home'),
        onTap: () {
          Navigator.pop(context);
        },
      ),
      _drawerEntry('Meal planner', Icons.calendar_today_rounded, "/planner"),
      // _drawerEntry(
      //     'Shopping lists', Icons.checklist_outlined, "/shopping-lists"),
      // _drawerEntry('Stock manager', Icons.now_widgets, "/"),
      _drawerEntry('Products', Icons.favorite, "/products"),
      _drawerEntry('Meals', Icons.fastfood, "/meals"),
      // _drawerEntry('Settings', Icons.settings, "/"),
    ],
  ));
}
