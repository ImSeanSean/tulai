// Example of how to use the Tulai Design System across different screens
// This file demonstrates the consistent styling approach you can apply

import 'package:flutter/material.dart';
import 'package:tulai/core/design_system.dart';

class ExampleScreenWithDesignSystem extends StatefulWidget {
  const ExampleScreenWithDesignSystem({super.key});

  @override
  State<ExampleScreenWithDesignSystem> createState() =>
      _ExampleScreenWithDesignSystemState();
}

class _ExampleScreenWithDesignSystemState
    extends State<ExampleScreenWithDesignSystem> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use design system colors
      backgroundColor: TulaiColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: TulaiColors.backgroundPrimary,
        elevation: 0,
        title: Text(
          'Example Screen',
          style: TulaiTextStyles.heading2,
        ),
        actions: [
          // Responsive design
          if (TulaiResponsive.isLargeScreen(context))
            Padding(
              padding: const EdgeInsets.only(right: TulaiSpacing.md),
              child: TulaiButton(
                text: 'Desktop Action',
                style: TulaiButtonStyle.ghost,
                size: TulaiButtonSize.small,
                onPressed: () {},
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TulaiSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page header with consistent typography
            Text(
              'Main Content Area',
              style: TulaiTextStyles.heading1,
            ),
            const SizedBox(height: TulaiSpacing.md),
            Text(
              'This demonstrates how to use the design system consistently across screens.',
              style: TulaiTextStyles.bodyMedium,
            ),
            const SizedBox(height: TulaiSpacing.xl),

            // Form section using design system components
            TulaiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Form Section',
                    style: TulaiTextStyles.heading3,
                  ),
                  const SizedBox(height: TulaiSpacing.md),

                  // Using TulaiTextField
                  TulaiTextField(
                    label: 'Example Input',
                    hint: 'Enter some text...',
                    controller: _textController,
                    prefixIcon: Icon(
                      Icons.edit,
                      color: TulaiColors.primary,
                    ),
                  ),
                  const SizedBox(height: TulaiSpacing.lg),

                  // Button examples
                  Wrap(
                    spacing: TulaiSpacing.md,
                    runSpacing: TulaiSpacing.sm,
                    children: [
                      TulaiButton(
                        text: 'Primary Action',
                        style: TulaiButtonStyle.primary,
                        isLoading: _isLoading,
                        onPressed: () {
                          setState(() {
                            _isLoading = !_isLoading;
                          });
                        },
                      ),
                      TulaiButton(
                        text: 'Secondary',
                        style: TulaiButtonStyle.secondary,
                        onPressed: () {},
                      ),
                      TulaiButton(
                        text: 'Outline',
                        style: TulaiButtonStyle.outline,
                        onPressed: () {},
                      ),
                      TulaiButton(
                        text: 'Ghost',
                        style: TulaiButtonStyle.ghost,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: TulaiSpacing.lg),

            // Information cards
            TulaiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              TulaiColors.primary,
                              TulaiColors.secondary
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius:
                              BorderRadius.circular(TulaiBorderRadius.round),
                        ),
                        child: const Icon(
                          Icons.info,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: TulaiSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Information Card',
                              style: TulaiTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'This shows how to create consistent information displays.',
                              style: TulaiTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: TulaiSpacing.lg),

            // Status badges
            Wrap(
              spacing: TulaiSpacing.sm,
              runSpacing: TulaiSpacing.sm,
              children: [
                _buildStatusBadge('Success', TulaiColors.success),
                _buildStatusBadge('Warning', TulaiColors.warning),
                _buildStatusBadge('Error', TulaiColors.error),
                _buildStatusBadge('Info', TulaiColors.info),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TulaiSpacing.md,
        vertical: TulaiSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(TulaiBorderRadius.xl),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Text(
        text,
        style: TulaiTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// Example of using responsive design
class ResponsiveLayoutExample extends StatelessWidget {
  const ResponsiveLayoutExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TulaiColors.backgroundSecondary,
      body: TulaiResponsive.responsive<Widget>(
        context: context,
        // Mobile layout
        mobile: Column(
          children: [
            _buildMobileHeader(),
            Expanded(child: _buildContent()),
          ],
        ),
        // Tablet layout
        tablet: Column(
          children: [
            _buildTabletHeader(),
            Expanded(child: _buildContent()),
          ],
        ),
        // Desktop layout
        desktop: Row(
          children: [
            SizedBox(
              width: 300,
              child: _buildSidebar(),
            ),
            Expanded(
              child: Column(
                children: [
                  _buildDesktopHeader(),
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      height: 60,
      color: TulaiColors.primary,
      child: const Center(
        child: Text(
          'Mobile Header',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTabletHeader() {
    return Container(
      height: 80,
      color: TulaiColors.primary,
      child: const Center(
        child: Text(
          'Tablet Header',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Container(
      height: 100,
      color: TulaiColors.primary,
      child: const Center(
        child: Text(
          'Desktop Header',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      color: TulaiColors.backgroundPrimary,
      child: const Center(
        child: Text('Sidebar'),
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      color: TulaiColors.backgroundSecondary,
      child: const Center(
        child: Text('Main Content'),
      ),
    );
  }
}
