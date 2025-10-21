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

      setState(() {
        _submissions = List<Map<String, dynamic>>.from(response);
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TulaiSpacing.sm,
                      vertical: TulaiSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: TulaiColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(TulaiBorderRadius.sm),
                    ),
                    child: Text(
                      'PENDING',
                      style: TulaiTextStyles.caption.copyWith(
                        color: TulaiColors.warning,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
