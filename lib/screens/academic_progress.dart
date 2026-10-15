
import 'package:flutter/material.dart';
import '../models/student_model.dart';
import '../services/performance_service.dart';

class AcademicProgress extends StatelessWidget {
  final Student student;

  const AcademicProgress({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    final service = PerformanceService();
    final average = service.calculateAverage(student);
    final weakSubjects = service.getWeakSubjects(student);

    final status = average >= 75
        ? 'Good Performance'
        : average >= 60
            ? 'Average Performance'
            : 'Needs Improvement';

    final statusColor = average >= 75
        ? Colors.green
        : average >= 60
            ? Colors.orange
            : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Progress'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Academic Progress',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'View your academic performance',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 20),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.person,
                color: Colors.blue,
                size: 40,
              ),
              title: Text(
                student.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Register No: ${student.registerNumber}\n'
                'Department: ${student.department}\n'
                'Semester: ${student.semester}',
              ),
              isThreeLine: true,
            ),
          ),

          _progressCard(
            'Attendance',
            '${student.attendance.toStringAsFixed(1)}%',
            Icons.calendar_month,
            student.attendance >= 75 ? Colors.green : Colors.red,
          ),
          _progressCard(
            'Average Marks',
            '${average.toStringAsFixed(1)} / 100',
            Icons.school,
            Colors.green,
          ),
          _progressCard(
            'SGPA',
            student.sgpa.toStringAsFixed(2),
            Icons.trending_up,
            Colors.orange,
          ),
          _progressCard(
            'CGPA',
            student.cgpa.toStringAsFixed(2),
            Icons.assessment,
            Colors.purple,
          ),

          Card(
            child: ListTile(
              leading: Icon(Icons.flag, color: statusColor, size: 40),
              title: const Text(
                'Performance Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(status),
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'Subject-wise Marks',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          ...student.subjectMarks.entries.map((entry) {
            final mark = entry.value;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(entry.key)),
                        Text(
                          '${mark.toStringAsFixed(0)} / 100',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: mark < 60 ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (mark / 100).clamp(0.0, 1.0),
                      color: mark < 60 ? Colors.red : Colors.green,
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 20),
          const Text(
            'Subjects to Improve',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          if (weakSubjects.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('No weak subjects identified.'),
                subtitle: Text('Continue your regular revision.'),
              ),
            )
          else
            ...weakSubjects.map(
              (subject) => Card(
                child: ListTile(
                  leading: const Icon(Icons.menu_book, color: Colors.red),
                  title: Text(subject),
                  subtitle: const Text(
                    'Revise this subject and practise questions regularly.',
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),
          Card(
            color: Colors.blue.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Target: Improve your average marks towards 85/100 '
                'and maintain attendance at 75% or above.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color, size: 40),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(value, style: const TextStyle(fontSize: 17)),
      ),
    );
  }
}
