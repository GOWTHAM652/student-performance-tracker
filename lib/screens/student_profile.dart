
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProfile extends StatelessWidget {
  final String email;

  const StudentProfile({
    super.key,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('students')
            .where('Email', isEqualTo: email)
            .limit(1)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load profile. Please try again.',
              ),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Student profile not found'),
            );
          }

          final data = snapshot.data!.docs.first.data();

          final name = data['Name']?.toString() ?? 'Student';
          final registerNumber =
              data['RegisterNumber']?.toString() ?? '-';
          final studentEmail = data['Email']?.toString() ?? email;
          final department = data['Department']?.toString() ?? '-';
          final batch = data['Batch']?.toString() ?? '-';
          final semester = data['Semester']?.toString() ?? '-';

          final attendance = data['Attendance'] ?? '-';
          final sgpa = data['SGPA'] ?? '-';
          final cgpa = data['CGPA'] ?? '-';

          final marks = data['Subject Marks'] is Map
              ? Map<String, dynamic>.from(data['Subject Marks'])
              : <String, dynamic>{};

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.indigo.shade100,
                      child: Text(
                        name.isNotEmpty
                            ? name[0].toUpperCase()
                            : 'S',
                        style: const TextStyle(
                          fontSize: 36,
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      registerNumber,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _heading('Personal Details'),
              _detail('Full Name', name, Icons.person),
              _detail(
                'Register Number',
                registerNumber,
                Icons.badge,
              ),
              _detail(
                'Email',
                studentEmail,
                Icons.email,
              ),

              const SizedBox(height: 18),

              _heading('Academic Details'),
              _detail(
                'Department',
                department,
                Icons.school,
              ),
              _detail('Batch', batch, Icons.calendar_month),
              _detail('Semester', semester, Icons.menu_book),

              const SizedBox(height: 18),

              _heading('Academic Performance'),
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      'Attendance',
                      '$attendance${attendance is num || attendance is String ? '%' : ''}',
                      Icons.event_available,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statCard(
                      'SGPA',
                      '$sgpa',
                      Icons.grade,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statCard(
                      'CGPA',
                      '$cgpa',
                      Icons.school,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              _heading('Subject Marks'),
              if (marks.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No subject marks available'),
                  ),
                )
              else
                ...marks.entries.map((entry) {
                  final value = entry.value;
                  final numericMark = value is num
                      ? value.toDouble()
                      : double.tryParse('$value') ?? 0;

                  final progress =
                      (numericMark / 100).clamp(0.0, 1.0);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '$value/100',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            color: Colors.indigo,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _heading(String title) {
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

  Widget _detail(
    String label,
    String value,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo),
        title: Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      color: Colors.indigo.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 4,
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.indigo, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
