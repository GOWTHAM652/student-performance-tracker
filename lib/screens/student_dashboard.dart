
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'student_profile.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Student Dashboard')),
        body: const Center(
          child: Text('Please log in to continue.'),
        ),
      );
    }

    final email = user.email!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .where('Email', isEqualTo: email)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load student data.'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Student record not found for this email.'),
            );
          }

          final data = snapshot.data!.docs.first.data();
          final name = data['Name']?.toString() ?? 'Student';
          final registerNo = data['RegisterNumber']?.toString() ?? '-';
          final attendance = _toDouble(data['Attendance']);
          final sgpa = data['SGPA']?.toString() ?? '-';
          final cgpa = data['CGPA']?.toString() ?? '-';

          final rawMarks = data['Subject Marks'];
          final marks = rawMarks is Map
              ? Map<String, dynamic>.from(rawMarks)
              : <String, dynamic>{};

          final average = marks.isEmpty
              ? 0.0
              : marks.values.map(_toDouble).fold<double>(
                    0,
                    (total, mark) => total + mark,
                  ) /
                  marks.length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: Colors.indigo,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'S',
                          style: const TextStyle(
                            fontSize: 26,
                            color: Colors.indigo,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome back!',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              registerNo,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                icon: const Icon(Icons.person),
                label: const Text('My Profile'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentProfile(email: email),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
              _sectionTitle('Academic Overview'),

              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      'Attendance',
                      '${attendance.toStringAsFixed(1)}%',
                      Icons.calendar_month,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _statCard(
                      'SGPA',
                      sgpa,
                      Icons.grade,
                      Colors.orange,
                    ),
                  ),
                ],
              ),

              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      'CGPA',
                      cgpa,
                      Icons.school,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _statCard(
                      'Average Marks',
                      marks.isEmpty
                          ? '-'
                          : '${average.toStringAsFixed(1)}%',
                      Icons.bar_chart,
                      Colors.purple,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _sectionTitle('Attendance Progress'),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attendance: ${attendance.toStringAsFixed(1)}%',
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: (attendance / 100).clamp(0.0, 1.0),
                        minHeight: 9,
                        color: attendance >= 75 ? Colors.green : Colors.red,
                        backgroundColor: Colors.grey.shade200,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        attendance >= 75
                            ? 'Attendance is at least 75%.'
                            : 'Attendance is below 75%. Please improve it.',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              _sectionTitle('Subject Performance'),

              if (marks.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No subject marks available.'),
                  ),
                )
              else
                ...marks.entries.map((entry) {
                  final mark = _toDouble(entry.value);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(entry.key)),
                              Text(
                                '${mark.toStringAsFixed(0)}/100',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: (mark / 100).clamp(0.0, 1.0),
                            minHeight: 7,
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 20),
              _sectionTitle('AI Mentoring'),

              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.psychology),
                  ),
                  title: const Text('Academic Suggestions'),
                  subtitle: Text(
                    _mentoringAdvice(attendance, average, marks.isNotEmpty),
                  ),
                  isThreeLine: true,
                ),
              ),

              const SizedBox(height: 16),

              ListTile(
                leading: const Icon(Icons.person, color: Colors.indigo),
                title: const Text('My Profile'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentProfile(email: email),
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout'),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _mentoringAdvice(
    double attendance,
    double average,
    bool hasMarks,
  ) {
    final advice = <String>[];

    if (attendance < 75) {
      advice.add('Improve attendance to reach 75% or above.');
    }

    if (!hasMarks) {
      advice.add('Subject marks are not available yet.');
    } else if (average < 60) {
      advice.add('Revise subjects with lower marks and practise daily.');
    } else if (average >= 80) {
      advice.add('Good performance! Continue your study routine.');
    } else {
      advice.add('Review difficult topics and take practice tests.');
    }

    return advice.join('\n');
  }

  static Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: Colors.indigo,
        ),
      ),
    );
  }

  static Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.all(5),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
