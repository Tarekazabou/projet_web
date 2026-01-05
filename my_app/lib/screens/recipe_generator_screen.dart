import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/fridge_provider.dart';
import '../models/recipe.dart';
import '../services/api_service.dart';
import '../utils/mealy_theme.dart';
import '../widgets/recipe_card.dart';

class RecipeGeneratorScreen extends StatefulWidget {
  const RecipeGeneratorScreen({super.key});

  @override
  State<RecipeGeneratorScreen> createState() => _RecipeGeneratorScreenState();
}

class _RecipeGeneratorScreenState extends State<RecipeGeneratorScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _ingredientsController = TextEditingController();
  final _cuisineController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  AnimationController? animationController;
  Animation<double>? topBarAnimation;
  double topBarOpacity = 0.0;

  String _difficulty = 'Facile';
  int _servings = 4;
  int _maxTime = 60;
  final List<String> _dietaryPrefs = [];

  final List<String> _availableDietaryPrefs = [
    'Végétarien',
    'Végétalien',
    'Sans Gluten',
    'Sans Lactose',
    'Pauvre en Glucides',
    'Keto',
    'Paleo',
    'Halal',
    'Casher',
  ];

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
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
  }

  @override
  void dispose() {
    animationController?.dispose();
    _ingredientsController.dispose();
    _cuisineController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _generateRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    final ingredients = _ingredientsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez entrer au moins un ingrédient'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    await Provider.of<RecipeProvider>(context, listen: false).generateRecipe(
      ingredients: ingredients,
      cuisine: _cuisineController.text.isEmpty ? null : _cuisineController.text,
      difficulty: _difficulty,
      servings: _servings,
      maxTime: _maxTime,
      dietaryPreferences: _dietaryPrefs,
    );

    if (mounted) {
      final provider = Provider.of<RecipeProvider>(context, listen: false);
      if (provider.error == null && provider.generatedRecipe != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Recette générée avec succès !'),
            backgroundColor: MealyTheme.nearlyGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MealyTheme.background,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(children: [_buildMainContent(), _buildTopBar()]),
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
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios),
                              color: MealyTheme.darkerText,
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Text(
                                'Recipe Generator',
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
                ),
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
        return Form(
          key: _formKey,
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 80,
              bottom: 100,
            ),
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 16),
              _buildIngredientsCard(),
              const SizedBox(height: 16),
              _buildPreferencesCard(),
              const SizedBox(height: 16),
              _buildDietaryPrefsCard(),
              const SizedBox(height: 24),
              _buildGenerateButton(provider),
              if (provider.error != null) ...[
                const SizedBox(height: 16),
                _buildErrorCard(provider.error!),
              ],
              if (provider.generatedRecipes.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildRecipeChoicesSection(provider),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard() {
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
                      MealyTheme.nearlyGreen,
                      MealyTheme.nearlyGreen.withOpacity(0.8),
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
                      color: MealyTheme.nearlyGreen.withOpacity(0.4),
                      offset: const Offset(1.1, 4.0),
                      blurRadius: 8.0,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: MealyTheme.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: MealyTheme.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AI Recipe Generator',
                              style: TextStyle(
                                fontFamily: MealyTheme.fontName,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: MealyTheme.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create amazing recipes from your ingredients',
                              style: TextStyle(
                                fontFamily: MealyTheme.fontName,
                                fontSize: 13,
                                color: MealyTheme.white.withOpacity(0.9),
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

  Widget _buildIngredientsCard() {
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
              child: Container(
                padding: const EdgeInsets.all(20),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: MealyTheme.nearlyOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.kitchen,
                            color: MealyTheme.nearlyOrange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Ingrédients',
                          style: TextStyle(
                            fontFamily: MealyTheme.fontName,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: MealyTheme.darkerText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ingredientsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'poulet, riz, tomates...',
                        helperText: 'Séparer par des virgules',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: MealyTheme.grey.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: MealyTheme.grey.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: MealyTheme.nearlyOrange,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: MealyTheme.background,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez entrer les ingrédients';
                        }
                        return null;
                      },
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
                padding: const EdgeInsets.all(20),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF738AE6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.tune,
                            color: Color(0xFF738AE6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Préférences',
                          style: TextStyle(
                            fontFamily: MealyTheme.fontName,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: MealyTheme.darkerText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _cuisineController,
                      decoration: InputDecoration(
                        labelText: 'Type de cuisine (optionnel)',
                        hintText: 'Français, Italien, Asiatique...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: MealyTheme.grey.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: MealyTheme.nearlyOrange,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: MealyTheme.background,
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _difficulty,
                      decoration: InputDecoration(
                        labelText: 'Difficulté',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: MealyTheme.grey.withOpacity(0.3),
                          ),
                        ),
                        filled: true,
                        fillColor: MealyTheme.background,
                      ),
                      items: ['Facile', 'Moyen', 'Difficile']
                          .map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _difficulty = value!),
                    ),
                    const SizedBox(height: 20),
                    _buildSliderSection(
                      'Portions',
                      '$_servings pers',
                      _servings.toDouble(),
                      1,
                      12,
                      11,
                      (value) => setState(() => _servings = value.toInt()),
                    ),
                    const SizedBox(height: 16),
                    _buildSliderSection(
                      'Temps max',
                      '$_maxTime min',
                      _maxTime.toDouble(),
                      15,
                      180,
                      11,
                      (value) => setState(() => _maxTime = value.toInt()),
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

  Widget _buildSliderSection(
    String label,
    String value,
    double sliderValue,
    double min,
    double max,
    int divisions,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: MealyTheme.fontName,
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: MealyTheme.darkerText,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: MealyTheme.nearlyOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontFamily: MealyTheme.fontName,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: MealyTheme.nearlyOrange,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: MealyTheme.nearlyOrange,
            inactiveTrackColor: MealyTheme.nearlyOrange.withOpacity(0.2),
            thumbColor: MealyTheme.nearlyOrange,
            overlayColor: MealyTheme.nearlyOrange.withOpacity(0.1),
          ),
          child: Slider(
            value: sliderValue,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDietaryPrefsCard() {
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
                padding: const EdgeInsets.all(20),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: MealyTheme.nearlyGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.eco,
                            color: MealyTheme.nearlyGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Préférences Alimentaires',
                          style: TextStyle(
                            fontFamily: MealyTheme.fontName,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: MealyTheme.darkerText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableDietaryPrefs.map((pref) {
                        final isSelected = _dietaryPrefs.contains(pref);
                        return FilterChip(
                          label: Text(pref),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _dietaryPrefs.add(pref);
                              } else {
                                _dietaryPrefs.remove(pref);
                              }
                            });
                          },
                          backgroundColor: MealyTheme.background,
                          selectedColor: MealyTheme.nearlyGreen.withOpacity(
                            0.2,
                          ),
                          checkmarkColor: MealyTheme.nearlyGreen,
                          labelStyle: TextStyle(
                            fontFamily: MealyTheme.fontName,
                            fontSize: 13,
                            color: isSelected
                                ? MealyTheme.nearlyGreen
                                : MealyTheme.grey,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? MealyTheme.nearlyGreen
                                  : MealyTheme.grey.withOpacity(0.3),
                            ),
                          ),
                        );
                      }).toList(),
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

  Widget _buildGenerateButton(RecipeProvider provider) {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (context, child) {
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animationController!,
            curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
          ),
        );
        return ScaleTransition(
          scale: animation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    MealyTheme.nearlyOrange,
                    MealyTheme.nearlyOrange.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: MealyTheme.nearlyOrange.withOpacity(0.4),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: provider.isLoading ? null : _generateRecipe,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (provider.isLoading)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: MealyTheme.white,
                          ),
                        )
                      else
                        const Icon(
                          Icons.auto_awesome,
                          color: MealyTheme.white,
                          size: 24,
                        ),
                      const SizedBox(width: 12),
                      Text(
                        provider.isLoading
                            ? 'Génération en cours...'
                            : 'Générer une Recette',
                        style: const TextStyle(
                          fontFamily: MealyTheme.fontName,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: MealyTheme.white,
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

  Widget _buildErrorCard(String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error,
                style: TextStyle(
                  fontFamily: MealyTheme.fontName,
                  color: Colors.red.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeChoicesSection(RecipeProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      MealyTheme.nearlyOrange,
                      MealyTheme.nearlyOrange.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  color: MealyTheme.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choisissez une Recette',
                      style: TextStyle(
                        fontFamily: MealyTheme.fontName,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: MealyTheme.darkerText,
                      ),
                    ),
                    Text(
                      'Sélectionnez votre recette préférée',
                      style: TextStyle(
                        fontFamily: MealyTheme.fontName,
                        fontSize: 12,
                        color: MealyTheme.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...provider.generatedRecipes.asMap().entries.map((entry) {
          final index = entry.key;
          final recipe = entry.value;
          final isSelected = provider.selectedRecipe == recipe;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildRecipeChoiceCard(recipe, index, isSelected, provider),
          );
        }),
      ],
    );
  }

  Widget _buildRecipeChoiceCard(
    Recipe recipe,
    int index,
    bool isSelected,
    RecipeProvider provider,
  ) {
    final variationLabels = ['Classique', 'Rapide', 'Gourmet'];
    final variationColors = [
      const Color(0xFF738AE6),
      MealyTheme.nearlyOrange,
      const Color(0xFF6F72CA),
    ];

    return GestureDetector(
      onTap: () => _selectRecipe(recipe, provider),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: MealyTheme.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? MealyTheme.nearlyGreen : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? MealyTheme.nearlyGreen.withOpacity(0.3)
                  : MealyTheme.grey.withOpacity(0.15),
              offset: const Offset(0, 4),
              blurRadius: isSelected ? 16 : 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with variation label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    variationColors[index % variationColors.length],
                    variationColors[index % variationColors.length].withOpacity(
                      0.7,
                    ),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(17),
                  topRight: Radius.circular(17),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: MealyTheme.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Option ${index + 1} - ${variationLabels[index % variationLabels.length]}',
                      style: const TextStyle(
                        fontFamily: MealyTheme.fontName,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: MealyTheme.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: MealyTheme.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: MealyTheme.nearlyGreen,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
            // Recipe content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontFamily: MealyTheme.fontName,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: MealyTheme.darkerText,
                    ),
                  ),
                  if (recipe.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      recipe.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: MealyTheme.fontName,
                        fontSize: 13,
                        color: MealyTheme.grey,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Stats row
                  Row(
                    children: [
                      _buildStatChip(Icons.timer, recipe.formattedTotalTime),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        Icons.people,
                        '${recipe.servingSize} pers',
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(Icons.restaurant, recipe.difficulty),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Ingredients preview
                  Text(
                    '${recipe.ingredients.length} ingrédients',
                    style: TextStyle(
                      fontFamily: MealyTheme.fontName,
                      fontSize: 12,
                      color: MealyTheme.grey,
                    ),
                  ),
                ],
              ),
            ),
            // Select button
            if (isSelected)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () => _confirmRecipeSelection(recipe),
                  icon: const Icon(Icons.check_circle, color: MealyTheme.white),
                  label: const Text(
                    'Utiliser cette Recette',
                    style: TextStyle(
                      fontFamily: MealyTheme.fontName,
                      fontWeight: FontWeight.bold,
                      color: MealyTheme.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MealyTheme.nearlyGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: MealyTheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: MealyTheme.nearlyOrange),
          const SizedBox(width: 4),
          Text(
            value,
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

  void _selectRecipe(Recipe recipe, RecipeProvider provider) {
    provider.selectRecipe(recipe);
  }

  Future<void> _confirmRecipeSelection(Recipe recipe) async {
    // Show confirmation dialog with ingredient check
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildIngredientCheckSheet(recipe),
    );
  }

  Widget _buildIngredientCheckSheet(Recipe recipe) {
    return Consumer<FridgeProvider>(
      builder: (context, fridgeProvider, child) {
        final fridgeItems = fridgeProvider.items;
        final recipeIngredients = recipe.ingredients;

        // Check which ingredients are available
        List<Map<String, dynamic>> ingredientStatus = [];
        List<Map<String, dynamic>> missingIngredients = [];

        for (var ingredient in recipeIngredients) {
          String ingredientName = '';
          String quantity = '';
          String unit = '';

          if (ingredient is String) {
            ingredientName = ingredient.toLowerCase();
          } else if (ingredient is Map) {
            ingredientName =
                (ingredient['name'] ?? ingredient['ingredientName'] ?? '')
                    .toString()
                    .toLowerCase();
            quantity = (ingredient['quantity'] ?? '1').toString();
            unit = (ingredient['unit'] ?? 'pcs').toString();
          }

          // Check if ingredient exists in fridge
          final fridgeItem = fridgeItems
              .where(
                (item) =>
                    item.name.toLowerCase().contains(ingredientName) ||
                    ingredientName.contains(item.name.toLowerCase()),
              )
              .firstOrNull;

          final isAvailable = fridgeItem != null;

          ingredientStatus.add({
            'name': ingredientName,
            'quantity': quantity,
            'unit': unit,
            'available': isAvailable,
            'fridgeItem': fridgeItem,
          });

          if (!isAvailable) {
            missingIngredients.add({
              'name': ingredientName,
              'quantity': quantity,
              'unit': unit,
            });
          }
        }

        final availableCount = ingredientStatus
            .where((i) => i['available'] == true)
            .length;
        final totalCount = ingredientStatus.length;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: MealyTheme.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: MealyTheme.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      recipe.title,
                      style: const TextStyle(
                        fontFamily: MealyTheme.fontName,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: MealyTheme.darkerText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // Status summary
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: availableCount == totalCount
                            ? MealyTheme.nearlyGreen.withOpacity(0.1)
                            : MealyTheme.nearlyOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            availableCount == totalCount
                                ? Icons.check_circle
                                : Icons.warning_amber,
                            color: availableCount == totalCount
                                ? MealyTheme.nearlyGreen
                                : MealyTheme.nearlyOrange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            availableCount == totalCount
                                ? 'Tous les ingrédients disponibles!'
                                : '$availableCount/$totalCount ingrédients disponibles',
                            style: TextStyle(
                              fontFamily: MealyTheme.fontName,
                              fontWeight: FontWeight.w600,
                              color: availableCount == totalCount
                                  ? MealyTheme.nearlyGreen
                                  : MealyTheme.nearlyOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Ingredients list
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  itemCount: ingredientStatus.length,
                  itemBuilder: (context, index) {
                    final item = ingredientStatus[index];
                    final isAvailable = item['available'] as bool;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? MealyTheme.nearlyGreen.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isAvailable ? Icons.check : Icons.close,
                              size: 16,
                              color: isAvailable
                                  ? MealyTheme.nearlyGreen
                                  : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item['name'].toString().isNotEmpty
                                  ? '${item['name'][0].toUpperCase()}${item['name'].substring(1)}'
                                  : 'Ingrédient',
                              style: TextStyle(
                                fontFamily: MealyTheme.fontName,
                                fontSize: 15,
                                color: MealyTheme.darkerText,
                                decoration: isAvailable
                                    ? null
                                    : TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                          if (item['quantity'].toString().isNotEmpty)
                            Text(
                              '${item['quantity']} ${item['unit']}',
                              style: TextStyle(
                                fontFamily: MealyTheme.fontName,
                                fontSize: 13,
                                color: MealyTheme.grey,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Action buttons
              Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                  top: 12,
                ),
                child: Column(
                  children: [
                    if (missingIngredients.isNotEmpty) ...[
                      // Add to grocery list button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _addToGroceryList(missingIngredients),
                          icon: const Icon(Icons.shopping_cart),
                          label: Text(
                            'Ajouter ${missingIngredients.length} ingrédient(s) à la liste',
                            style: const TextStyle(
                              fontFamily: MealyTheme.fontName,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MealyTheme.nearlyOrange,
                            side: const BorderSide(
                              color: MealyTheme.nearlyOrange,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Confirm and use recipe button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _useRecipe(recipe, ingredientStatus),
                        icon: const Icon(
                          Icons.restaurant,
                          color: MealyTheme.white,
                        ),
                        label: Text(
                          availableCount == totalCount
                              ? 'Préparer cette Recette'
                              : 'Préparer avec ingrédients disponibles',
                          style: const TextStyle(
                            fontFamily: MealyTheme.fontName,
                            fontWeight: FontWeight.bold,
                            color: MealyTheme.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MealyTheme.nearlyGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
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
    );
  }

  Future<void> _addToGroceryList(
    List<Map<String, dynamic>> missingIngredients,
  ) async {
    try {
      final api = ApiService();

      for (var ingredient in missingIngredients) {
        await api.addGroceryItem({
          'name': ingredient['name'],
          'quantity': ingredient['quantity'] ?? '1',
          'unit': ingredient['unit'] ?? 'pcs',
          'category': 'Other',
        });
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${missingIngredients.length} ingrédient(s) ajouté(s) à la liste de courses!',
            ),
            backgroundColor: MealyTheme.nearlyGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _useRecipe(
    Recipe recipe,
    List<Map<String, dynamic>> ingredientStatus,
  ) async {
    try {
      final fridgeProvider = context.read<FridgeProvider>();

      // Remove available ingredients from fridge
      for (var item in ingredientStatus) {
        if (item['available'] == true && item['fridgeItem'] != null) {
          final fridgeItem = item['fridgeItem'];
          // For simplicity, we remove the item - you could also reduce quantity
          await fridgeProvider.removeItem(fridgeItem.id);
        }
      }

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context); // Go back to previous screen

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Bon appétit! Les ingrédients ont été retirés du frigo.',
            ),
            backgroundColor: MealyTheme.nearlyGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
