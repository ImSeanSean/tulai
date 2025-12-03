import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tulai/core/design_system.dart';
import 'package:tulai/screens/teacher/review_submission.dart';

class PendingSubmissions extends StatefulWidget {
  const PendingSubmissions({super.key});

  @override
  State<PendingSubmissions> createState() => _PendingSubmissionsState();
}

class _PendingSubmissionsState extends State<PendingSubmissions> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _submissions = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Map<String, List<Map<String, dynamic>>> _potentialDuplicates = {};

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() => _isLoading = true);

    try {
      final response = await _supabase
          .from('pending_submissions')
          .select()
          .order('submitted_at', ascending: false);

      final submissions = List<Map<String, dynamic>>.from(response);

      // Check for potential duplicates
      await _checkForDuplicates(submissions);

      setState(() {
        _submissions = submissions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: TulaiSpacing.sm),
                Expanded(child: Text('Error loading submissions: $e')),
              ],
            ),
            backgroundColor: TulaiColors.error,
          ),
        );
      }
    }
  }

  Future<void> _checkForDuplicates(
      List<Map<String, dynamic>> submissions) async {
    final duplicates = <String, List<Map<String, dynamic>>>{};

    for (final submission in submissions) {
      final firstName = submission['first_name']?.toString().trim();
      final lastName = submission['last_name']?.toString().trim();
      final birthdate = submission['birthdate'];

      if (firstName == null || lastName == null || birthdate == null) {
        continue;
      }

      try {
        // Check for existing students with matching name and birthdate
        final existingStudents = await _supabase
            .from('students')
            .select(
                'id, first_name, last_name, middle_name, birthdate, contact_number, barangay, batch_id')
            .ilike('first_name', firstName)
            .ilike('last_name', lastName)
            .eq('birthdate', birthdate);

        if (existingStudents.isNotEmpty) {
          duplicates[submission['id']] =
              List<Map<String, dynamic>>.from(existingStudents);
        }
      } catch (e) {
        debugPrint('Error checking duplicates for ${submission['id']}: $e');
      }
    }

    _potentialDuplicates = duplicates;
  }

  List<Map<String, dynamic>> get _filteredSubmissions {
    if (_searchQuery.isEmpty) return _submissions;

    return _submissions.where((submission) {
      final firstName =
          submission['first_name']?.toString().toLowerCase() ?? '';
      final lastName = submission['last_name']?.toString().toLowerCase() ?? '';
      final middleName =
          submission['middle_name']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();

      return firstName.contains(query) ||
          lastName.contains(query) ||
          middleName.contains(query);
    }).toList();
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _deleteSubmission(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TulaiBorderRadius.lg),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: TulaiColors.error),
            const SizedBox(width: TulaiSpacing.sm),
            Text('Delete Submission', style: TulaiTextStyles.heading3),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this submission? This action cannot be undone.',
          style: TulaiTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TulaiTextStyles.bodyMedium.copyWith(
                color: TulaiColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: TulaiColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabase.from('pending_submissions').delete().eq('id', id);
        await _loadSubmissions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: TulaiSpacing.sm),
                  const Text('Submission deleted successfully'),
                ],
              ),
              backgroundColor: TulaiColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting submission: $e'),
              backgroundColor: TulaiColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _reEnrollExistingStudent(
      String submissionId, Map<String, dynamic> existingStudent) async {
    try {
      // Get the active batch
      final batchResponse = await _supabase
          .from('batches')
          .select('id')
          .eq('is_active', true)
          .single();

      final activeBatchId = batchResponse['id'];

      // Update the existing student's batch_id to re-enroll them
      await _supabase
          .from('students')
          .update({'batch_id': activeBatchId}).eq('id', existingStudent['id']);

      // Delete the pending submission
      await _supabase
          .from('pending_submissions')
          .delete()
          .eq('id', submissionId);

      // Reload submissions
      await _loadSubmissions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: TulaiSpacing.sm),
                Expanded(
                  child: Text(
                    'Student re-enrolled to active batch successfully',
                  ),
                ),
              ],
            ),
            backgroundColor: TulaiColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error re-enrolling student: $e'),
            backgroundColor: TulaiColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showReEnrollDialog(
      String submissionId, List<Map<String, dynamic>> duplicates) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TulaiBorderRadius.lg),
        ),
        title: Row(
          children: [
            Icon(Icons.person_add, color: TulaiColors.primary),
            const SizedBox(width: TulaiSpacing.sm),
            Expanded(
              child: Text(
                'Re-enroll Existing Student',
                style: TulaiTextStyles.heading3,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select which existing student to re-enroll to the active batch:',
                style: TulaiTextStyles.bodyMedium.copyWith(
                  color: TulaiColors.textSecondary,
                ),
              ),
              const SizedBox(height: TulaiSpacing.md),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: duplicates.length,
                  itemBuilder: (context, index) {
                    final student = duplicates[index];
                    final fullName = [
                      student['first_name'],
                      student['middle_name'],
                      student['last_name'],
                    ]
                        .where((e) => e != null && e.toString().isNotEmpty)
                        .join(' ');

                    return Card(
                      margin: const EdgeInsets.only(bottom: TulaiSpacing.sm),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: TulaiColors.primary.withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            color: TulaiColors.primary,
                          ),
                        ),
                        title: Text(
                          fullName,
                          style: TulaiTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (student['barangay'] != null)
                              Text(
                                'Barangay: ${student['barangay']}',
                                style: TulaiTextStyles.caption,
                              ),
                            if (student['contact_number'] != null)
                              Text(
                                'Contact: ${student['contact_number']}',
                                style: TulaiTextStyles.caption,
                              ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _reEnrollExistingStudent(submissionId, student);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TulaiColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: TulaiSpacing.md,
                              vertical: TulaiSpacing.sm,
                            ),
                          ),
                          child: const Text('Re-enroll'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TulaiTextStyles.bodyMedium.copyWith(
                color: TulaiColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = TulaiResponsive.isLargeScreen(context);

    return Scaffold(
      backgroundColor: TulaiColors.backgroundSecondary,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: TulaiColors.backgroundPrimary,
        title: Row(
          children: [
            Icon(Icons.pending_actions, color: TulaiColors.primary),
            const SizedBox(width: TulaiSpacing.sm),
            Text('Pending Submissions', style: TulaiTextStyles.heading2),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSubmissions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(TulaiSpacing.lg),
            color: TulaiColors.backgroundPrimary,
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: Icon(Icons.search, color: TulaiColors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
                  borderSide: BorderSide(color: TulaiColors.primary, width: 2),
                ),
              ),
            ),
          ),

          // Stats bar
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: TulaiSpacing.lg,
              vertical: TulaiSpacing.md,
            ),
            color: TulaiColors.info.withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: TulaiColors.info, size: 20),
                const SizedBox(width: TulaiSpacing.sm),
                Text(
                  '${_filteredSubmissions.length} pending submission(s)',
                  style: TulaiTextStyles.bodyMedium.copyWith(
                    color: TulaiColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_potentialDuplicates.isNotEmpty) ...[
                  const SizedBox(width: TulaiSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TulaiSpacing.sm,
                      vertical: TulaiSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: TulaiColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(TulaiBorderRadius.sm),
                      border: Border.all(
                        color: TulaiColors.error.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: TulaiColors.error,
                          size: 16,
                        ),
                        const SizedBox(width: TulaiSpacing.xs),
                        Text(
                          '${_potentialDuplicates.length} potential duplicate(s)',
                          style: TulaiTextStyles.bodySmall.copyWith(
                            color: TulaiColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSubmissions.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadSubmissions,
                        child: ListView.builder(
                          padding: EdgeInsets.all(isLargeScreen
                              ? TulaiSpacing.xl
                              : TulaiSpacing.lg),
                          itemCount: _filteredSubmissions.length,
                          itemBuilder: (context, index) {
                            final submission = _filteredSubmissions[index];
                            return _buildSubmissionCard(submission);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isEmpty ? Icons.inbox_outlined : Icons.search_off,
            size: 80,
            color: TulaiColors.textMuted,
          ),
          const SizedBox(height: TulaiSpacing.lg),
          Text(
            _searchQuery.isEmpty
                ? 'No Pending Submissions'
                : 'No Results Found',
            style: TulaiTextStyles.heading3.copyWith(
              color: TulaiColors.textSecondary,
            ),
          ),
          const SizedBox(height: TulaiSpacing.sm),
          Text(
            _searchQuery.isEmpty
                ? 'All submissions have been reviewed'
                : 'Try a different search term',
            style: TulaiTextStyles.bodyMedium.copyWith(
              color: TulaiColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(Map<String, dynamic> submission) {
    final fullName = [
      submission['first_name'],
      submission['middle_name'],
      submission['last_name'],
    ].where((e) => e != null && e.toString().isNotEmpty).join(' ');

    return TulaiCard(
      margin: const EdgeInsets.only(bottom: TulaiSpacing.md),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReviewSubmission(submission: submission),
            ),
          );
          if (result == true) {
            _loadSubmissions();
          }
        },
        borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(TulaiSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [TulaiColors.primary, TulaiColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: TulaiSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName.isEmpty ? 'Unnamed Submission' : fullName,
                          style: TulaiTextStyles.heading3,
                        ),
                        const SizedBox(height: TulaiSpacing.xs),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: TulaiColors.textSecondary,
                            ),
                            const SizedBox(width: TulaiSpacing.xs),
                            Text(
                              _formatDate(submission['submitted_at']),
                              style: TulaiTextStyles.caption.copyWith(
                                color: TulaiColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: TulaiSpacing.sm,
                          vertical: TulaiSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: TulaiColors.warning.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(TulaiBorderRadius.sm),
                        ),
                        child: Text(
                          'PENDING',
                          style: TulaiTextStyles.caption.copyWith(
                            color: TulaiColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (_potentialDuplicates
                          .containsKey(submission['id'])) ...[
                        const SizedBox(height: TulaiSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: TulaiSpacing.sm,
                            vertical: TulaiSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: TulaiColors.error.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(TulaiBorderRadius.sm),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 12,
                                color: TulaiColors.error,
                              ),
                              const SizedBox(width: TulaiSpacing.xs),
                              Text(
                                'DUPLICATE',
                                style: TulaiTextStyles.caption.copyWith(
                                  color: TulaiColors.error,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: TulaiSpacing.md),
              const Divider(),
              const SizedBox(height: TulaiSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      Icons.cake_outlined,
                      submission['birthdate'] ?? 'N/A',
                    ),
                  ),
                  const SizedBox(width: TulaiSpacing.sm),
                  Expanded(
                    child: _buildInfoChip(
                      Icons.wc,
                      submission['sex'] ?? 'N/A',
                    ),
                  ),
                  const SizedBox(width: TulaiSpacing.sm),
                  Expanded(
                    child: _buildInfoChip(
                      Icons.location_on_outlined,
                      submission['municipality_city'] ?? 'N/A',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TulaiSpacing.md),
              if (_potentialDuplicates.containsKey(submission['id'])) ...[
                Container(
                  padding: const EdgeInsets.all(TulaiSpacing.md),
                  decoration: BoxDecoration(
                    color: TulaiColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(TulaiBorderRadius.sm),
                    border: Border.all(
                      color: TulaiColors.error.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: TulaiColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: TulaiSpacing.sm),
                          Text(
                            'Potential Duplicate Enrollment',
                            style: TulaiTextStyles.labelMedium.copyWith(
                              color: TulaiColors.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: TulaiSpacing.xs),
                      Text(
                        'Found ${_potentialDuplicates[submission['id']]!.length} existing student(s) with the same name and birthdate:',
                        style: TulaiTextStyles.bodySmall.copyWith(
                          color: TulaiColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: TulaiSpacing.sm),
                      ..._potentialDuplicates[submission['id']]!
                          .map((existing) {
                        final existingFullName = [
                          existing['first_name'],
                          existing['middle_name'],
                          existing['last_name'],
                        ]
                            .where((e) => e != null && e.toString().isNotEmpty)
                            .join(' ');

                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: TulaiSpacing.xs),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 14,
                                color: TulaiColors.textSecondary,
                              ),
                              const SizedBox(width: TulaiSpacing.xs),
                              Expanded(
                                child: Text(
                                  existingFullName,
                                  style: TulaiTextStyles.bodySmall.copyWith(
                                    color: TulaiColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (existing['barangay'] != null) ...[
                                Text(
                                  ' • ${existing['barangay']}',
                                  style: TulaiTextStyles.caption.copyWith(
                                    color: TulaiColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: TulaiSpacing.xs),
                      Text(
                        'Please verify before approving this submission.',
                        style: TulaiTextStyles.caption.copyWith(
                          color: TulaiColors.error,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: TulaiSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showReEnrollDialog(
                            submission['id'],
                            _potentialDuplicates[submission['id']]!,
                          ),
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text('Use Existing & Re-enroll'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: TulaiColors.primary,
                            side: const BorderSide(
                                color: TulaiColors.primary, width: 1.5),
                            padding: const EdgeInsets.symmetric(
                              vertical: TulaiSpacing.sm,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TulaiSpacing.md),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_potentialDuplicates.containsKey(submission['id'])) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showReEnrollDialog(
                          submission['id'],
                          _potentialDuplicates[submission['id']]!,
                        ),
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text('Use Existing'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: TulaiColors.primary,
                          side: const BorderSide(color: TulaiColors.primary),
                          padding: const EdgeInsets.symmetric(
                            horizontal: TulaiSpacing.sm,
                            vertical: TulaiSpacing.sm,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: TulaiSpacing.sm),
                  ],
                  TextButton.icon(
                    onPressed: () => _deleteSubmission(submission['id']),
                    icon: Icon(Icons.delete_outline, color: TulaiColors.error),
                    label: Text(
                      'Delete',
                      style: TextStyle(color: TulaiColors.error),
                    ),
                  ),
                  const SizedBox(width: TulaiSpacing.sm),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ReviewSubmission(submission: submission),
                        ),
                      );
                      if (result == true) {
                        _loadSubmissions();
                      }
                    },
                    icon: const Icon(Icons.rate_review),
                    label: const Text('Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TulaiColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: TulaiColors.textSecondary),
        const SizedBox(width: TulaiSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: TulaiTextStyles.caption.copyWith(
              color: TulaiColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
