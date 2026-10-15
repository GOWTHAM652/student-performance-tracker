
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AiMentoring extends StatelessWidget {
  const AiMentoring({super.key});

  String getSuggestion(double attendance, double cgpa) {
    if (attendance < 75) {
      return 'Attendance is low. Attend classes regularly and meet your faculty mentor.';
    }

    if (cgpa < 6.0) {
      return 'Focus on core subjects, follow a daily study plan, and ask faculty for support.';
    }

    if (cgpa < 8.0) {
      return 'Good progress. Practise regularly and improve weaker subjects.';
    }

    return 'Excellent progress! Maintain consistency and continue developing your skills.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Mentoring'),
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
              child: Text('No students available'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final data = students[index].data();

              final attendance =
                  (data['Attendance'] as num?)?.toDouble() ?? 0;

              final cgpa =
                  (data['CGPA'] as num?)?.toDouble() ?? 0;

              final suggestion =
                  getSuggestion(attendance, cgpa);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.psychology,
                            color: Colors.purple,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              data['Name']?.toString() ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Attendance: $attendance%'),
                      Text('CGPA: $cgpa'),
                      const Divider(height: 24),
                      const Text(
                        'Mentoring Suggestion',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(suggestion),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
