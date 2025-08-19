# Tulai Design System

This design system provides a consistent visual language and reusable components for the Tulai ALS Enrollment System. It ensures consistency across mobile and web platforms while maintaining the app's visual identity.

## 🎨 Design Tokens

### Colors

- **Primary**: `TulaiColors.primary` - Main brand color (#0C15A6)
- **Secondary**: `TulaiColors.secondary` - Accent color (#40AD5F)
- **Text Colors**: `textPrimary`, `textSecondary`, `textMuted`
- **Background Colors**: `backgroundPrimary`, `backgroundSecondary`, `backgroundMuted`
- **Status Colors**: `success`, `warning`, `error`, `info`

### Typography

- **Headings**: `TulaiTextStyles.heading1`, `heading2`, `heading3`
- **Body Text**: `TulaiTextStyles.bodyLarge`, `bodyMedium`, `bodySmall`
- **Labels**: `TulaiTextStyles.labelLarge`, `labelMedium`, `labelSmall`
- **Caption**: `TulaiTextStyles.caption`

### Spacing

- **Consistent spacing**: `TulaiSpacing.xs` (4px) to `TulaiSpacing.xxl` (48px)
- **Use for margins, padding, and gaps**

### Border Radius

- **Consistent rounded corners**: `TulaiBorderRadius.sm` to `TulaiBorderRadius.round`

### Shadows

- **Elevation levels**: `TulaiShadows.sm`, `TulaiShadows.md`, `TulaiShadows.lg`

## 🧩 Components

### TulaiCard

Reusable card component with consistent styling:

```dart
TulaiCard(
  onTap: () {}, // Optional tap handler
  child: Text('Card content'),
)
```

### TulaiButton

Consistent button styling with multiple variants:

```dart
TulaiButton(
  text: 'Click me',
  style: TulaiButtonStyle.primary, // primary, secondary, outline, ghost
  size: TulaiButtonSize.medium,    // small, medium, large
  onPressed: () {},
)
```

### TulaiTextField

Styled text input with consistent appearance:

```dart
TulaiTextField(
  label: 'Input Label',
  hint: 'Placeholder text',
  controller: textController,
  prefixIcon: Icon(Icons.search),
)
```

## 📱 Responsive Design

### Breakpoints

- **Mobile**: < 640px
- **Tablet**: 768px - 1024px
- **Desktop**: > 1024px

### Usage

```dart
// Check screen size
bool isLargeScreen = TulaiResponsive.isLargeScreen(context);

// Responsive values
Widget content = TulaiResponsive.responsive<Widget>(
  context: context,
  mobile: MobileWidget(),
  tablet: TabletWidget(),
  desktop: DesktopWidget(),
);
```

## 🎯 Best Practices

### 1. Consistent Spacing

```dart
// ✅ Good
const EdgeInsets.all(TulaiSpacing.md)

// ❌ Avoid
const EdgeInsets.all(16.0)
```

### 2. Typography Hierarchy

```dart
// ✅ Good
Text('Heading', style: TulaiTextStyles.heading2)

// ❌ Avoid
Text('Heading', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
```

### 3. Color Usage

```dart
// ✅ Good
color: TulaiColors.primary

// ❌ Avoid
color: Color(0xff0C15A6)
```

### 4. Component Reuse

```dart
// ✅ Good - Use design system components
TulaiButton(text: 'Save', onPressed: onSave)

// ❌ Avoid - Custom buttons that look different
ElevatedButton(...)
```

## 🔄 Migration Guide

### From Old Styling to Design System

**Before:**

```dart
Container(
  padding: EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [BoxShadow(...)],
  ),
  child: Text('Content'),
)
```

**After:**

```dart
TulaiCard(
  child: Text('Content'),
)
```

## 📁 File Structure

```
lib/
  core/
    design_system.dart     # Main design system file
  examples/
    design_system_usage.dart # Usage examples
  screens/
    teacher/
      enrollees.dart       # Updated with design system
```

## 🚀 Usage in New Screens

1. Import the design system:

```dart
import 'package:tulai/core/design_system.dart';
```

2. Use design tokens and components:

```dart
Scaffold(
  backgroundColor: TulaiColors.backgroundSecondary,
  appBar: AppBar(
    title: Text('Screen Title', style: TulaiTextStyles.heading2),
  ),
  body: Padding(
    padding: const EdgeInsets.all(TulaiSpacing.lg),
    child: Column(
      children: [
        TulaiCard(
          child: Text('Card content', style: TulaiTextStyles.bodyMedium),
        ),
        const SizedBox(height: TulaiSpacing.md),
        TulaiButton(
          text: 'Action',
          onPressed: () {},
        ),
      ],
    ),
  ),
)
```

## 🎨 Theming

The design system automatically adapts to your app's theme defined in `main.dart`. The colors are consistent with:

- Primary: #0C15A6 (Blue)
- Secondary: #40AD5F (Green)
- Accent: #05AF35 (Bright Green)

This ensures all screens maintain visual consistency while being suitable for both mobile and web platforms.
