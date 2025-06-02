import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tulai/screens/teacher/enrolee_information.dart';
import 'package:tulai/services/student_db.dart';

enum SortMode { alphabetical, createdAt }

class Enrollees extends StatefulWidget {
  const Enrollees({super.key});

  @override
  State<Enrollees> createState() => _EnrolleesState();
}

class _EnrolleesState extends State<Enrollees> {
  List<Student> students = [];
  List<Student> filteredStudents = [];
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();

  // Sorting modes
  SortMode currentSortMode = SortMode.alphabetical;

  @override
  void initState() {
    super.initState();
    fetchStudents();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterAndSortStudents();
  }

  void _filterAndSortStudents() {
    final query = searchController.text.toLowerCase();

    List<Student> filtered = students.where((student) {
      final fullName = [student.lastName, student.firstName, student.middleName]
          .where((part) => part != null && part.isNotEmpty)
          .join(' ')
          .toLowerCase();

      return fullName.contains(query);
    }).toList();

    // Sort filtered list based on currentSortMode
    if (currentSortMode == SortMode.alphabetical) {
      filtered.sort((a, b) {
        final nameA = [a.lastName, a.firstName, a.middleName]
            .where((part) => part != null && part.isNotEmpty)
            .join(' ')
            .toLowerCase();
        final nameB = [b.lastName, b.firstName, b.middleName]
            .where((part) => part != null && part.isNotEmpty)
            .join(' ')
            .toLowerCase();
        return nameA.compareTo(nameB);
      });
    } else if (currentSortMode == SortMode.createdAt) {
      filtered.sort((a, b) {
        return b.created_at!.compareTo(a.created_at!);
      });
    }

    setState(() {
      filteredStudents = filtered;
    });
  }

  Future<void> fetchStudents() async {
    try {
      final fetchedStudents = await StudentDatabase.getStudents();
      students = fetchedStudents;

      // After fetching, filter & sort
      _filterAndSortStudents();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error fetching students: $e");
    }
  }

  void _toggleSortMode() {
    setState(() {
      currentSortMode = currentSortMode == SortMode.alphabetical
          ? SortMode.createdAt
          : SortMode.alphabetical;
    });

    // Re-apply filter and sort when toggling
    _filterAndSortStudents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Enrollees'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Expanded search bar takes most of the width
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search enrollees',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  iconSize: 30,
                  tooltip: currentSortMode == SortMode.alphabetical
                      ? 'Sort by Date Created'
                      : 'Sort Alphabetically',
                  icon: Icon(currentSortMode == SortMode.alphabetical
                      ? Icons.sort_by_alpha
                      : Icons.calendar_today),
                  onPressed: _toggleSortMode,
                ),
              ],
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredStudents.isEmpty
              ? const Center(child: Text("No enrollees found."))
              : ListView.separated(
                  itemCount: filteredStudents.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index];
                    final fullName = [
                      student.lastName,
                      student.firstName,
                      student.middleName
                    ]
                        .where((part) => part != null && part.isNotEmpty)
                        .join(', ');

                    return ListTile(
                      leading: const Icon(
                        Icons.person,
                        size: 30,
                      ),
                      title: Text(
                        fullName,
                        style: const TextStyle(fontSize: 23),
                      ),
                      trailing: Text(
                        student.created_at != null
                            ? DateFormat.yMMMd().format(student.created_at!)
                            : '',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EnrolleeInformation(student: student),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
