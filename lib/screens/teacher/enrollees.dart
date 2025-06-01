import 'package:flutter/material.dart';
import 'package:tulai/services/student_db.dart';

class Enrollees extends StatefulWidget {
  const Enrollees({super.key});

  @override
  State<Enrollees> createState() => _EnrolleesState();
}

class _EnrolleesState extends State<Enrollees> {
  List<Student> students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    try {
      final fetchedStudents = await StudentDatabase.getStudents();
      setState(() {
        students = fetchedStudents;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error fetching students: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
              ? const Center(child: Text("No enrollees found."))
              : ListView.separated(
                  itemCount: students.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final fullName = [
                      student.lastName,
                      student.firstName,
                      student.middleName
                    ]
                        .where((part) => part != null && part.isNotEmpty)
                        .join(', ');

                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(fullName),
                    );
                  },
                ),
    );
  }
}
