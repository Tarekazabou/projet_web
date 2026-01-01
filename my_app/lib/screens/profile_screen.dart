import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/mealy_theme.dart';
import 'notification_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.animationController});

  final AnimationController? animationController;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  Animation<double>? topBarAnimation;
  AnimationController? animationController;
  double topBarOpacity = 0.0;
  final ScrollController scrollController = ScrollController();

  final String _userName = 'Demo User';
  final String _userEmail = 'demo@mealy.com';

  List<String> _dietaryRestrictions = ['Vegetarian'];
  List<String> _allergens = ['Nuts'];

  @override
  void initState() {
    super.initState();
    animationController = widget.animationController ??
        AnimationController(
          duration: const Duration(milliseconds: 600),
          vsync: this,
        );

    topBarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController!,
        curve: const Interval(0, 0.5, curve: Curves.fastOutSlowIn),
      ),
    );

    scrollController.addListener(() {
      if (scrollController.offset >= 24) {
        if (topBarOpacity != 1.0) {
          setState(() => topBarOpacity = 1.0);
        }
      } else if (scrollController.offset <= 24 && scrollController.offset >= 0) {
        if (topBarOpacity != scrollController.offset / 24) {
          setState(() => topBarOpacity = scrollController.offset / 24);
        }
      } else if (scrollController.offset <= 0) {
        if (topBarOpacity != 0.0) {
          setState(() => topBarOpacity = 0.0);
        }
      }
    });

    animationController?.forward();
  }

  @override
  void dispose() {
    if (widget.animationController == null) {
      animationController?.dispose();
    }
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Container(
      color: MealyTheme.background,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            _buildMainContent(user),
            _buildTopBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: animationController!,
          builder: (context, child) {
            return FadeTransition(
              opacity: topBarAnimation!,
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - topBarAnimation!.value)),
                child: Container(
                  decoration: BoxDecoration(
                    color: MealyTheme.white.withOpacity(topBarOpacity),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: MealyTheme.grey.withOpacity(0.4 * topBarOpacity),
                        offset: const Offset(1.1, 1.1),
                        blurRadius: 10.0,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top),
                      Padding(
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16 - 8.0 * topBarOpacity,
                          bottom: 12 - 8.0 * topBarOpacity,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Profile',
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontFamily: MealyTheme.fontName,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 22 + 6 - 6 * topBarOpacity,
                                    letterSpacing: 1.2,
                                    color: MealyTheme.darkerText,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMainContent(dynamic user) {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 88,
        bottom: 100,
      ),
      children: [
        _buildProfileHeader(user),
        const SizedBox(height: 24),
        _buildStatsRow(),
        const SizedBox(height: 24),
        _buildPreferencesCard(),
        const SizedBox(height: 16),
        _buildSettingsCard(),
        const SizedBox(height: 16),
        _buildAboutCard(),
        const SizedBox(height: 24),
        _buildLogoutButton(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildProfileHeader(dynamic user) {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (context, child) {
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animationController!,
            curve: const Interval(0.0, 0.5, curve: Curves.fastOutSlowIn),
          ),
        );
        return FadeTransition(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - animation.value)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      MealyTheme.nearlyOrange,
                      MealyTheme.nearlyOrange.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(8.0),
                    bottomLeft: Radius.circular(8.0),
                    topLeft: Radius.circular(8.0),
                    topRight: Radius.circular(68.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: MealyTheme.nearlyOrange.withOpacity(0.4),
                      offset: const Offset(1.1, 4.0),
                      blurRadius: 8.0,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: MealyTheme.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: MealyTheme.white,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 44,
                          color: MealyTheme.white,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? _userName,
                              style: const TextStyle(
                                fontFamily: MealyTheme.fontName,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: MealyTheme.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? _userEmail,
                              style: TextStyle(
                                fontFamily: MealyTheme.fontName,
                                fontSize: 14,
                                color: MealyTheme.white.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: MealyTheme.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Premium Member',
                                style: TextStyle(
                                  fontFamily: MealyTheme.fontName,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: MealyTheme.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsRow() {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (context, child) {
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animationController!,
            curve: const Interval(0.1, 0.6, curve: Curves.fastOutSlowIn),
          ),
        );
        return FadeTransition(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - animation.value)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _buildStatCard('12', 'Recipes\nSaved', Icons.bookmark)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('28', 'Meals\nPlanned', Icons.calendar_month)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('45', 'Items\nTracked', Icons.kitchen)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MealyTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: MealyTheme.grey.withOpacity(0.1),
            offset: const Offset(1.1, 1.1),
            blurRadius: 10.0,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: MealyTheme.nearlyOrange, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: MealyTheme.fontName,
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: MealyTheme.darkerText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: MealyTheme.fontName,
              fontSize: 12,
              color: MealyTheme.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (context, child) {
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animationController!,
            curve: const Interval(0.2, 0.7, curve: Curves.fastOutSlowIn),
          ),
        );
        return FadeTransition(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - animation.value)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: MealyTheme.white,
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(8.0),
                    bottomLeft: Radius.circular(8.0),
                    topLeft: Radius.circular(8.0),
                    topRight: Radius.circular(54.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: MealyTheme.grey.withOpacity(0.1),
                      offset: const Offset(1.1, 1.1),
                      blurRadius: 10.0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: MealyTheme.nearlyGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.restaurant,
                              color: MealyTheme.nearlyGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Food Preferences',
                            style: TextStyle(
                              fontFamily: MealyTheme.fontName,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: MealyTheme.darkerText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    _buildPreferenceItem(
                      'Dietary Restrictions',
                      _dietaryRestrictions.join(', '),
                      Icons.eco,
                      () => _showDietaryRestrictionsDialog(),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _buildPreferenceItem(
                      'Allergens',
                      _allergens.join(', '),
                      Icons.warning_amber,
                      () => _showAllergensDialog(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreferenceItem(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: MealyTheme.nearlyOrange, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: MealyTheme.fontName,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: MealyTheme.darkerText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: MealyTheme.fontName,
                      fontSize: 13,
                      color: MealyTheme.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: MealyTheme.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (context, child) {
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animationController!,
            curve: const Interval(0.3, 0.8, curve: Curves.fastOutSlowIn),
          ),
        );
        return FadeTransition(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - animation.value)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: MealyTheme.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: MealyTheme.grey.withOpacity(0.1),
                      offset: const Offset(1.1, 1.1),
                      blurRadius: 10.0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingsItem(
                      'Notifications',
                      Icons.notifications_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _buildSettingsItem(
                      'Favorite Recipes',
                      Icons.favorite_border,
                      onTap: () => _showComingSoon(),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _buildSettingsItem(
                      'Recipe History',
                      Icons.history,
                      onTap: () => _showComingSoon(),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _buildSettingsItem(
                      'Help & Support',
                      Icons.help_outline,
                      onTap: () => _showComingSoon(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsItem(String title, IconData icon, {Widget? trailing, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: MealyTheme.nearlyOrange, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: MealyTheme.fontName,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: MealyTheme.darkerText,
                ),
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right, color: MealyTheme.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (context, child) {
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animationController!,
            curve: const Interval(0.4, 0.9, curve: Curves.fastOutSlowIn),
          ),
        );
        return FadeTransition(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - animation.value)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () => _showAboutDialog(),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: MealyTheme.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: MealyTheme.grey.withOpacity(0.1),
                        offset: const Offset(1.1, 1.1),
                        blurRadius: 10.0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              MealyTheme.nearlyGreen,
                              MealyTheme.nearlyGreen.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.restaurant_menu,
                          color: MealyTheme.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'About Mealy',
                              style: TextStyle(
                                fontFamily: MealyTheme.fontName,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: MealyTheme.darkerText,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Version 1.0.0',
                              style: TextStyle(
                                fontFamily: MealyTheme.fontName,
                                fontSize: 13,
                                color: MealyTheme.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: MealyTheme.grey),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton() {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (context, child) {
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animationController!,
            curve: const Interval(0.5, 1.0, curve: Curves.fastOutSlowIn),
          ),
        );
        return FadeTransition(
          opacity: animation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              onTap: () => _confirmLogout(),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: Colors.red.shade600),
                    const SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontFamily: MealyTheme.fontName,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Coming soon!'),
        backgroundColor: MealyTheme.nearlyOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Mealy',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [MealyTheme.nearlyOrange, MealyTheme.nearlyGreen],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.restaurant_menu, size: 40, color: MealyTheme.white),
      ),
      children: [
        const Text('Your AI-powered meal planning assistant'),
      ],
    );
  }

  void _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await Provider.of<AuthProvider>(context, listen: false).logout();
    }
  }

  void _showDietaryRestrictionsDialog() {
    final options = ['Vegetarian', 'Vegan', 'Pescatarian', 'Gluten-Free', 'Dairy-Free', 'Keto', 'Paleo'];
    final selected = List<String>.from(_dietaryRestrictions);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Dietary Restrictions'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options.map((option) {
                return CheckboxListTile(
                  title: Text(option),
                  value: selected.contains(option),
                  activeColor: MealyTheme.nearlyOrange,
                  onChanged: (checked) {
                    setDialogState(() {
                      if (checked == true) {
                        selected.add(option);
                      } else {
                        selected.remove(option);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _dietaryRestrictions = selected;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MealyTheme.nearlyOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAllergensDialog() {
    final options = ['Nuts', 'Dairy', 'Eggs', 'Soy', 'Shellfish', 'Fish', 'Wheat', 'Gluten'];
    final selected = List<String>.from(_allergens);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Allergens'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options.map((option) {
                return CheckboxListTile(
                  title: Text(option),
                  value: selected.contains(option),
                  activeColor: MealyTheme.nearlyOrange,
                  onChanged: (checked) {
                    setDialogState(() {
                      if (checked == true) {
                        selected.add(option);
                      } else {
                        selected.remove(option);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _allergens = selected;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MealyTheme.nearlyOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
