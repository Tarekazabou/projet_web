import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../models/recipe.dart';
import '../utils/mealy_theme.dart';
import '../widgets/recipe_card.dart';

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen>
    with TickerProviderStateMixin {
  AnimationController? animationController;
  final ScrollController scrollController = ScrollController();
  double topBarOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    scrollController.addListener(() {
      if (scrollController.offset >= 24) {
        if (topBarOpacity != 1.0) {
          setState(() => topBarOpacity = 1.0);
        }
      } else if (scrollController.offset <= 24 &&
          scrollController.offset >= 0) {
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

    // Load recipes when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RecipeProvider>(context, listen: false).loadRecipes();
    });
  }

  @override
  void dispose() {
    animationController?.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MealyTheme.background,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            _buildMainContent(),
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
            return Container(
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
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios),
                          color: MealyTheme.darkerText,
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            'All Recipes',
                            style: TextStyle(
                              fontFamily: MealyTheme.fontName,
                              fontWeight: FontWeight.w700,
                              fontSize: 20 + 4 - 4 * topBarOpacity,
                              letterSpacing: 1.2,
                              color: MealyTheme.darkerText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Consumer<RecipeProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    MealyTheme.nearlyGreen,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading recipes...',
                  style: TextStyle(
                    fontFamily: MealyTheme.fontName,
                    fontSize: 16,
                    color: MealyTheme.grey,
                  ),
                ),
              ],
            ),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: MealyTheme.fontName,
                      fontSize: 16,
                      color: MealyTheme.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    provider.loadRecipes();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MealyTheme.nearlyGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (provider.recipes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: MealyTheme.nearlyGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    size: 64,
                    color: MealyTheme.nearlyGreen,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No Recipes Yet',
                  style: TextStyle(
                    fontFamily: MealyTheme.fontName,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: MealyTheme.darkerText,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    'Generate your first recipe using AI or add recipes manually',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: MealyTheme.fontName,
                      fontSize: 16,
                      color: MealyTheme.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to recipe generator
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate Recipe'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MealyTheme.nearlyGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          controller: scrollController,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 80,
            bottom: 24,
          ),
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: MealyTheme.nearlyGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu,
                      color: MealyTheme.nearlyGreen,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'All Recipes',
                          style: TextStyle(
                            fontFamily: MealyTheme.fontName,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: MealyTheme.darkerText,
                          ),
                        ),
                        Text(
                          '${provider.recipes.length} recipes available',
                          style: TextStyle(
                            fontFamily: MealyTheme.fontName,
                            fontSize: 14,
                            color: MealyTheme.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Recipe Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: provider.recipes.length,
                itemBuilder: (context, index) {
                  final recipe = provider.recipes[index];
                  return _buildRecipeCard(recipe);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return GestureDetector(
      onTap: () {
        _showRecipeDetails(recipe);
      },
      child: Container(
        decoration: BoxDecoration(
          color: MealyTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: MealyTheme.grey.withOpacity(0.2),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image Placeholder
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    MealyTheme.nearlyGreen,
                    MealyTheme.nearlyGreen.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.restaurant,
                  size: 48,
                  color: MealyTheme.white.withOpacity(0.8),
                ),
              ),
            ),

            // Recipe Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: MealyTheme.fontName,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: MealyTheme.darkerText,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 14,
                          color: MealyTheme.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recipe.formattedTotalTime,
                          style: TextStyle(
                            fontFamily: MealyTheme.fontName,
                            fontSize: 11,
                            color: MealyTheme.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: MealyTheme.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.servingSize} servings',
                          style: TextStyle(
                            fontFamily: MealyTheme.fontName,
                            fontSize: 11,
                            color: MealyTheme.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecipeDetails(Recipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: MealyTheme.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: MealyTheme.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Recipe Header
              Text(
                recipe.title,
                style: const TextStyle(
                  fontFamily: MealyTheme.fontName,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: MealyTheme.darkerText,
                ),
              ),
              const SizedBox(height: 8),
              if (recipe.description != null)
                Text(
                  recipe.description!,
                  style: TextStyle(
                    fontFamily: MealyTheme.fontName,
                    fontSize: 14,
                    color: MealyTheme.grey,
                  ),
                ),
              const SizedBox(height: 16),

              // Recipe Stats
              Row(
                children: [
                  _buildStatChip(Icons.timer, recipe.formattedTotalTime),
                  const SizedBox(width: 8),
                  _buildStatChip(Icons.people, '${recipe.servingSize} servings'),
                  const SizedBox(width: 8),
                  _buildStatChip(Icons.restaurant, recipe.difficulty),
                ],
              ),
              const SizedBox(height: 24),

              // Ingredients
              const Text(
                'Ingredients',
                style: TextStyle(
                  fontFamily: MealyTheme.fontName,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: MealyTheme.darkerText,
                ),
              ),
              const SizedBox(height: 12),
              ...recipe.ingredients.map((ingredient) {
                final ingredientText = ingredient is String
                    ? ingredient
                    : ingredient['name'] ?? ingredient.toString();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: MealyTheme.nearlyGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ingredientText,
                          style: const TextStyle(
                            fontFamily: MealyTheme.fontName,
                            fontSize: 14,
                            color: MealyTheme.darkerText,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Instructions
              const Text(
                'Instructions',
                style: TextStyle(
                  fontFamily: MealyTheme.fontName,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: MealyTheme.darkerText,
                ),
              ),
              const SizedBox(height: 12),
              ...recipe.instructions.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: MealyTheme.nearlyGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              fontFamily: MealyTheme.fontName,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: MealyTheme.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            fontFamily: MealyTheme.fontName,
                            fontSize: 14,
                            color: MealyTheme.darkerText,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: MealyTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: MealyTheme.nearlyGreen),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: MealyTheme.fontName,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: MealyTheme.darkerText,
            ),
          ),
        ],
      ),
    );
  }
}
