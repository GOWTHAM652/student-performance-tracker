
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentPerformance extends StatelessWidget {
  const StudentPerformance({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Performance'),
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
              child: Text('No student records found'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final data = students[index].data();
              final marks = data['Subject Marks'];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(
                    data['Name']?.toString() ?? 'Unknown',
                  ),
                  subtitle: Text(
                    'Register No: ${data['RegisterNumber'] ?? students[index].id}\n'
                    'Attendance: ${data['Attendance'] ?? 0}%\n'
                    'SGPA: ${data['SGPA'] ?? 0} | '
                    'CGPA: ${data['CGPA'] ?? 0}',
                  ),
                  children: [
                    if (marks is Map && marks.isNotEmpty)
                      ...marks.entries.map(
                        (entry) => ListTile(
                          title: Text(entry.key.toString()),
                          trailing: Text(
                            '${entry.value} / 100',
                          ),
                        ),
                      )
                    else
                      const ListTile(
                        title: Text(
                          'Subject marks not found in Firestore',
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
