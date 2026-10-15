
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AcademicReports extends StatelessWidget {
  const AcademicReports({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Reports'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final students = snapshot.data?.docs ?? [];

          if (students.isEmpty) {
            return const Center(
              child: Text('No academic records found'),
            );
          }

          double attendanceTotal = 0;
          double sgpaTotal = 0;
          double cgpaTotal = 0;

          for (final doc in students) {
            final data = doc.data();
            attendanceTotal +=
                (data['Attendance'] as num?)?.toDouble() ?? 0;
            sgpaTotal +=
                (data['SGPA'] as num?)?.toDouble() ?? 0;
            cgpaTotal +=
                (data['CGPA'] as num?)?.toDouble() ?? 0;
          }

          final count = students.length;

          final averageAttendance = attendanceTotal / count;
          final averageSGPA = sgpaTotal / count;
          final averageCGPA = cgpaTotal / count;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Academic Summary',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _reportCard(
                'Total Students',
                '$count',
                Icons.people,
                Colors.blue,
              ),
              _reportCard(
                'Average Attendance',
                '${averageAttendance.toStringAsFixed(1)}%',
                Icons.fact_check,
                Colors.green,
              ),
              _reportCard(
                'Average SGPA',
                averageSGPA.toStringAsFixed(2),
                Icons.school,
                Colors.orange,
              ),
              _reportCard(
                'Average CGPA',
                averageCGPA.toStringAsFixed(2),
                Icons.analytics,
                Colors.purple,
              ),

              const SizedBox(height: 24),

              _sectionTitle('CGPA Comparison'),
              _chartCard(
                child: Column(
                  children: students.map((doc) {
                    final data = doc.data();
                    final name =
                        data['Name']?.toString() ?? 'Unknown';
                    final cgpa =
                        (data['CGPA'] as num?)?.toDouble() ?? 0;
                    final value = cgpa.clamp(0.0, 10.0);

                    return _bar(
                      label: name,
                      value: value / 10,
                      valueText: cgpa.toStringAsFixed(1),
                      color: Colors.purple,
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              _sectionTitle('Attendance Overview'),
              _chartCard(
                child: Column(
                  children: students.map((doc) {
                    final data = doc.data();
                    final name =
                        data['Name']?.toString() ?? 'Unknown';
                    final attendance =
                        (data['Attendance'] as num?)
                            ?.toDouble() ??
                        0;
                    final value =
                        (attendance / 100).clamp(0.0, 1.0);

                    return _bar(
                      label: name,
                      value: value,
                      valueText:
                          '${attendance.toStringAsFixed(1)}%',
                      color: Colors.green,
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              _sectionTitle('Student Academic Records'),
              const SizedBox(height: 8),

              ...students.map((doc) {
                final data = doc.data();
                final marks = data['Subject Marks'];

                return Card(
                  child: ExpansionTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(
                      data['Name']?.toString() ?? 'Unknown',
                    ),
                    subtitle: Text(
                      'Register No: '
                      '${data['RegisterNumber'] ?? doc.id}\n'
                      'Attendance: ${data['Attendance'] ?? 0}%\n'
                      'SGPA: ${data['SGPA'] ?? 0} | '
                      'CGPA: ${data['CGPA'] ?? 0}',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Semester: '
                              '${data['Semester'] ?? '-'}',
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Subject Marks',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            if (marks is Map &&
                                marks.isNotEmpty)
                              ...marks.entries.map((entry) {
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    entry.key.toString(),
                                  ),
                                  trailing: Text(
                                    entry.value.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              })
                            else
                              const Text(
                                'Subject marks not found',
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _chartCard({required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _bar({
    required String label,
    required double value,
    required String valueText,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                valueText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
