import 'package:flutter/material.dart';

/// Tab icon data model for the bottom navigation bar
/// Inspired by Best Flutter UI Templates fitness app
class TabIconData {
  TabIconData({
    this.imagePath = '',
    this.selectedImagePath = '',
    this.index = 0,
    this.isSelected = false,
    this.animationController,
  });

  String imagePath;
  String selectedImagePath;
  int index;
  bool isSelected;
  AnimationController? animationController;

  /// Default tab icons for the Mealy app
  static List<TabIconData> tabIconsList = <TabIconData>[
    TabIconData(
      imagePath: 'assets/icons/tab_1.png',
      selectedImagePath: 'assets/icons/tab_1s.png',
      index: 0,
      isSelected: true,
    ),
    TabIconData(
      imagePath: 'assets/icons/tab_2.png',
      selectedImagePath: 'assets/icons/tab_2s.png',
      index: 1,
      isSelected: false,
    ),
    TabIconData(
      imagePath: 'assets/icons/tab_3.png',
      selectedImagePath: 'assets/icons/tab_3s.png',
      index: 2,
      isSelected: false,
    ),
    TabIconData(
      imagePath: 'assets/icons/tab_4.png',
      selectedImagePath: 'assets/icons/tab_4s.png',
      index: 3,
      isSelected: false,
    ),
  ];

  /// Icon-based tab data (fallback when assets not available)
  static List<TabIconData> createIconTabs() {
    return <TabIconData>[
      TabIconData(index: 0, isSelected: true),
      TabIconData(index: 1, isSelected: false),
      TabIconData(index: 2, isSelected: false),
      TabIconData(index: 3, isSelected: false),
    ];
  }
}

/// Tab item info for displaying labels and icons
class TabItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int index;

  const TabItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.index,
  });

  static const List<TabItem> items = [
    TabItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
      index: 0,
    ),
    TabItem(
      icon: Icons.kitchen_outlined,
      selectedIcon: Icons.kitchen_rounded,
      label: 'Fridge',
      index: 1,
    ),
    TabItem(
      icon: Icons.restaurant_menu_outlined,
      selectedIcon: Icons.restaurant_menu_rounded,
      label: 'Nutrition',
      index: 2,
    ),
    TabItem(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profile',
      index: 3,
    ),
  ];
}
