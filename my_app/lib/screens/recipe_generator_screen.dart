import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipe_provider.dart';
import '../widgets/recipe_card.dart';

class RecipeGeneratorScreen extends StatefulWidget {
  const RecipeGeneratorScreen({super.key});

  @override
  State<RecipeGeneratorScreen> createState() => _RecipeGeneratorScreenState();
}

class _RecipeGeneratorScreenState extends State<RecipeGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ingredientsController = TextEditingController();
  final _cuisineController = TextEditingController();
  
  String _difficulty = 'Easy';
  int _servings = 4;
  int _maxTime = 60;
  List<String> _dietaryPrefs = [];

  final List<String> _availableDietaryPrefs = [
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Dairy-Free',
    'Low-Carb',
    'Keto',
    'Paleo',
    'Halal',
    'Kosher',
  ];

  @override
  void dispose() {
    _ingredientsController.dispose();
    _cuisineController.dispose();
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
        const SnackBar(content: Text('Please enter at least one ingredient')),
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
          const SnackBar(content: Text('Recipe generated successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Generator'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      extendBodyBehindAppBar: true,
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
          child: Consumer<RecipeProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ingredients',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _ingredientsController,
                            decoration: const InputDecoration(
                              hintText: 'chicken, rice, tomatoes...',
                              helperText: 'Separate with commas',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter ingredients';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Preferences',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _cuisineController,
                            decoration: const InputDecoration(
                              labelText: 'Cuisine (optional)',
                              hintText: 'Italian, Mexican, Asian...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _difficulty,
                            decoration: const InputDecoration(
                              labelText: 'Difficulty',
                              border: OutlineInputBorder(),
                            ),
                            items: ['Easy', 'Medium', 'Hard']
                                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                                .toList(),
                            onChanged: (value) => setState(() => _difficulty = value!),
                          ),
                          const SizedBox(height: 16),
                          Text('Servings: $_servings', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Slider(
                            value: _servings.toDouble(),
                            min: 1,
                            max: 12,
                            divisions: 11,
                            label: _servings.toString(),
                            onChanged: (value) => setState(() => _servings = value.toInt()),
                          ),
                          const SizedBox(height: 8),
                          Text('Max Time: $_maxTime min', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Slider(
                            value: _maxTime.toDouble(),
                            min: 15,
                            max: 180,
                            divisions: 11,
                            label: _maxTime.toString(),
                            onChanged: (value) => setState(() => _maxTime = value.toInt()),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dietary Preferences',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
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
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: provider.isLoading ? null : _generateRecipe,
                    icon: provider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(provider.isLoading ? 'Generating...' : 'Generate Recipe'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  if (provider.error != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                provider.error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (provider.generatedRecipe != null) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Generated Recipe',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    RecipeCard(recipe: provider.generatedRecipe!),
                  ],
                ],
              ),
            ),
          );
        },
          ),
        ),
      ),
    );
  }
}
