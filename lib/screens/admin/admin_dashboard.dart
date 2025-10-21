import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tulai/core/app_config.dart';
import 'package:tulai/core/design_system.dart';
import 'package:tulai/widgets/appbar.dart';
import 'package:tulai/screens/admin/admin_analytics_page.dart';

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
  final List<String> _adminTabs = [
    'Users',
    'Analytics',
  ];
  final List<String> _superAdminTabs = [
    'Users',
    'Analytics',
    'Enrollees',
  ];

  List<String> get _tabs =>
      AppConfig().isSuperAdmin ? _superAdminTabs : _adminTabs;

  void _onTabSelected(int index) {
    setState(() {
      _tabController!.index = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController!.addListener(() {
      setState(() {});
    });
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _supabase
          .from('users')
          .select('*')
          .order('created_at', ascending: false);

      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
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
    return Column(
      children: [
        // Header
        Container(
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

        // Statistics
        Container(
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

        // Users List
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: TulaiColors.primary,
                  ),
                )
              : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: TulaiColors.error,
                          ),
                          const SizedBox(height: TulaiSpacing.md),
                          Text(
                            _errorMessage!,
                            style: TulaiTextStyles.bodyLarge.copyWith(
                              color: TulaiColors.error,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(
                        isLargeScreen ? TulaiSpacing.xl : TulaiSpacing.lg,
                      ),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return TulaiCard(
                          margin:
                              const EdgeInsets.only(bottom: TulaiSpacing.md),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isLargeScreen
                                  ? TulaiSpacing.xl
                                  : TulaiSpacing.lg,
                              vertical: TulaiSpacing.sm,
                            ),
                            leading: CircleAvatar(
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
                            title: Text(
                              user['name'] ?? 'No name',
                              style: TulaiTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: isLargeScreen ? 18 : 16,
                              ),
                            ),
                            subtitle: Text(
                              user['email'] ?? 'No email',
                              style: TulaiTextStyles.bodyMedium.copyWith(
                                color: TulaiColors.textSecondary,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isLargeScreen
                                        ? TulaiSpacing.lg
                                        : TulaiSpacing.md,
                                    vertical: TulaiSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (user['role'] == 'admin'
                                        ? TulaiColors.warning.withOpacity(0.2)
                                        : TulaiColors.primary.withOpacity(0.2)),
                                    borderRadius: BorderRadius.circular(
                                        TulaiBorderRadius.sm),
                                  ),
                                  child: Text(
                                    user['role'].toString().toUpperCase(),
                                    style: TulaiTextStyles.caption.copyWith(
                                      color: user['role'] == 'admin'
                                          ? TulaiColors.warning
                                          : TulaiColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                    width: isLargeScreen
                                        ? TulaiSpacing.md
                                        : TulaiSpacing.sm),
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
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsView(bool isLargeScreen) {
    return const AdminAnalyticsPage();
  }

  Widget _buildEnrolleesView(bool isLargeScreen) {
    // TODO: Import and show your enrollees view here
    return const Center(child: Text('Enrollees View (Super Admin Only)'));
  }

  Widget _buildStatCard(
      String value, String label, Color color, IconData icon) {
    return TulaiCard(
      backgroundColor: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(TulaiSpacing.lg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(TulaiSpacing.md),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(width: TulaiSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TulaiTextStyles.heading1.copyWith(
                      color: color,
                      fontSize: 32,
                    ),
                  ),
                  Text(
                    label,
                    style: TulaiTextStyles.bodyMedium.copyWith(
                      color: TulaiColors.textSecondary,
                    ),
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
    return Scaffold(
      backgroundColor: TulaiColors.backgroundSecondary,
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onNavSelected,
              labelType: NavigationRailLabelType.all,
              backgroundColor: TulaiColors.backgroundPrimary,
              destinations: _navDestinations,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: TulaiSpacing.md),
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
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildUsersView(isLargeScreen),
                  _buildAnalyticsView(isLargeScreen),
                  if (AppConfig().isSuperAdmin)
                    _buildEnrolleesView(isLargeScreen),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
