import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../providers/fridge_provider.dart';
import '../services/api_service.dart';
import '../utils/mealy_theme.dart';

class CookFromFridgeScreen extends StatefulWidget {
  const CookFromFridgeScreen({super.key});

  @override
  State<CookFromFridgeScreen> createState() => _CookFromFridgeScreenState();
}

class _CookFromFridgeScreenState extends State<CookFromFridgeScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  
  AnimationController? _animationController;
  Animation<double>? _topBarAnimation;
  double _topBarOpacity = 0.0;
  
  bool _isLoading = false;
  bool _isGenerating = false;
  Recipe? _generatedRecipe;
  String? _error;
  
  // Optional filters
  String _difficulty = 'medium';
  int _servings = 4;
  int _maxCookingTime = 60;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _topBarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: const Interval(0, 0.5, curve: Curves.fastOutSlowIn),
      ),
    );

    _scrollController.addListener(_handleScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final fridgeProvider = context.read<FridgeProvider>();
      await fridgeProvider.loadFridgeItems();
      _animationController?.forward();
    });
  }

  void _handleScroll() {
    if (_scrollController.offset >= 24) {
      if (_topBarOpacity != 1.0) {
        setState(() => _topBarOpacity = 1.0);
      }
    } else if (_scrollController.offset <= 24 && _scrollController.offset >= 0) {
      if (_topBarOpacity != _scrollController.offset / 24) {
        setState(() => _topBarOpacity = _scrollController.offset / 24);
      }
    } else if (_scrollController.offset <= 0) {
      if (_topBarOpacity != 0.0) {
        setState(() => _topBarOpacity = 0.0);
      }
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _generateRecipe() async {
    final fridgeProvider = context.read<FridgeProvider>();
    
    if (fridgeProvider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your fridge is empty! Add some ingredients first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _error = null;
      _generatedRecipe = null;
    });

    try {
      final response = await _apiService.suggestRecipesFromFridge(
        difficulty: _difficulty,
        servings: _servings,
        maxCookingTime: _maxCookingTime,
      );
      
      final recipeData = response['recipe'] ?? response;
      
      setState(() {
        _generatedRecipe = Recipe.fromJson(recipeData);
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isGenerating = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate recipe: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cookRecipe() async {
    if (_generatedRecipe == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cook this recipe?'),
        content: const Text(
          'This will remove the used ingredients from your fridge. Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: MealyTheme.nearlyGreen,
            ),
            child: const Text('Yes, Cook it!'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      // Prepare ingredients list for consumption
      final ingredientsToConsume = _generatedRecipe!.ingredients.map((ing) {
        if (ing is Map) {
          return {
            'name': ing['name'] ?? ing['ingredient'] ?? ing.toString(),
            'quantity': ing['quantity'] ?? 1,
            'unit': ing['unit'] ?? 'pieces',
          };
        } else if (ing is String) {
          return {'name': ing, 'quantity': 1, 'unit': 'pieces'};
        }
        return {'name': ing.toString(), 'quantity': 1, 'unit': 'pieces'};
      }).toList();

      await _apiService.consumeFridgeIngredients(
        ingredientsToConsume.cast<Map<String, dynamic>>(),
      );
      
      // Refresh fridge items
      if (mounted) {
        await context.read<FridgeProvider>().loadFridgeItems();
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🍳 Enjoy your ${_generatedRecipe!.title}! Ingredients removed from fridge.'),
            backgroundColor: MealyTheme.nearlyGreen,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Show recipe details dialog
        _showRecipeDetailsDialog();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRecipeDetailsDialog() {
    if (_generatedRecipe == null) return;
    
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
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Recipe title
              Text(
                _generatedRecipe!.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Quick info row
              Row(
                children: [
                  _buildInfoChip(Icons.timer, _generatedRecipe!.formattedTotalTime),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.restaurant, '${_generatedRecipe!.servingSize} servings'),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.bar_chart, _generatedRecipe!.difficultyDisplay),
                ],
              ),
              const SizedBox(height: 16),
              
              // Description
              if (_generatedRecipe!.description != null) ...[
                Text(
                  _generatedRecipe!.description!,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Ingredients section
              const Text(
                'Ingredients',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ..._generatedRecipe!.ingredients.map((ing) {
                String text;
                if (ing is Map) {
                  final name = ing['name'] ?? ing['ingredient'] ?? '';
                  final qty = ing['quantity'] ?? '';
                  final unit = ing['unit'] ?? '';
                  text = '$qty $unit $name'.trim();
                } else {
                  text = ing.toString();
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, 
                        color: MealyTheme.nearlyGreen, 
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
              
              // Instructions section
              const Text(
                'Instructions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(_generatedRecipe!.instructions.length, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: MealyTheme.nearlyGreen,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _generatedRecipe!.instructions[index],
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
              
              // Nutrition info
              if (_generatedRecipe!.nutrition != null) ...[
                const Text(
                  'Nutrition (per serving)',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildNutritionGrid(),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: MealyTheme.nearlyGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: MealyTheme.nearlyGreen),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: MealyTheme.nearlyGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionGrid() {
    final nutrition = _generatedRecipe!.nutrition!;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (nutrition['calories'] != null)
          _buildNutritionItem('Calories', '${nutrition['calories']}', 'kcal'),
        if (nutrition['protein'] != null)
          _buildNutritionItem('Protein', '${nutrition['protein']}', 'g'),
        if (nutrition['carbs'] != null || nutrition['carbohydrates'] != null)
          _buildNutritionItem('Carbs', '${nutrition['carbs'] ?? nutrition['carbohydrates']}', 'g'),
        if (nutrition['fat'] != null)
          _buildNutritionItem('Fat', '${nutrition['fat']}', 'g'),
        if (nutrition['fiber'] != null)
          _buildNutritionItem('Fiber', '${nutrition['fiber']}', 'g'),
      ],
    );
  }

  Widget _buildNutritionItem(String label, String value, String unit) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: MealyTheme.nearlyGreen,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
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
          animation: _animationController!,
          builder: (context, child) {
            return FadeTransition(
              opacity: _topBarAnimation!,
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - _topBarAnimation!.value)),
                child: Container(
                  decoration: BoxDecoration(
                    color: MealyTheme.white.withOpacity(_topBarOpacity),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: MealyTheme.grey.withOpacity(0.4 * _topBarOpacity),
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
                          top: 16 - 8.0 * _topBarOpacity,
                          bottom: 12 - 8.0 * _topBarOpacity,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Text(
                                'Cook from Fridge',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22 + 6 - 6 * _topBarOpacity,
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
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Consumer<FridgeProvider>(
      builder: (context, fridgeProvider, child) {
        return ListView(
          controller: _scrollController,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 80,
            left: 16,
            right: 16,
            bottom: 100,
          ),
          children: [
            // Fridge summary card
            _buildFridgeSummaryCard(fridgeProvider),
            const SizedBox(height: 20),
            
            // Filters section
            _buildFiltersSection(),
            const SizedBox(height: 20),
            
            // Generate button
            _buildGenerateButton(fridgeProvider),
            const SizedBox(height: 24),
            
            // Generated recipe card
            if (_isGenerating) _buildLoadingCard(),
            if (_error != null) _buildErrorCard(),
            if (_generatedRecipe != null && !_isGenerating) _buildRecipeCard(),
          ],
        );
      },
    );
  }

  Widget _buildFridgeSummaryCard(FridgeProvider fridgeProvider) {
    final items = fridgeProvider.items;
    final expiringSoon = items.where((i) => i.isExpiringSoon).length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [MealyTheme.nearlyGreen, MealyTheme.nearlyGreen.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: MealyTheme.nearlyGreen.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.kitchen,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Fridge',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${items.length} ingredients available',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.take(6).map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
            if (items.length > 6)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+${items.length - 6} more ingredients',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ),
          ],
          if (expiringSoon > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '$expiringSoon item${expiringSoon > 1 ? 's' : ''} expiring soon!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recipe Preferences',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Difficulty selector
          Row(
            children: [
              const Icon(Icons.bar_chart, color: MealyTheme.nearlyGreen),
              const SizedBox(width: 12),
              const Text('Difficulty:'),
              const Spacer(),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'easy', label: Text('Easy')),
                  ButtonSegment(value: 'medium', label: Text('Medium')),
                  ButtonSegment(value: 'hard', label: Text('Hard')),
                ],
                selected: {_difficulty},
                onSelectionChanged: (selected) {
                  setState(() => _difficulty = selected.first);
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Servings slider
          Row(
            children: [
              const Icon(Icons.people, color: MealyTheme.nearlyGreen),
              const SizedBox(width: 12),
              Text('Servings: $_servings'),
            ],
          ),
          Slider(
            value: _servings.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: MealyTheme.nearlyGreen,
            onChanged: (value) {
              setState(() => _servings = value.toInt());
            },
          ),
          
          // Max cooking time slider
          Row(
            children: [
              const Icon(Icons.timer, color: MealyTheme.nearlyGreen),
              const SizedBox(width: 12),
              Text('Max time: $_maxCookingTime min'),
            ],
          ),
          Slider(
            value: _maxCookingTime.toDouble(),
            min: 15,
            max: 120,
            divisions: 7,
            activeColor: MealyTheme.nearlyGreen,
            onChanged: (value) {
              setState(() => _maxCookingTime = value.toInt());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton(FridgeProvider fridgeProvider) {
    final hasItems = fridgeProvider.items.isNotEmpty;
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: hasItems && !_isGenerating ? _generateRecipe : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: MealyTheme.nearlyGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: _isGenerating
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Generating Recipe...', style: TextStyle(fontSize: 18)),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    hasItems ? 'Generate Recipe from Fridge' : 'Add ingredients first',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: MealyTheme.nearlyGreen),
          const SizedBox(height: 20),
          const Text(
            '🍳 Creating your recipe...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Using ingredients from your fridge',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 48),
          const SizedBox(height: 12),
          Text(
            'Failed to generate recipe',
            style: TextStyle(
              color: Colors.red[700],
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: TextStyle(color: Colors.red[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _generateRecipe,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recipe header with gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  MealyTheme.nearlyGreen.withOpacity(0.1),
                  MealyTheme.nearlyGreen.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: MealyTheme.nearlyGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'AI Generated',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (_generatedRecipe!.basedOnFridge == true)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.kitchen, color: Colors.orange, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'From Fridge',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _generatedRecipe!.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_generatedRecipe!.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _generatedRecipe!.description!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          
          // Quick info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickInfo(Icons.timer, _generatedRecipe!.formattedTotalTime, 'Time'),
                    _buildQuickInfo(Icons.restaurant, '${_generatedRecipe!.servingSize}', 'Servings'),
                    _buildQuickInfo(Icons.bar_chart, _generatedRecipe!.difficultyDisplay, 'Difficulty'),
                    if (_generatedRecipe!.calories != null)
                      _buildQuickInfo(Icons.local_fire_department, '${_generatedRecipe!.calories}', 'Calories'),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Ingredients preview
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ingredients',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_generatedRecipe!.ingredients.length} ingredients needed',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showRecipeDetailsDialog,
                        icon: const Icon(Icons.visibility),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: MealyTheme.nearlyGreen),
                          foregroundColor: MealyTheme.nearlyGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _cookRecipe,
                        icon: _isLoading 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.restaurant_menu),
                        label: Text(_isLoading ? 'Cooking...' : 'Cook This!'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: MealyTheme.nearlyGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfo(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: MealyTheme.nearlyGreen, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
