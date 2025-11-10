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
      backgroundColor: Colors.white,
      body: SafeArea(
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
                SizedBox(height: 25.h),
                
                // Quick Actions Grid
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22.sp,
                    color: Colors.black87,
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
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          "What's cooking today?",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24.sp,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 15.h),
        
        // Quick Stats Row
        Row(
          children: [
            _buildStatItem('Recipes', '12', Icons.restaurant_menu),
            SizedBox(width: 15.w),
            _buildStatItem('Meals Planned', '7', Icons.calendar_today),
            SizedBox(width: 15.w),
            _buildStatItem('Ingredients', '24', Icons.kitchen),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15.r),
        onTap: () {
          // Navigate to respective feature
          _navigateToFeature(feature.name);
        },
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.r),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                feature.color.withOpacity(0.1),
                feature.color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: feature.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(feature.icon, color: feature.color, size: 24.r),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    feature.description,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaysMealPlan() {
    // Temporary: Empty meals list until MealPlanProvider is implemented
    final todayMeals = <Meal>[];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Today's Meals",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22.sp,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // Navigate to meal planner
              },
              child: Text(
                'View Plan',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 15.h),
        
        if (todayMeals.isEmpty)
          _buildEmptyMealPlanState()
        else
          Column(
            children: todayMeals.map((meal) => _buildMealPlanItem(meal)).toList(),
          ),
      ],
    );
  }

  Widget _buildEmptyMealPlanState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.calendar_today, size: 40.r, color: Colors.grey[400]),
          SizedBox(height: 12.h),
          Text(
            'No meals planned for today',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Plan your meals to get started with grocery lists and nutrition tracking',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () {
              // Navigate to meal planner
            },
            child: const Text('Plan Meals'),
          ),
        ],
      ),
    );
  }

  Widget _buildMealPlanItem(Meal meal) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: _getMealTypeColor(meal.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              _getMealTypeIcon(meal.type),
              color: _getMealTypeColor(meal.type),
              size: 20.r,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.type,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  meal.recipe?.title ?? 'Not planned yet',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (meal.recipe != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '${meal.recipe!.totalTime}min',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
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
              'AI Suggestions 🤖',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22.sp,
                color: Colors.black87,
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                'NEW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Text(
          'Personalized recipes based on your preferences and available ingredients',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 15.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(color: Colors.purple[100]!),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.purple, size: 24.r),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Generate AI Recipe',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Create a custom recipe with ingredients you have',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.purple, size: 16.r),
            ],
          ),
        ),
      ],
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
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'See All',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
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
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 15.h),
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              Icon(Icons.restaurant_menu, size: 40.r, color: Colors.grey[400]),
              SizedBox(height: 12.h),
              Text(
                'No recipes yet',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Start by generating your first AI recipe or browsing our collection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(12.w),
        leading: Container(
          width: 50.w,
          height: 50.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ),
          child: Icon(Icons.restaurant, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
          ),
        ),
        subtitle: Text(
          '$totalTime min • $difficulty',
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
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
            : Icon(Icons.arrow_forward_ios, size: 16.r, color: Colors.grey[400]),
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

  Color _getMealTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast': return Colors.orange;
      case 'lunch': return Colors.green;
      case 'dinner': return Colors.blue;
      case 'snack': return Colors.purple;
      default: return Colors.grey;
    }
  }

  IconData _getMealTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast': return Icons.breakfast_dining;
      case 'lunch': return Icons.lunch_dining;
      case 'dinner': return Icons.dinner_dining;
      case 'snack': return Icons.cookie;
      default: return Icons.restaurant;
    }
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