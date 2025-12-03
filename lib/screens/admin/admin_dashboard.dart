import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tulai/core/app_config.dart';
import 'package:tulai/core/design_system.dart';
import 'package:tulai/screens/admin/admin_analytics_page.dart';
import 'package:tulai/screens/teacher/enrollees.dart';
import 'package:tulai/services/batch_db.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _errorMessage;
  TabController? _tabController;
  RealtimeChannel? _usersChannel;
  final List<String> _adminTabs = [
    'Users',
    'Analytics',
  ];
  final List<String> _superAdminTabs = [
    'Users',
    'Analytics',
    'Batches',
    'Enrollees',
  ];

  List<String> get _tabs =>
      AppConfig().isSuperAdmin ? _superAdminTabs : _adminTabs;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _setupRealtimeSubscription();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController!.addListener(() {
      setState(() {});
    });
  }

  void _setupRealtimeSubscription() {
    _usersChannel = _supabase
        .channel('users_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'users',
          callback: (payload) {
            print('Realtime change detected: ${payload.eventType}');
            // Reload users when any change occurs
            _loadUsers();
          },
        )
        .subscribe();
  }

  Future<void> _logout() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/admin-login');
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Auth user: ${_supabase.auth.currentUser?.id}');
      print('Auth user email: ${_supabase.auth.currentUser?.email}');
      print('Fetching users from Supabase...');

      final response = await _supabase
          .from('users')
          .select('*')
          .order('created_at', ascending: false);

      print('Users response type: ${response.runtimeType}');
      print('Users loaded: ${response.length}'); // Debug
      print('Users data: $response');

      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error loading users: $e'); // Debug
      print('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Failed to load users: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddUserDialog() async {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    String selectedRole = 'teacher';

    final isLargeScreen = MediaQuery.of(context).size.width > 800;

    await showDialog(
        context: context,
        builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TulaiBorderRadius.lg),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isLargeScreen ? 600 : 400,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                padding: EdgeInsets.all(
                    isLargeScreen ? TulaiSpacing.xxl : TulaiSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(
                          Icons.person_add,
                          color: TulaiColors.primary,
                          size: isLargeScreen ? 32 : 28,
                        ),
                        const SizedBox(width: TulaiSpacing.md),
                        Expanded(
                          child: Text(
                            'Add New User',
                            style: TulaiTextStyles.heading3.copyWith(
                              color: TulaiColors.primary,
                              fontSize: isLargeScreen ? 24 : 20,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          color: TulaiColors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: TulaiSpacing.lg),
                    const Divider(color: TulaiColors.borderLight),
                    const SizedBox(height: TulaiSpacing.lg),

                    // Form
                    Expanded(
                      child: Form(
                        key: formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextFormField(
                                controller: nameController,
                                decoration: InputDecoration(
                                  labelText: 'Name',
                                  prefixIcon: const Icon(Icons.person),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        TulaiBorderRadius.md),
                                  ),
                                ),
                                validator: (value) => value?.isEmpty ?? true
                                    ? 'Name is required'
                                    : null,
                              ),
                              const SizedBox(height: TulaiSpacing.md),
                              TextFormField(
                                controller: emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: const Icon(Icons.email),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        TulaiBorderRadius.md),
                                  ),
                                ),
                                validator: (value) {
                                  if (value?.isEmpty ?? true)
                                    return 'Email is required';
                                  if (!value!.contains('@'))
                                    return 'Invalid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: TulaiSpacing.md),
                              TextFormField(
                                controller: passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        TulaiBorderRadius.md),
                                  ),
                                ),
                                validator: (value) {
                                  if (value?.isEmpty ?? true)
                                    return 'Password is required';
                                  if (value!.length < 6)
                                    return 'Password must be 6+ characters';
                                  return null;
                                },
                              ),
                              const SizedBox(height: TulaiSpacing.md),
                              DropdownButtonFormField<String>(
                                value: selectedRole,
                                decoration: InputDecoration(
                                  labelText: 'Role',
                                  prefixIcon:
                                      const Icon(Icons.admin_panel_settings),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                        TulaiBorderRadius.md),
                                  ),
                                ),
                                items: ['teacher', 'admin'].map((role) {
                                  return DropdownMenuItem(
                                    value: role,
                                    child: Text(role.toUpperCase()),
                                  );
                                }).toList(),
                                onChanged: (value) => selectedRole = value!,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: TulaiSpacing.lg),
                    const Divider(color: TulaiColors.borderLight),
                    const SizedBox(height: TulaiSpacing.md),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TulaiTextStyles.bodyLarge.copyWith(
                              color: TulaiColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: TulaiSpacing.md),
                        ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              try {
                                // Create user in Supabase Auth
                                final authResponse =
                                    await _supabase.auth.signUp(
                                  email: emailController.text.trim(),
                                  password: passwordController.text,
                                  data: {
                                    'name': nameController.text.trim(),
                                    'role': selectedRole,
                                  },
                                );

                                if (authResponse.user != null) {
                                  // Wait a moment for the auth trigger to complete
                                  await Future.delayed(
                                      const Duration(milliseconds: 500));

                                  // Add/update user details to users table with upsert
                                  await _supabase.from('users').upsert(
                                    {
                                      'id': authResponse.user!.id,
                                      'email': emailController.text.trim(),
                                      'name': nameController.text.trim(),
                                      'role': selectedRole,
                                    },
                                    onConflict: 'id',
                                  );

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                'User ${nameController.text} created successfully!'),
                                            const SizedBox(height: 4),
                                            const Text(
                                              'Note: User needs to verify their email before logging in.',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white70),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: TulaiColors.success,
                                        duration: const Duration(seconds: 4),
                                      ),
                                    );
                                    _loadUsers();
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error creating user: $e'),
                                      backgroundColor: TulaiColors.error,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TulaiColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: isLargeScreen
                                  ? TulaiSpacing.xl
                                  : TulaiSpacing.lg,
                              vertical: TulaiSpacing.md,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person_add, size: 20),
                              const SizedBox(width: TulaiSpacing.sm),
                              Text(
                                'Add User',
                                style: TulaiTextStyles.bodyLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ));
  }

  Future<void> _showEditUserDialog(Map<String, dynamic> user) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user['name']);
    final emailController = TextEditingController(text: user['email']);
    String selectedRole = user['role'] ?? 'teacher';

    final isLargeScreen = MediaQuery.of(context).size.width > 800;

    await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
              builder: (context, setState) => Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TulaiBorderRadius.lg),
                ),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isLargeScreen ? 600 : 400,
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  padding: EdgeInsets.all(
                      isLargeScreen ? TulaiSpacing.xl : TulaiSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(TulaiSpacing.sm),
                            decoration: BoxDecoration(
                              color: TulaiColors.primary.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(TulaiBorderRadius.md),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: TulaiColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: TulaiSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Edit User',
                                  style: TulaiTextStyles.heading2.copyWith(
                                    color: TulaiColors.textPrimary,
                                    fontSize: isLargeScreen ? 22 : 18,
                                  ),
                                ),
                                Text(
                                  'Update user information',
                                  style: TulaiTextStyles.bodySmall.copyWith(
                                    color: TulaiColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: TulaiSpacing.md),
                      const Divider(color: TulaiColors.borderLight),
                      const SizedBox(height: TulaiSpacing.md),

                      // Form
                      Flexible(
                        child: SingleChildScrollView(
                          child: Form(
                            key: formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Name',
                                    prefixIcon: const Icon(Icons.person),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          TulaiBorderRadius.md),
                                    ),
                                  ),
                                  validator: (value) => value?.isEmpty ?? true
                                      ? 'Name is required'
                                      : null,
                                ),
                                const SizedBox(height: TulaiSpacing.md),
                                TextFormField(
                                  controller: emailController,
                                  enabled: false,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: const Icon(Icons.email),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          TulaiBorderRadius.md),
                                    ),
                                    helperText: 'Email cannot be changed',
                                  ),
                                ),
                                const SizedBox(height: TulaiSpacing.md),
                                DropdownButtonFormField<String>(
                                  value: selectedRole,
                                  decoration: InputDecoration(
                                    labelText: 'Role',
                                    prefixIcon:
                                        const Icon(Icons.admin_panel_settings),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          TulaiBorderRadius.md),
                                    ),
                                  ),
                                  items: ['teacher', 'admin'].map((role) {
                                    return DropdownMenuItem(
                                      value: role,
                                      child: Text(role.toUpperCase()),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedRole = value!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: TulaiSpacing.md),
                      const Divider(color: TulaiColors.borderLight),
                      const SizedBox(height: TulaiSpacing.sm),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: TulaiTextStyles.bodyMedium.copyWith(
                                color: TulaiColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: TulaiSpacing.sm),
                          ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                try {
                                  // Update user in database
                                  await _supabase.from('users').update({
                                    'name': nameController.text.trim(),
                                    'role': selectedRole,
                                  }).eq('id', user['id']);

                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('User updated successfully'),
                                        backgroundColor: TulaiColors.success,
                                      ),
                                    );
                                    _loadUsers();
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Error updating user: $e'),
                                        backgroundColor: TulaiColors.error,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TulaiColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: isLargeScreen
                                    ? TulaiSpacing.lg
                                    : TulaiSpacing.md,
                                vertical: TulaiSpacing.sm,
                              ),
                            ),
                            child: const Text('Save Changes'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ));
  }

  Future<void> _deleteUser(String userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete user "$userName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: TulaiColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabase.from('users').delete().eq('id', userId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User $userName deleted successfully'),
              backgroundColor: TulaiColors.success,
            ),
          );
          _loadUsers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting user: $e'),
              backgroundColor: TulaiColors.error,
            ),
          );
        }
      }
    }
  }

  Widget _buildUsersView(bool isLargeScreen) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.all(
              isLargeScreen ? TulaiSpacing.xl : TulaiSpacing.lg,
            ),
            color: TulaiColors.backgroundPrimary,
            child: Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: isLargeScreen ? 40 : 32,
                  color: TulaiColors.primary,
                ),
                const SizedBox(width: TulaiSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Dashboard',
                        style: TulaiTextStyles.heading2.copyWith(
                          color: TulaiColors.primary,
                          fontSize: isLargeScreen ? 28 : 24,
                        ),
                      ),
                      Text(
                        'User Management System',
                        style: TulaiTextStyles.bodyMedium.copyWith(
                          color: TulaiColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddUserDialog,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add User'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TulaiColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          isLargeScreen ? TulaiSpacing.xl : TulaiSpacing.lg,
                      vertical: TulaiSpacing.md,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Statistics
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.all(
              isLargeScreen ? TulaiSpacing.xl : TulaiSpacing.lg,
            ),
            child: isLargeScreen
                ? Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          '${_users.length}',
                          'Total Users',
                          TulaiColors.primary,
                          Icons.people,
                        ),
                      ),
                      const SizedBox(width: TulaiSpacing.lg),
                      Expanded(
                        child: _buildStatCard(
                          '${_users.where((u) => u['role'] == 'teacher').length}',
                          'Teachers',
                          TulaiColors.success,
                          Icons.school,
                        ),
                      ),
                      const SizedBox(width: TulaiSpacing.lg),
                      Expanded(
                        child: _buildStatCard(
                          '${_users.where((u) => u['role'] == 'admin').length}',
                          'Admins',
                          TulaiColors.warning,
                          Icons.admin_panel_settings,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildStatCard(
                        '${_users.length}',
                        'Total Users',
                        TulaiColors.primary,
                        Icons.people,
                      ),
                      const SizedBox(height: TulaiSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              '${_users.where((u) => u['role'] == 'teacher').length}',
                              'Teachers',
                              TulaiColors.success,
                              Icons.school,
                            ),
                          ),
                          const SizedBox(width: TulaiSpacing.md),
                          Expanded(
                            child: _buildStatCard(
                              '${_users.where((u) => u['role'] == 'admin').length}',
                              'Admins',
                              TulaiColors.warning,
                              Icons.admin_panel_settings,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),

        // Users List
        _isLoading
            ? const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: TulaiColors.primary,
                  ),
                ),
              )
            : _errorMessage != null
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: TulaiColors.error,
                          ),
                          const SizedBox(height: TulaiSpacing.md),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: TulaiSpacing.xl),
                            child: Text(
                              _errorMessage!,
                              style: TulaiTextStyles.bodyLarge.copyWith(
                                color: TulaiColors.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _users.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: TulaiColors.textMuted,
                              ),
                              const SizedBox(height: TulaiSpacing.md),
                              Text(
                                'No users found',
                                style: TulaiTextStyles.bodyLarge.copyWith(
                                  color: TulaiColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: TulaiSpacing.sm),
                              Text(
                                'Add your first user to get started',
                                style: TulaiTextStyles.bodyMedium.copyWith(
                                  color: TulaiColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: EdgeInsets.all(
                          isLargeScreen ? TulaiSpacing.xl : TulaiSpacing.lg,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final user = _users[index];
                              return TulaiCard(
                                margin: const EdgeInsets.only(
                                    bottom: TulaiSpacing.md),
                                child: Padding(
                                  padding: EdgeInsets.all(
                                    isLargeScreen
                                        ? TulaiSpacing.lg
                                        : TulaiSpacing.md,
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: isLargeScreen ? 24 : 20,
                                        backgroundColor: user['role'] == 'admin'
                                            ? TulaiColors.warning
                                            : TulaiColors.primary,
                                        child: Icon(
                                          user['role'] == 'admin'
                                              ? Icons.admin_panel_settings
                                              : Icons.person,
                                          color: Colors.white,
                                          size: isLargeScreen ? 24 : 20,
                                        ),
                                      ),
                                      const SizedBox(width: TulaiSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user['name'] ?? 'No name',
                                              style: TulaiTextStyles.bodyLarge
                                                  .copyWith(
                                                fontWeight: FontWeight.w600,
                                                fontSize:
                                                    isLargeScreen ? 18 : 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              user['email'] ?? 'No email',
                                              style: TulaiTextStyles.bodyMedium
                                                  .copyWith(
                                                color:
                                                    TulaiColors.textSecondary,
                                                fontSize: 13,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: TulaiSpacing.sm,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: (user['role'] == 'admin'
                                                    ? TulaiColors.warning
                                                        .withOpacity(0.2)
                                                    : TulaiColors.primary
                                                        .withOpacity(0.2)),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        TulaiBorderRadius.sm),
                                              ),
                                              child: Text(
                                                user['role']
                                                    .toString()
                                                    .toUpperCase(),
                                                style: TulaiTextStyles.caption
                                                    .copyWith(
                                                  color: user['role'] == 'admin'
                                                      ? TulaiColors.warning
                                                      : TulaiColors.primary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit_outlined,
                                          color: TulaiColors.primary,
                                          size: isLargeScreen ? 24 : 20,
                                        ),
                                        onPressed: () =>
                                            _showEditUserDialog(user),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Edit User',
                                      ),
                                      const SizedBox(width: TulaiSpacing.xs),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: TulaiColors.error,
                                          size: isLargeScreen ? 24 : 20,
                                        ),
                                        onPressed: () => _deleteUser(
                                          user['id'],
                                          user['name'] ?? 'User',
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Delete User',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            childCount: _users.length,
                          ),
                        ),
                      ),
      ],
    );
  }

  Widget _buildAnalyticsView(bool isLargeScreen) {
    return const AdminAnalyticsPage();
  }

  Widget _buildEnrolleesView(bool isLargeScreen) {
    // Use the existing Enrollees widget with showAllBatches for super admin
    return const Enrollees(showAllBatches: true);
  }

  Widget _buildBatchManagementView(bool isLargeScreen) {
    return BatchManagementSection(isLargeScreen: isLargeScreen);
  }

  Widget _buildStatCard(
      String value, String label, Color color, IconData icon) {
    return TulaiCard(
      backgroundColor: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TulaiSpacing.md,
          vertical: TulaiSpacing.lg,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(TulaiSpacing.sm),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: TulaiSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TulaiTextStyles.heading1.copyWith(
                        color: color,
                        fontSize: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TulaiTextStyles.bodySmall.copyWith(
                      color: TulaiColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _selectedIndex = 0;
  List<NavigationRailDestination> get _navDestinations => [
        const NavigationRailDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people, color: TulaiColors.primary),
          label: Text('Users'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart, color: TulaiColors.primary),
          label: Text('Analytics'),
        ),
        if (AppConfig().isSuperAdmin)
          const NavigationRailDestination(
            icon: Icon(Icons.layers_outlined),
            selectedIcon: Icon(Icons.layers, color: TulaiColors.primary),
            label: Text('Batches'),
          ),
        if (AppConfig().isSuperAdmin)
          const NavigationRailDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school, color: TulaiColors.primary),
            label: Text('Enrollees'),
          ),
      ];

  void _onNavSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 800;
    final navItems = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart), label: 'Analytics'),
      if (AppConfig().isSuperAdmin)
        const BottomNavigationBarItem(
            icon: Icon(Icons.layers), label: 'Batches'),
      if (AppConfig().isSuperAdmin)
        const BottomNavigationBarItem(
            icon: Icon(Icons.school), label: 'Enrollees'),
    ];

    final pages = [
      _buildUsersView(isLargeScreen),
      _buildAnalyticsView(isLargeScreen),
      if (AppConfig().isSuperAdmin) _buildBatchManagementView(isLargeScreen),
      if (AppConfig().isSuperAdmin) _buildEnrolleesView(isLargeScreen),
    ];

    return Scaffold(
      backgroundColor: TulaiColors.backgroundSecondary,
      body: isLargeScreen
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onNavSelected,
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: TulaiColors.backgroundPrimary,
                  destinations: _navDestinations,
                  leading: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: TulaiSpacing.md),
                    child: Column(
                      children: [
                        Image.asset('assets/images/tulai-logo.png', height: 40),
                        const SizedBox(height: TulaiSpacing.sm),
                        Text('TULAI',
                            style: TulaiTextStyles.heading3.copyWith(
                                color: TulaiColors.primary,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: TulaiSpacing.lg),
                        child: IconButton(
                          icon: const Icon(Icons.logout),
                          onPressed: _logout,
                          tooltip: 'Logout',
                          color: TulaiColors.error,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: pages,
                  ),
                ),
              ],
            )
          : Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Container(
                    color: TulaiColors.backgroundPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: TulaiSpacing.md,
                      vertical: TulaiSpacing.sm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Image.asset('assets/images/tulai-logo.png',
                                height: 30),
                            const SizedBox(width: TulaiSpacing.sm),
                            Text('TULAI',
                                style: TulaiTextStyles.heading3.copyWith(
                                    color: TulaiColors.primary,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout),
                          onPressed: _logout,
                          tooltip: 'Logout',
                          color: TulaiColors.error,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: pages,
                  ),
                ),
                SafeArea(
                  top: false,
                  child: BottomNavigationBar(
                    currentIndex: _selectedIndex,
                    onTap: (i) => setState(() => _selectedIndex = i),
                    items: navItems,
                    type: BottomNavigationBarType.fixed,
                    selectedItemColor: TulaiColors.primary,
                    unselectedItemColor: TulaiColors.textMuted,
                    backgroundColor: TulaiColors.backgroundPrimary,
                    showUnselectedLabels: true,
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _usersChannel?.unsubscribe();
    super.dispose();
  }
}

