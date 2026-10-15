
import '../models/student_model.dart';

const List<Student> students = [
  Student(
    registerNumber: '7376241CS101',
    name: 'Arun Kumar',
    department: 'Computer Science',
    batch: '2024-2028',
    semester: 5,
    attendance: 92,
    subjectMarks: {
      'Data Structures': 85,
      'Database Management': 78,
      'Operating Systems': 68,
      'Computer Networks': 90,
      'Software Engineering': 55,
    },
    sgpa: 8.2,
    cgpa: 8.0,
  ),
  Student(
    registerNumber: '7376241CS102',
    name: 'Priya',
    department: 'Computer Science',
    batch: '2024-2028',
    semester: 5,
    attendance: 78,
    subjectMarks: {
      'Data Structures': 72,
      'Database Management': 88,
      'Operating Systems': 62,
      'Computer Networks': 80,
      'Software Engineering': 75,
    },
    sgpa: 7.8,
    cgpa: 7.6,
  ),
];
