import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              if (provider.generatedRecipe != null) ...[
                const SizedBox(height: 24),
                _buildResultSection(provider),
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
                          borderSide: BorderSide(color: MealyTheme.grey.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: MealyTheme.grey.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: MealyTheme.nearlyOrange, width: 2),
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
                          borderSide: BorderSide(color: MealyTheme.grey.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: MealyTheme.nearlyOrange, width: 2),
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
                          borderSide: BorderSide(color: MealyTheme.grey.withOpacity(0.3)),
                        ),
                        filled: true,
                        fillColor: MealyTheme.background,
                      ),
                      items: ['Facile', 'Moyen', 'Difficile']
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (value) => setState(() => _difficulty = value!),
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
                          selectedColor: MealyTheme.nearlyGreen.withOpacity(0.2),
                          checkmarkColor: MealyTheme.nearlyGreen,
                          labelStyle: TextStyle(
                            fontFamily: MealyTheme.fontName,
                            fontSize: 13,
                            color: isSelected ? MealyTheme.nearlyGreen : MealyTheme.grey,
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
                        const Icon(Icons.auto_awesome, color: MealyTheme.white, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        provider.isLoading ? 'Génération en cours...' : 'Générer une Recette',
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

  Widget _buildResultSection(RecipeProvider provider) {
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
                child: const Icon(Icons.restaurant, color: MealyTheme.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recette Générée',
                style: TextStyle(
                  fontFamily: MealyTheme.fontName,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: MealyTheme.darkerText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: RecipeCard(recipe: provider.generatedRecipe!),
        ),
      ],
    );
  }
}
