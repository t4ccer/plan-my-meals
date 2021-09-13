import 'package:flutter/material.dart';

Widget _drawer(context) {
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
      _drawerEntry(context, 'Home', Icons.home, "/"),
      _drawerEntry(
          context, 'Meal planner', Icons.calendar_today_rounded, "/"),
      _drawerEntry(context, 'Shopping lists', Icons.checklist_outlined,
          "/shopping-lists"),
      _drawerEntry(context, 'Stock manager', Icons.now_widgets, "/"),
      _drawerEntry(context, 'Products', Icons.favorite, "/products"),
      _drawerEntry(context, 'Meals', Icons.fastfood, "/meals"),
      _drawerEntry(context, 'Settings', Icons.settings, "/"),
    ],
  ));
}

Widget _drawerEntry(context, name, icon, route) {
  return ListTile(
    leading: Icon(icon),
    title: Text(name),
    onTap: () {
      Navigator.pushNamed(context, route);
    },
  );
}
