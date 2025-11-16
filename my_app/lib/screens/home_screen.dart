import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/recipe_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/recipe_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _statsIndex = 0;

  final List<Map<String, dynamic>> stats = [
    {
      'label': ' Delicious Recipes',
      'value': '12',
      'icon': Icons.restaurant_menu,
    },
    {
      'label': 'Meals Planned',
      'value': '7',
      'icon': Icons.calendar_today,
    },
    {
      'label': 'Ingredients',
      'value': '24',
      'icon': Icons.kitchen,
    },
  ];

  void _rotateStats(int direction) {
    setState(() {
      _statsIndex = (_statsIndex + direction) % stats.length;
      if (_statsIndex < 0) _statsIndex += stats.length;
    });
  }
  final _searchController = TextEditingController();
  
  final List<HomeFeature> features = [
    HomeFeature(
      name: 'AI Recipe Generator',
      icon: Icons.auto_awesome,
      description: 'Create personalized recipes',
      color: Colors.purple,
    ),
    HomeFeature(
      name: 'Meal Planner',
      icon: Icons.calendar_today,
      description: 'Plan your weekly meals',
      color: Colors.blue,
    ),
    HomeFeature(
      name: 'Your Fridge',
      icon: Icons.kitchen,
      description: 'Manage ingredients',
      color: Colors.green,
    ),
    HomeFeature(
      name: 'Nutrition',
      icon: Icons.monitor_heart,
      description: 'Track calories & macros',
      color: Colors.orange,
    ),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<RecipeProvider>(context, listen: false).loadRecipes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.currentUser?.name ?? 'User';
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4CAF50), // Green
              Color(0xFF81C784), // Light Green
            ],
          ),
        ),
        child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Provider.of<RecipeProvider>(context, listen: false).loadRecipes();
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                // Header with User Info
                _buildHeader(userName),
                SizedBox(height: 10.h),
                // Rotatable Stats Row
                _buildRotatableStatsRow(),
                SizedBox(height: 25.h),
                // Quick Actions Grid
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22.sp,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 15.h),
                _buildFeaturesGrid(),
                SizedBox(height: 25.h),
                // Today's Meal Plan
                _buildTodaysMealPlan(),
                SizedBox(height: 25.h),
                // AI Recipe Suggestions
                _buildAISuggestions(),
                SizedBox(height: 25.h),
                // Recent Recipes
                _buildRecentRecipes(),
                SizedBox(height: 100.h),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildHeader(String userName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, $userName! 👋',
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          "What's cooking today?",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24.sp,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildRotatableStatsRow() {
    // Rotate the stats list so the selected index is in the middle
    final List<Map<String, dynamic>> orderedStats = [
      stats[(_statsIndex + 2) % stats.length],
      stats[_statsIndex],
      stats[(_statsIndex + 1) % stats.length],
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left, size: 28.r),
          onPressed: () => _rotateStats(-1),
        ),
        // Left stat card (small)
        Expanded(
          flex: 1,
          child: Transform.scale(
            scale: 0.75,
            child: Opacity(
              opacity: 0.6,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: _buildStatItem(orderedStats[0]['label'], orderedStats[0]['value'], orderedStats[0]['icon']),
              ),
            ),
          ),
        ),
        // Center stat card (large - featured)
        Expanded(
          flex: 1,
          child: Transform.scale(
            scale: 1.1,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: _buildStatItem(orderedStats[1]['label'], orderedStats[1]['value'], orderedStats[1]['icon']),
            ),
          ),
        ),
        // Right stat card (small)
        Expanded(
          flex: 1,
          child: Transform.scale(
            scale: 0.75,
            child: Opacity(
              opacity: 0.6,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: _buildStatItem(orderedStats[2]['label'], orderedStats[2]['value'], orderedStats[2]['icon']),
              ),
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right, size: 28.r),
          onPressed: () => _rotateStats(1),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20.r, color: Theme.of(context).colorScheme.primary),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
              color: Colors.black87,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysMealPlan() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Meals",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'No meals planned for today',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15.w,
        mainAxisSpacing: 15.h,
        childAspectRatio: 1.2,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        return _buildFeatureCard(features[index]);
      },
    );
  }

  Widget _buildFeatureCard(HomeFeature feature) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: feature.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(feature.icon, color: feature.color, size: 22.r),
            ),
            SizedBox(height: 8.h),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    feature.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    feature.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
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

  Widget _buildAISuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Nutrition Track 🥗',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22.sp,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                _navigateToFeature('Nutrition');
              },
              child: Text(
                'View Details',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Text(
          'Track your daily calories and macros',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        SizedBox(height: 15.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              // Daily Calorie Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Calories',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '1,450 / 2,000 kcal',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: LinearProgressIndicator(
                  value: 0.725,
                  minHeight: 10.h,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              ),
              SizedBox(height: 16.h),
              // Macros Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(child: _buildMacroItem('Protein', '65g', '120g', Colors.red)),
                  Expanded(child: _buildMacroItem('Carbs', '180g', '250g', Colors.blue)),
                  Expanded(child: _buildMacroItem('Fat', '45g', '67g', Colors.green)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMacroItem(String label, String current, String target, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.circle,
              color: color,
              size: 16.r,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            '$current / $target',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRecipes() {
    return Consumer<RecipeProvider>(
      builder: (context, recipeProvider, child) {
        if (recipeProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (recipeProvider.recipes.isEmpty) {
          return _buildEmptyRecipesState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Your Recipes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22.sp,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'See All',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 15.h),
            ...recipeProvider.recipes.take(3).map((recipe) => _buildRecipeListItem(recipe)),
          ],
        );
      },
    );
  }

  Widget _buildEmptyRecipesState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Recipes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22.sp,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 15.h),
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(Icons.restaurant_menu,
                  size: 40.r, color: Colors.white.withOpacity(0.5)),
              SizedBox(height: 12.h),
              Text(
                'No recipes yet',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Start by generating your first AI recipe or browsing our collection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              SizedBox(height: 16.h),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to AI generator
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate AI Recipe'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeListItem(dynamic recipe) {
    // Get the recipe properties safely
    final String title = recipe.title ?? 'Untitled Recipe';
    final int totalTime = recipe.cookTimeMinutes ?? recipe.totalTime ?? 30;
    final String difficulty = recipe.difficulty ?? 'Medium';
    final bool isAI = recipe.generatedByAI ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(12.w),
        leading: Container(
          width: 50.w,
          height: 50.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          ),
          child: Icon(Icons.restaurant,
              color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          '$totalTime min • $difficulty',
          style: TextStyle(
              fontSize: 12.sp, color: Colors.white.withOpacity(0.7)),
        ),
        trailing: isAI
            ? Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : Icon(Icons.arrow_forward_ios,
                size: 16.r, color: Colors.white.withOpacity(0.5)),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => RecipeDetailSheet(recipe: recipe),
          );
        },
      ),
    );
  }

  void _navigateToFeature(String featureName) {
    // Implement navigation logic
    print('Navigating to: $featureName');
  }


}

class HomeFeature {
  final String name;
  final IconData icon;
  final String description;
  final Color color;

  HomeFeature({
    required this.name,
    required this.icon,
    required this.description,
    required this.color,
  });
}

class Meal {
  final String type;
  final dynamic recipe; // This would be your Recipe model

  Meal({required this.type, this.recipe});
}