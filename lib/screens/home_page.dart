import 'package:flutter/material.dart';
import 'package:tulai/core/design_system.dart';
import 'package:tulai/screens/teacher/enrollees.dart';
import 'package:tulai/screens/teacher/pending_submissions.dart';
import 'package:tulai/screens/teacher/settings.dart';
import 'package:tulai/screens/student/enrollment_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  bool isSidebarExpanded = false; // Collapsed by default

  final List<NavigationItem> navigationItems = const [
    NavigationItem(
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      label: 'Enrollees',
      description: 'View and manage student enrollments',
    ),
    NavigationItem(
      icon: Icons.pending_actions_outlined,
      selectedIcon: Icons.pending_actions,
      label: 'Pending Submissions',
      description: 'Review and approve student submissions',
    ),
    NavigationItem(
      icon: Icons.person_add_outlined,
      selectedIcon: Icons.person_add,
      label: 'New Enrollment',
      description: 'Enroll a new student',
    ),
    NavigationItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
      description: 'Configure app settings and preferences',
    ),
  ];

  Widget _getBody() {
    switch (selectedIndex) {
      case 0:
        return const Enrollees();
      case 1:
        return const PendingSubmissions();
      case 2:
        return EnrollmentPage(
          onBackToTeacherDashboard: () {
            setState(() {
              selectedIndex = 0; // Return to Enrollees page
            });
          },
        );
      case 3:
        return const TeacherSettings();
      default:
        return _buildWelcomeScreen();
    }
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school,
            size: 80,
            color: TulaiColors.primary,
          ),
          const SizedBox(height: TulaiSpacing.lg),
          Text(
            'Welcome to Tulai',
            style: TulaiTextStyles.heading1,
          ),
          const SizedBox(height: TulaiSpacing.sm),
          Text(
            'ALS Enrollment System',
            style: TulaiTextStyles.bodyLarge.copyWith(
              color: TulaiColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = TulaiResponsive.isLargeScreen(context);
    final sidebarWidth = isSidebarExpanded ? 280.0 : 72.0;
    final isEnrollmentPage = selectedIndex ==
        2; // Hide sidebar when enrollment is open (New Enrollment)

    if (isLargeScreen) {
      // Desktop/tablet layout with collapsible sidebar
      return Scaffold(
        backgroundColor: TulaiColors.backgroundSecondary,
        body: Row(
          children: [
            // Collapsible sidebar navigation - hide when enrollment is open
            if (!isEnrollmentPage)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                width: sidebarWidth,
                decoration: BoxDecoration(
                  color: TulaiColors.backgroundPrimary,
                  boxShadow: TulaiShadows.md,
                ),
                child: Column(
                  children: [
                    // Header with logos
                    _buildSidebarHeader(),
                    // Navigation items
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(TulaiSpacing.md),
                        itemCount: navigationItems.length,
                        itemBuilder: (context, index) {
                          return _buildSidebarItem(
                              navigationItems[index], index);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            // Main content area
            Expanded(
              child: _getBody(),
            ),
          ],
        ),
      );
    } else {
      // Mobile layout with bottom navigation - hide bottom nav when enrollment is open
      return Scaffold(
        backgroundColor: TulaiColors.backgroundSecondary,
        appBar: isEnrollmentPage ? null : _buildMobileAppBar(),
        body: _getBody(),
        bottomNavigationBar: isEnrollmentPage ? null : _buildBottomNavigation(),
      );
    }
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding:
          EdgeInsets.all(isSidebarExpanded ? TulaiSpacing.lg : TulaiSpacing.md),
      decoration: BoxDecoration(
        color: TulaiColors.primary,
        border: Border(
          bottom: BorderSide(
            color: TulaiColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          if (isSidebarExpanded) ...[
            // Expanded header with logos and text
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
                  ),
                  child: Image.asset(
                    'assets/images/deped-logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: TulaiSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tulai',
                        style: TulaiTextStyles.heading3.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'ALS Enrollment System',
                        style: TulaiTextStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(TulaiBorderRadius.sm),
                  ),
                  child: Image.asset(
                    'assets/images/als-logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TulaiSpacing.md),
          ] else ...[
            // Collapsed header with just the main logo
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
              ),
              child: Image.asset(
                'assets/images/tulai-logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: TulaiSpacing.sm),
          ],
          // Toggle button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  isSidebarExpanded = !isSidebarExpanded;
                });
              },
              borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
              child: Container(
                padding: const EdgeInsets.all(TulaiSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
                ),
                child: Icon(
                  isSidebarExpanded ? Icons.menu_open : Icons.menu,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(NavigationItem item, int index) {
    final isSelected = selectedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: TulaiSpacing.sm),
      child: Tooltip(
        message: isSidebarExpanded ? '' : item.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                selectedIndex = index;
              });
            },
            borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
            child: Container(
              padding: EdgeInsets.all(
                  isSidebarExpanded ? TulaiSpacing.md : TulaiSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected
                    ? TulaiColors.primary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
                border: isSelected
                    ? Border.all(color: TulaiColors.primary.withOpacity(0.3))
                    : null,
              ),
              child: isSidebarExpanded
                  ? _buildExpandedSidebarItem(item, isSelected)
                  : _buildCollapsedSidebarItem(item, isSelected),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedSidebarItem(NavigationItem item, bool isSelected) {
    return Row(
      children: [
        Icon(
          isSelected ? item.selectedIcon : item.icon,
          color: isSelected ? TulaiColors.primary : TulaiColors.textSecondary,
          size: 24,
        ),
        const SizedBox(width: TulaiSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: TulaiTextStyles.bodyLarge.copyWith(
                  color: isSelected
                      ? TulaiColors.primary
                      : TulaiColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const SizedBox(height: TulaiSpacing.xs),
              Text(
                item.description,
                style: TulaiTextStyles.bodySmall.copyWith(
                  color: TulaiColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedSidebarItem(NavigationItem item, bool isSelected) {
    return Center(
      child: Icon(
        isSelected ? item.selectedIcon : item.icon,
        color: isSelected ? TulaiColors.primary : TulaiColors.textSecondary,
        size: 24,
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      backgroundColor: TulaiColors.backgroundPrimary,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(
          'assets/images/deped-logo.png',
          fit: BoxFit.contain,
        ),
      ),
      title: Column(
        children: [
          Text(
            'Tulai',
            style: TulaiTextStyles.heading3.copyWith(
              color: TulaiColors.primary,
            ),
          ),
          Text(
            'ALS Enrollment System',
            style: TulaiTextStyles.caption.copyWith(
              color: TulaiColors.textSecondary,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/images/als-logo.png',
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: TulaiColors.backgroundPrimary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TulaiSpacing.md,
            vertical: TulaiSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navigationItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = selectedIndex == index;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: TulaiSpacing.md,
                        horizontal: TulaiSpacing.sm,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(TulaiSpacing.sm),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? TulaiColors.primary
                                  : Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(TulaiBorderRadius.md),
                            ),
                            child: Icon(
                              isSelected ? item.selectedIcon : item.icon,
                              color: isSelected
                                  ? Colors.white
                                  : TulaiColors.textSecondary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: TulaiSpacing.xs),
                          Text(
                            item.label,
                            style: TulaiTextStyles.labelSmall.copyWith(
                              color: isSelected
                                  ? TulaiColors.primary
                                  : TulaiColors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String description;

  const NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.description,
  });
}