class BatchManagementSection extends StatefulWidget {
  final bool isLargeScreen;
  const BatchManagementSection({Key? key, required this.isLargeScreen})
      : super(key: key);

  @override
  State<BatchManagementSection> createState() => _BatchManagementSectionState();
}

class _BatchManagementSectionState extends State<BatchManagementSection> {
  final _formKey = GlobalKey<FormState>();
  final _startYearController = TextEditingController();
  final _endYearController = TextEditingController();
  List<Batch> _batches = [];
  String? _activeBatchId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    setState(() => _isLoading = true);
    final batches = await BatchDatabase.getBatches();
    setState(() {
      _batches = batches;
      // Find the first batch marked as active, or default to the first batch
      final active = batches.firstWhere(
        (b) => b.id == _activeBatchId,
        orElse: () => batches.isNotEmpty
            ? batches.first
            : Batch(id: '', startYear: 0, endYear: 0),
      );
      _activeBatchId = active.id;
      _isLoading = false;
    });
  }

  Future<void> _createBatch() async {
    if (_formKey.currentState?.validate() ?? false) {
      final startYear = int.tryParse(_startYearController.text);
      final endYear = int.tryParse(_endYearController.text);
      if (startYear != null && endYear != null) {
        await BatchDatabase.createBatch(startYear, endYear);
        _startYearController.clear();
        _endYearController.clear();
        await _loadBatches();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Batch created successfully'),
              backgroundColor: TulaiColors.success,
            ),
          );
        }
      }
    }
  }

  Future<void> _setActiveBatch(String batchId) async {
    await BatchDatabase.setActiveBatch(batchId);
    setState(() => _activeBatchId = batchId);
    await _loadBatches();
  }

  Future<void> _showCreateBatchDialog() async {
    final isLargeScreen = MediaQuery.of(context).size.width > 800;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TulaiBorderRadius.lg),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isLargeScreen ? 500 : 400,
          ),
          padding:
              EdgeInsets.all(isLargeScreen ? TulaiSpacing.xl : TulaiSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(TulaiSpacing.sm),
                    decoration: BoxDecoration(
                      color: TulaiColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline,
                      color: TulaiColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: TulaiSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create New Batch',
                          style: TulaiTextStyles.heading3.copyWith(
                            color: TulaiColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add a new academic year',
                          style: TulaiTextStyles.bodySmall.copyWith(
                            color: TulaiColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: TulaiColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: TulaiSpacing.lg),
              const Divider(color: TulaiColors.borderLight),
              const SizedBox(height: TulaiSpacing.lg),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _startYearController,
                      decoration: InputDecoration(
                        labelText: 'Start Year',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(TulaiBorderRadius.md),
                        ),
                        hintText: 'e.g., 2024',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: TulaiSpacing.md),
                    TextFormField(
                      controller: _endYearController,
                      decoration: InputDecoration(
                        labelText: 'End Year',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(TulaiBorderRadius.md),
                        ),
                        hintText: 'e.g., 2025',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TulaiSpacing.lg),
              const Divider(color: TulaiColors.borderLight),
              const SizedBox(height: TulaiSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TulaiTextStyles.bodyMedium.copyWith(
                        color: TulaiColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: TulaiSpacing.sm),
                  ElevatedButton.icon(
                    onPressed: _createBatch,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Create Batch'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TulaiColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            isLargeScreen ? TulaiSpacing.lg : TulaiSpacing.md,
                        vertical: TulaiSpacing.sm,
                      ),
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

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.all(
                widget.isLargeScreen ? TulaiSpacing.xl : TulaiSpacing.lg),
            color: TulaiColors.backgroundPrimary,
            child: Row(
              children: [
                Icon(
                  Icons.layers,
                  size: widget.isLargeScreen ? 40 : 32,
                  color: TulaiColors.primary,
                ),
                const SizedBox(width: TulaiSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Batch Management',
                        style: TulaiTextStyles.heading2.copyWith(
                          color: TulaiColors.primary,
                          fontSize: widget.isLargeScreen ? 28 : 24,
                        ),
                      ),
                      Text(
                        'Manage academic year batches',
                        style: TulaiTextStyles.bodyMedium.copyWith(
                          color: TulaiColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showCreateBatchDialog,
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(widget.isLargeScreen ? 'New Batch' : 'New'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TulaiColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.isLargeScreen
                          ? TulaiSpacing.lg
                          : TulaiSpacing.md,
                      vertical: widget.isLargeScreen
                          ? TulaiSpacing.md
                          : TulaiSpacing.sm,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Statistics
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(
                widget.isLargeScreen ? TulaiSpacing.xl : TulaiSpacing.lg),
            child: widget.isLargeScreen
                ? Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          '${_batches.length}',
                          'Total Batches',
                          TulaiColors.primary,
                          Icons.layers,
                        ),
                      ),
                      const SizedBox(width: TulaiSpacing.lg),
                      Expanded(
                        child: _buildStatCard(
                          '1',
                          'Active Batch',
                          TulaiColors.success,
                          Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: TulaiSpacing.lg),
                      Expanded(
                        child: _buildStatCard(
                          _activeBatchId != null
                              ? _batches
                                      .firstWhere((b) => b.id == _activeBatchId,
                                          orElse: () => Batch(
                                              id: '', startYear: 0, endYear: 0))
                                      .startYear
                                      .toString() +
                                  '-' +
                                  _batches
                                      .firstWhere((b) => b.id == _activeBatchId,
                                          orElse: () => Batch(
                                              id: '', startYear: 0, endYear: 0))
                                      .endYear
                                      .toString()
                              : 'None',
                          'Current Year',
                          TulaiColors.info,
                          Icons.calendar_today,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          '${_batches.length}',
                          'Total',
                          TulaiColors.primary,
                          Icons.layers,
                        ),
                      ),
                      const SizedBox(width: TulaiSpacing.md),
                      Expanded(
                        child: _buildStatCard(
                          '1',
                          'Active',
                          TulaiColors.success,
                          Icons.check_circle,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        // Existing Batches Section
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(
                widget.isLargeScreen ? TulaiSpacing.xl : TulaiSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(TulaiSpacing.xs),
                  decoration: BoxDecoration(
                    color: TulaiColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(TulaiBorderRadius.sm),
                  ),
                  child: const Icon(
                    Icons.list,
                    color: TulaiColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: TulaiSpacing.sm),
                Text(
                  'All Batches',
                  style: TulaiTextStyles.heading3.copyWith(
                    color: TulaiColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Batches List
        _isLoading
            ? const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: TulaiColors.primary,
                  ),
                ),
              )
            : _batches.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.layers_outlined,
                            size: 64,
                            color: TulaiColors.textMuted,
                          ),
                          const SizedBox(height: TulaiSpacing.md),
                          Text(
                            'No batches found',
                            style: TulaiTextStyles.bodyLarge.copyWith(
                              color: TulaiColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: TulaiSpacing.sm),
                          Text(
                            'Create your first batch to get started',
                            style: TulaiTextStyles.bodyMedium.copyWith(
                              color: TulaiColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.isLargeScreen
                          ? TulaiSpacing.xl
                          : TulaiSpacing.lg,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final batch = _batches[index];
                          final isActive = batch.id == _activeBatchId;
                          return Container(
                            margin: EdgeInsets.only(
                              bottom: widget.isLargeScreen
                                  ? TulaiSpacing.md
                                  : TulaiSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: TulaiColors.backgroundPrimary,
                              borderRadius:
                                  BorderRadius.circular(TulaiBorderRadius.md),
                              border: Border.all(
                                color: isActive
                                    ? TulaiColors.success.withOpacity(0.3)
                                    : TulaiColors.borderLight,
                                width: isActive ? 2 : 1,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(
                                widget.isLargeScreen
                                    ? TulaiSpacing.lg
                                    : TulaiSpacing.md,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(
                                      widget.isLargeScreen
                                          ? TulaiSpacing.sm
                                          : TulaiSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? TulaiColors.success.withOpacity(0.1)
                                          : TulaiColors.primary
                                              .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                          TulaiBorderRadius.md),
                                    ),
                                    child: Icon(
                                      isActive
                                          ? Icons.check_circle
                                          : Icons.layers,
                                      color: isActive
                                          ? TulaiColors.success
                                          : TulaiColors.primary,
                                      size: widget.isLargeScreen ? 24 : 20,
                                    ),
                                  ),
                                  SizedBox(
                                      width: widget.isLargeScreen
                                          ? TulaiSpacing.md
                                          : TulaiSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Batch ${batch.startYear} - ${batch.endYear}',
                                          style: TulaiTextStyles.bodyLarge
                                              .copyWith(
                                            fontWeight: FontWeight.w600,
                                            fontSize:
                                                widget.isLargeScreen ? 16 : 15,
                                          ),
                                        ),
                                        if (isActive ||
                                            widget.isLargeScreen) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            isActive
                                                ? 'Currently active batch'
                                                : 'Academic Year ${batch.startYear}-${batch.endYear}',
                                            style: TulaiTextStyles.bodySmall
                                                .copyWith(
                                              color: TulaiColors.textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (isActive)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: widget.isLargeScreen
                                            ? TulaiSpacing.md
                                            : TulaiSpacing.sm,
                                        vertical: TulaiSpacing.xs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: TulaiColors.success
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(
                                            TulaiBorderRadius.sm),
                                      ),
                                      child: widget.isLargeScreen
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.check_circle,
                                                  color: TulaiColors.success,
                                                  size: 16,
                                                ),
                                                const SizedBox(
                                                    width: TulaiSpacing.xs),
                                                Text(
                                                  'ACTIVE',
                                                  style: TulaiTextStyles.caption
                                                      .copyWith(
                                                    color: TulaiColors.success,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : const Icon(
                                              Icons.check_circle,
                                              color: TulaiColors.success,
                                              size: 18,
                                            ),
                                    )
                                  else
                                    widget.isLargeScreen
                                        ? ElevatedButton(
                                            onPressed: () =>
                                                _setActiveBatch(batch.id),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  TulaiColors.primary,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: TulaiSpacing.lg,
                                                vertical: TulaiSpacing.sm,
                                              ),
                                            ),
                                            child: const Text('Set Active'),
                                          )
                                        : TextButton(
                                            onPressed: () =>
                                                _setActiveBatch(batch.id),
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  TulaiColors.primary,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: TulaiSpacing.sm,
                                                vertical: TulaiSpacing.xs,
                                              ),
                                            ),
                                            child: const Text('Activate'),
                                          ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: _batches.length,
                      ),
                    ),
                  ),

        const SliverToBoxAdapter(child: SizedBox(height: TulaiSpacing.xl)),
      ],
    );
  }

  Widget _buildStatCard(
      String value, String label, Color color, IconData icon) {
    return TulaiCard(
      backgroundColor: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TulaiSpacing.md,
          vertical: TulaiSpacing.lg,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(TulaiSpacing.sm),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: TulaiSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TulaiTextStyles.heading1.copyWith(
                        color: color,
                        fontSize: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TulaiTextStyles.bodySmall.copyWith(
                      color: TulaiColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
