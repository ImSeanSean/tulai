import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tulai/core/design_system.dart';
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

      // Handle empty names
      final searchName = fullName.isNotEmpty ? fullName : 'unknown student';
      return searchName.contains(query);
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

        // Handle empty names in sorting
        final sortNameA = nameA.isNotEmpty ? nameA : 'zzz_unknown';
        final sortNameB = nameB.isNotEmpty ? nameB : 'zzz_unknown';
        return sortNameA.compareTo(sortNameB);
      });
    } else if (currentSortMode == SortMode.createdAt) {
      filtered.sort((a, b) {
        // Handle null dates
        final dateA = a.created_at ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.created_at ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
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

  // Helper method to build the search and filter section
  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(TulaiSpacing.lg),
      decoration: BoxDecoration(
        color: TulaiColors.backgroundPrimary,
        boxShadow: TulaiShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TulaiTextField(
                  controller: searchController,
                  hint: 'Search enrollees by name...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: TulaiColors.primary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: TulaiSpacing.md),
              Container(
                decoration: BoxDecoration(
                  color: TulaiColors.primary,
                  borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
                ),
                child: IconButton(
                  tooltip: currentSortMode == SortMode.alphabetical
                      ? 'Sort by Date Created'
                      : 'Sort Alphabetically',
                  icon: Icon(
                    currentSortMode == SortMode.alphabetical
                        ? Icons.sort_by_alpha
                        : Icons.calendar_today,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: _toggleSortMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: TulaiSpacing.md),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TulaiSpacing.md,
                  vertical: TulaiSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: TulaiColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TulaiBorderRadius.xl),
                  border: Border.all(
                    color: TulaiColors.secondary.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '${filteredStudents.length} ${filteredStudents.length == 1 ? 'enrollee' : 'enrollees'} found',
                  style: TulaiTextStyles.labelSmall.copyWith(
                    color: TulaiColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Sorted ${currentSortMode == SortMode.alphabetical ? 'alphabetically' : 'by date'}',
                style: TulaiTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to build student cards
  Widget _buildStudentCard(Student student, BuildContext context) {
    final fullName = [
      student.firstName,
      student.middleName,
      student.lastName,
    ].where((part) => part != null && part.isNotEmpty).join(' ');

    // Fallback for empty names
    final displayName = fullName.isNotEmpty ? fullName : 'Unknown Student';
    final initials = _getInitials(displayName);

    return TulaiCard(
      margin: const EdgeInsets.symmetric(
        horizontal: TulaiSpacing.lg,
        vertical: TulaiSpacing.xs,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EnrolleeInformation(student: student),
          ),
        );
      },
      child: Row(
        children: [
          // Avatar with initials
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [TulaiColors.primary, TulaiColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(TulaiBorderRadius.round),
            ),
            child: Center(
              child: Text(
                initials,
                style: TulaiTextStyles.heading3.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: TulaiSpacing.md),
          // Student info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TulaiTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: TulaiSpacing.xs),
                if (student.municipalityCity != null)
                  Text(
                    student.municipalityCity!,
                    style: TulaiTextStyles.bodySmall,
                  ),
                const SizedBox(height: TulaiSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TulaiSpacing.sm,
                    vertical: TulaiSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: TulaiColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
                  ),
                  child: Text(
                    student.created_at != null
                        ? 'Enrolled ${_getRelativeTime(student.created_at!)}'
                        : 'Recently enrolled',
                    style: TulaiTextStyles.caption.copyWith(
                      color: TulaiColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Chevron icon
          Icon(
            Icons.chevron_right,
            color: TulaiColors.textMuted,
            size: 24,
          ),
        ],
      ),
    );
  }

  // Helper method to get initials
  String _getInitials(String fullName) {
    final words =
        fullName.trim().split(' ').where((word) => word.isNotEmpty).toList();
    if (words.isEmpty) return 'NA';
    if (words.length == 1) {
      return words[0].isNotEmpty ? words[0][0].toUpperCase() : 'NA';
    }

    final firstInitial = words.first.isNotEmpty ? words.first[0] : '';
    final lastInitial = words.last.isNotEmpty ? words.last[0] : '';

    if (firstInitial.isEmpty && lastInitial.isEmpty) return 'NA';
    if (firstInitial.isEmpty) return lastInitial.toUpperCase();
    if (lastInitial.isEmpty) return firstInitial.toUpperCase();

    return '${firstInitial}${lastInitial}'.toUpperCase();
  }

  // Helper method to get relative time
  String _getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return DateFormat.yMMMd().format(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  // Helper method to build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: TulaiColors.textMuted,
          ),
          const SizedBox(height: TulaiSpacing.md),
          Text(
            searchController.text.isEmpty
                ? 'No enrollees yet'
                : 'No enrollees found',
            style: TulaiTextStyles.heading3.copyWith(
              color: TulaiColors.textSecondary,
            ),
          ),
          const SizedBox(height: TulaiSpacing.sm),
          Text(
            searchController.text.isEmpty
                ? 'Enrollees will appear here once students complete their enrollment'
                : 'Try adjusting your search terms',
            style: TulaiTextStyles.bodyMedium.copyWith(
              color: TulaiColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          if (searchController.text.isNotEmpty) ...[
            const SizedBox(height: TulaiSpacing.md),
            TulaiButton(
              text: 'Clear Search',
              style: TulaiButtonStyle.secondary,
              onPressed: () {
                searchController.clear();
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we're on a large screen (web/tablet)
    final isLargeScreen = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: TulaiColors.backgroundSecondary,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: TulaiColors.backgroundPrimary,
        title: Text(
          'Enrollees',
          style: TulaiTextStyles.heading2,
        ),
        actions: [
          if (isLargeScreen)
            Padding(
              padding: const EdgeInsets.only(right: TulaiSpacing.md),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TulaiSpacing.md,
                    vertical: TulaiSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: TulaiColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(TulaiBorderRadius.xl),
                  ),
                  child: Text(
                    'Total: ${students.length}',
                    style: TulaiTextStyles.labelMedium.copyWith(
                      color: TulaiColors.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(TulaiColors.primary),
              ),
            )
          : Column(
              children: [
                _buildSearchAndFilter(),
                Expanded(
                  child: filteredStudents.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: fetchStudents,
                          color: TulaiColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                vertical: TulaiSpacing.md),
                            itemCount: filteredStudents.length,
                            itemBuilder: (context, index) {
                              return _buildStudentCard(
                                filteredStudents[index],
                                context,
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
