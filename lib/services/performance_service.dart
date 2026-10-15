
import '../models/student_model.dart';

class PerformanceService {
  double calculateAverage(Student student) {
    if (student.subjectMarks.isEmpty) return 0;

    final total = student.subjectMarks.values
        .reduce((a, b) => a + b);

    return total / student.subjectMarks.length;
  }

  List<String> getWeakSubjects(Student student) {
    return student.subjectMarks.entries
        .where((entry) => entry.value < 60)
        .map((entry) => entry.key)
        .toList();
  }

  List<String> getMentoringSuggestions(Student student) {
    final suggestions = <String>[];

    if (student.attendance < 75) {
      suggestions.add(
        'Improve attendance. Attend classes regularly.',
      );
    }

    for (final entry in student.subjectMarks.entries) {
      if (entry.value < 60) {
        suggestions.add(
          'Focus more on ${entry.key}. Revise daily and practise questions.',
        );
      }
    }

    if (student.sgpa < 7) {
      suggestions.add(
        'Create a weekly study timetable and revise difficult topics.',
      );
    }

    if (suggestions.isEmpty) {
      suggestions.add(
        'Good progress! Continue regular revision and practise mock tests.',
      );
    }

    return suggestions;
  }
}
