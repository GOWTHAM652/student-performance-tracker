
class Student {
  final String registerNumber;
  final String name;
  final String department;
  final String batch;
  final int semester;
  final double attendance;
  final Map<String, double> subjectMarks;
  final double sgpa;
  final double cgpa;

  const Student({
    required this.registerNumber,
    required this.name,
    required this.department,
    required this.batch,
    required this.semester,
    required this.attendance,
    required this.subjectMarks,
    required this.sgpa,
    required this.cgpa,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      registerNumber: json['registerNumber'] as String,
      name: json['name'] as String,
      department: json['department'] as String,
      batch: json['batch'] as String,
      semester: (json['semester'] as num).toInt(),
      attendance: (json['attendance'] as num).toDouble(),
      subjectMarks: (json['subjectMarks'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(
                key,
                (value as num).toDouble(),
              )),
      sgpa: (json['sgpa'] as num).toDouble(),
      cgpa: (json['cgpa'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'registerNumber': registerNumber,
      'name': name,
      'department': department,
      'batch': batch,
      'semester': semester,
      'attendance': attendance,
      'subjectMarks': subjectMarks,
      'sgpa': sgpa,
      'cgpa': cgpa,
    };
  }
}
