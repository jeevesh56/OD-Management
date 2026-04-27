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
  const TimetablePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Timetable")),
      body: ListView(
        children: timetable.entries.map((day) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.key,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ...day.value.map<Widget>((slot) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: slot["isLab"] == true
                          ? Colors.blue.withOpacity(0.2)
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(slot["time"] as String),
                        Text(
                          slot["subject"] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
