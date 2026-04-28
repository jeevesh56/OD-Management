import 'package:flutter/material.dart';

final timetable = {
  "Monday": [
    {"time": "08:00–08:50", "subject": "DBMS"},
    {"time": "08:50–09:40", "subject": "MLT"},
    {"time": "10:10–11:00", "subject": "DBMS"},
    {"time": "11:00–11:50", "subject": "DAA"},
    {"time": "11:50–12:40", "subject": "TOC"},
    {"time": "01:30–03:00", "subject": "OS LAB", "isLab": true},
  ],
  "Tuesday": [
    {"time": "08:00–09:40", "subject": "DBMS LAB", "isLab": true},
    {"time": "10:10–11:00", "subject": "SDP"},
    {"time": "11:00–11:50", "subject": "TOC"},
    {"time": "11:50–12:40", "subject": "DAA"},
    {"time": "01:30–02:15", "subject": "DBMS"},
    {"time": "02:15–03:00", "subject": "OS"},
  ],
  "Wednesday": [
    {"time": "08:00–08:50", "subject": "MLT"},
    {"time": "08:50–09:40", "subject": "Placement"},
    {"time": "10:10–11:00", "subject": "MLT"},
    {"time": "11:00–11:50", "subject": "DBMS"},
    {"time": "11:50–12:40", "subject": "OS"},
    {"time": "01:30–02:15", "subject": "TOC"},
  ],
  "Thursday": [
    {"time": "08:00–08:50", "subject": "TOC"},
    {"time": "08:50–09:40", "subject": "Placement"},
    {"time": "10:10–11:00", "subject": "SDP"},
    {"time": "11:00–12:40", "subject": "DAA LAB", "isLab": true},
    {"time": "01:30–02:15", "subject": "OS"},
    {"time": "02:15–03:00", "subject": "DAA"},
  ],
  "Friday": [
    {"time": "08:00–09:40", "subject": "MLT LAB", "isLab": true},
    {"time": "10:10–11:00", "subject": "TOC"},
    {"time": "11:00–11:50", "subject": "SDP"},
    {"time": "11:50–12:40", "subject": "MLT"},
    {"time": "01:30–02:15", "subject": "DAA"},
    {"time": "02:15–03:00", "subject": "OS"},
  ],
};

class TimetablePage extends StatelessWidget {
  const TimetablePage({super.key});

  static const periods = ["P1", "P2", "P3", "P4", "P5", "P6", "P7"];
  static const days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"];

  @override
  Widget build(BuildContext context) {
    // Build a grid: Rows = Days, Columns = Periods
    // For demo, map each slot to a period (by index)
    return Scaffold(
      appBar: AppBar(title: const Text("Timetable")),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            const DataColumn(label: Text("Day")),
            ...periods.map((p) => DataColumn(label: Text(p))),
          ],
          rows: days.map((day) {
            final slots = timetable[day] ?? [];
            return DataRow(
              cells: [
                DataCell(Text(day)),
                ...List.generate(periods.length, (i) {
                  if (i < slots.length) {
                    final slot = slots[i];
                    return DataCell(Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(slot["subject"] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: slot["isLab"] == true
                                  ? Colors.blue
                                  : null,
                            )),
                        Text(slot["time"] as String,
                            style: const TextStyle(fontSize: 11)),
                      ],
                    ));
                  } else {
                    return const DataCell(Text("-"));
                  }
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
