
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'student_profile.dart';
import 'student_performance.dart';
import 'academic_reports.dart';
import 'ai_mentoring.dart';

class FacultyDashboard extends StatefulWidget {
  const FacultyDashboard({super.key});

  @override
  State<FacultyDashboard> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard> {
  final TextEditingController searchController = TextEditingController();

  String searchText = '';
  String selectedDepartment = 'All';
  String selectedSemester = 'All';

  final List<String> departments = [
    'All',
    'Computer Science and Engineering',
    'Artificial Intelligence and Data Science',
    'Artificial Intelligence and Machine Learning',
    'Electrical and Electronics Engineering',
    'Electronics and Communication Engineering',
    'Information Technology',
  ];

  final List<String> semesters = [
    'All', '1', '2', '3', '4', '5', '6', '7'
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void openStudentProfile(String email) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentProfile(email: email),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading students: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allStudents = snapshot.data?.docs ?? [];

          final filteredStudents = allStudents.where((doc) {
            final data = doc.data();

            final name = (data['Name'] ?? '').toString();
            final registerNumber =
                (data['RegisterNumber'] ?? doc.id).toString();
            final email = (data['Email'] ?? '').toString();
            final department = (data['Department'] ?? '').toString();
            final semester = (data['Semester'] ?? '').toString();

            final query = searchText.toLowerCase();

            final matchesSearch =
                name.toLowerCase().contains(query) ||
                registerNumber.toLowerCase().contains(query) ||
                email.toLowerCase().contains(query);

            final matchesDepartment =
                selectedDepartment == 'All' ||
                department == selectedDepartment;

            final matchesSemester =
                selectedSemester == 'All' ||
                semester == selectedSemester;

            return matchesSearch &&
                matchesDepartment &&
                matchesSemester;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'Search students',
                    hintText: 'Name, register number or email',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        setState(() => searchText = '');
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => searchText = value.trim());
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<String>(
                  initialValue: selectedDepartment,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                  ),
                  items: departments.map((department) {
                    return DropdownMenuItem(
                      value: department,
                      child: Text(
                        department,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedDepartment = value);
                    }
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<String>(
                  initialValue: selectedSemester,
                  decoration: const InputDecoration(
                    labelText: 'Semester',
                    border: OutlineInputBorder(),
                  ),
                  items: semesters.map((semester) {
                    return DropdownMenuItem(
                      value: semester,
                      child: Text(
                        semester == 'All'
                            ? 'All Semesters'
                            : 'Semester $semester',
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedSemester = value);
                    }
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.people, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Students: ${filteredStudents.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: filteredStudents.isEmpty
                    ? const Center(child: Text('No students found'))
                    : ListView.builder(
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          final doc = filteredStudents[index];
                          final data = doc.data();

                          final name =
                              (data['Name'] ?? 'Student').toString();
                          final registerNumber =
                              (data['RegisterNumber'] ?? doc.id).toString();
                          final email =
                              (data['Email'] ?? '').toString();
                          final department =
                              (data['Department'] ?? 'N/A').toString();
                          final batch =
                              (data['Batch'] ?? 'N/A').toString();
                          final semester =
                              (data['Semester'] ?? 'N/A').toString();
                          final cgpa =
                              (data['CGPA'] ?? 0).toString();
                          final attendance =
                              (data['Attendance'] ?? 0).toString();

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  '$registerNumber\n'
                                  'Department: $department\n'
                                  'Batch: $batch | Semester: $semester\n'
                                  'Attendance: $attendance% | CGPA: $cgpa\n'
                                  '$email',
                                ),
                              ),
                              isThreeLine: false,
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 18,
                              ),
                              onTap: () {
                                if (email.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Student email is missing.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                openStudentProfile(email);
                              },
                            ),
                          );
                        },
                      ),
              ),

              const Divider(),

              Padding(
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.analytics),
                      label: const Text('Performance'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StudentPerformance(),
                          ),
                        );
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.description),
                      label: const Text('Reports'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AcademicReports(),
                          ),
                        );
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.psychology),
                      label: const Text('AI Mentoring'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AiMentoring(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
