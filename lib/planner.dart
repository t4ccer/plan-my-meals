import 'package:flutter/material.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'dart:developer' as developer;

import 'meal.dart';
import 'product.dart';
import 'utils.dart';

class MealPlannerDataSource extends CalendarDataSource {
  MealPlannerDataSource(List<Appointment> source) {
    appointments = source;
  }
}

class PlannedMeal {
  int id;
  DateTime date;
  Meal meal;
  bool done;

  PlannedMeal({
    required this.date,
    required this.meal,
    required this.done,
    this.id = -1,
  });
}

class MealPlanner {
  Database db;
  MealsManager mealsManager;
  ProductManager productsManager;
  int current = -1;
  DateTime currentDate = DateTime.fromMillisecondsSinceEpoch(0);

  MealPlanner({
    required this.db,
    required this.mealsManager,
    required this.productsManager,
  });

  void addPlannedMeal(PlannedMeal plannedMeal) {
    final q = db.prepare(
        'INSERT INTO planned_meals (meal_id, date, done) VALUES (?, ?, ?)');
    q.execute([
      plannedMeal.meal.id,
      plannedMeal.date.millisecondsSinceEpoch,
      plannedMeal.done ? 1 : 0
    ]);
    q.dispose();
  }

  void updatePlannedMeal(PlannedMeal plannedMeal) {
    final q = db.prepare('UPDATE planned_meals SET done = ? where id = ?');
    q.execute([plannedMeal.done ? 1 : 0, plannedMeal.id]);
    q.dispose();
  }

  void updateUsedProducts(PlannedMeal plannedMeal) {
    for (var ingr in plannedMeal.meal.ingredients) {
      var p = ingr.product;
      p.amount = plannedMeal.done
          ? p.amount - ingr.servings
          : p.amount + ingr.servings;
      productsManager.updateProduct(p);
    }
  }

  void removePlannedMeal(int id) {
    final q = db.prepare('DELETE FROM planned_meals WHERE id = ?');
    q.execute([id]);
    q.dispose();
  }

  Map<int, PlannedMeal> getPlannedMeals() {
    final rows = db.select(
        'SELECT planned_meals.id AS plannedId, planned_meals.date AS plannedDate, planned_meals.done AS plannedDone, meals.id as mealId, meals.name as mealName, meals.servings as mealServings FROM planned_meals INNER JOIN meals ON planned_meals.meal_id = meals.id');
    developer.log(rows.toString(), name: 'tmm.db.getPlannedMeals');
    Map<int, PlannedMeal> res = {};
    for (final row in rows) {
      res[row['plannedId']] = PlannedMeal(
        id: row['plannedId'],
        date: DateTime.fromMillisecondsSinceEpoch(row['plannedDate']),
        meal: Meal(
          id: row['mealId'],
          name: row['mealName'],
          servings: row['mealServings'].round(),
          ingredients: mealsManager.getIngredients(row['mealId']),
        ),
        done: row['plannedDone'] == 1,
      );
    }
    return res;
  }

  Appointment _addCalendarMeal(PlannedMeal plannedMeal) {
    var color = plannedMeal.done ? const Color(0xff90caf9) : Colors.blue;
    return Appointment(
      startTime: plannedMeal.date,
      endTime: plannedMeal.date.add(const Duration(milliseconds: 1)),
      isAllDay: true,
      subject: plannedMeal.meal.name,
      color: color,
      notes: '${plannedMeal.id}',
      startTimeZone: '',
      endTimeZone: '',
    );
  }

  MealPlannerDataSource getCalendarDataSource() {
    List<Appointment> appointments = <Appointment>[];

    var now = DateTime.now();
    now = DateTime(now.year, now.month, now.day, 23, 59, 58, now.millisecond,
        now.microsecond);

    appointments.add(Appointment(
      startTime: now.add(const Duration(days: -365)),
      endTime:
          now.add(const Duration(days: -365)).add(const Duration(seconds: 1)),
      isAllDay: true,
      subject: "Plan meal",
      color: const Color(0xffbfbfbf),
      notes: "PLAN_MEAL",
      recurrenceRule: 'FREQ=DAILY',
    ));

    getPlannedMeals().forEach((k, v) => appointments.add(_addCalendarMeal(v)));

    return MealPlannerDataSource(appointments);
  }
}

class MealPlannerPage extends StatefulWidget {
  const MealPlannerPage({Key? key}) : super(key: key);

  @override
  State<MealPlannerPage> createState() => _MealPlannerPageState();
}

class _MealPlannerPageState extends State<MealPlannerPage> {
  @override
  Widget build(BuildContext context) {
    final _state = ModalRoute.of(context)!.settings.arguments as AppState;

    return Scaffold(
      appBar: AppBar(title: const Text("Meal planner")),
      body: Center(
        child: SfCalendar(
          view: CalendarView.schedule,
          firstDayOfWeek: 1, // Monday - TODO: Make it customizable
          dataSource: _state.planner!.getCalendarDataSource(),
          scheduleViewSettings: const ScheduleViewSettings(
            appointmentItemHeight: 50,
          ),
          onTap: (CalendarTapDetails details) {
            dynamic appointment = details.appointments![0];
            if (appointment.notes == 'PLAN_MEAL') {
              setState(() {
                _state.planner?.currentDate = details.date!;
                Navigator.pushNamed(context, '/planner/add', arguments: _state)
                    .then((_) => setState(() {}));
              });
            } else {
              setState(() {
                var id = int.parse(appointment.notes);
                var plannedMeal =
                    _state.planner?.getPlannedMeals()[id] as PlannedMeal;
                plannedMeal.done = !plannedMeal.done;
                _state.planner?.updatePlannedMeal(plannedMeal);
                _state.planner?.updateUsedProducts(plannedMeal);
              });
            }
          },
          onLongPress: (CalendarLongPressDetails details) {
            dynamic appointment = details.appointments![0];
            int id = int.parse(appointment.notes);
            if (appointment.notes == 'PLAN_MEAL') return;
            setState(() {
              var plannedMeal =
                  _state.planner?.getPlannedMeals()[id] as PlannedMeal;
              plannedMeal.done = false;
              _state.planner?.updatePlannedMeal(plannedMeal);
              _state.planner?.updateUsedProducts(plannedMeal);
              _state.planner?.removePlannedMeal(id);
            });
          },
        ),
      ),
    );
  }
}

class MealPlannerAddPage extends StatefulWidget {
  const MealPlannerAddPage({Key? key}) : super(key: key);

  @override
  State<MealPlannerAddPage> createState() => _MealPlannerAddPageState();
}

class _MealPlannerAddPageState extends State<MealPlannerAddPage> {
  @override
  Widget build(BuildContext context) {
    final _state = ModalRoute.of(context)!.settings.arguments as AppState;
    final _meals = _state.mealsManager?.getMeals() as List<Meal>;

    return Scaffold(
      appBar: AppBar(title: const Text("Plan meal")),
      body: ListView.builder(
        itemCount: _meals.length,
        itemBuilder: (context, index) {
          var meal = _meals[index];
          return Card(
              child: ListTile(
            title: Text("${meal.name} (\$${meal.price.toStringAsFixed(2)})"),
            onTap: () {
              if (_state.planner?.currentDate != null) {
                setState(() {
                  _state.planner?.addPlannedMeal(PlannedMeal(
                    date: (_state.planner?.currentDate) as DateTime,
                    meal: meal,
                    done: false,
                  ));
                });
              }
              Navigator.pop(context);
            },
          ));
        },
      ),
    );
  }
}
