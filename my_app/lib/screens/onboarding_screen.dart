import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/app_buttons.dart';
import '../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    final provider = Provider.of<OnboardingProvider>(context, listen: false);
    provider.nextStep();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    final provider = Provider.of<OnboardingProvider>(context, listen: false);
    provider.previousStep();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _skipOnboarding() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId != null) {
      // Mark as completed without saving data
      await Provider.of<OnboardingProvider>(context, listen: false)
          .completeOnboarding(userId);
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  Future<void> _completeOnboarding() async {
    final provider = Provider.of<OnboardingProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId == null) return;

    final success = await provider.completeOnboarding(userId);

    if (mounted && success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } else if (mounted && provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Consumer<OnboardingProvider>(
              builder: (context, provider, child) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: provider.currentStep > 0
                            ? _previousPage
                            : null,
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (provider.currentStep + 1) / 5,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _skipOnboarding,
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            // Page view
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  GenderSelectionPage(),
                  PhysicalInfoPage(),
                  AllergiesPage(),
                  FridgeItemsPage(),
                  DietPreferencesPage(),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Consumer<OnboardingProvider>(
                builder: (context, provider, child) {
                  return PrimaryButton(
                    text: provider.isLastStep ? 'Get Started' : 'Continue',
                    onPressed: provider.isLastStep
                        ? _completeOnboarding
                        : _nextPage,
                    isLoading: provider.isLoading,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Step 1: Gender Selection
class GenderSelectionPage extends StatelessWidget {
  const GenderSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            size: 80,
            color: AppTheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'What\'s your gender?',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'This helps us personalize your nutrition goals',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Consumer<OnboardingProvider>(
            builder: (context, provider, child) {
              return Row(
                children: [
                  Expanded(
                    child: _GenderCard(
                      icon: Icons.male,
                      label: 'Male',
                      isSelected: provider.data.gender == 'male',
                      onTap: () => provider.updateGender('male'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _GenderCard(
                      icon: Icons.female,
                      label: 'Female',
                      isSelected: provider.data.gender == 'female',
                      onTap: () => provider.updateGender('female'),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected ? AppTheme.primary : Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.primary : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Step 2: Physical Info (Weight & Height)
class PhysicalInfoPage extends StatefulWidget {
  const PhysicalInfoPage({super.key});

  @override
  State<PhysicalInfoPage> createState() => _PhysicalInfoPageState();
}

class _PhysicalInfoPageState extends State<PhysicalInfoPage> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.monitor_weight,
            size: 80,
            color: AppTheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Tell us about yourself',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Help us calculate your personalized nutrition needs',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Consumer<OnboardingProvider>(
            builder: (context, provider, child) {
              return Column(
                children: [
                  TextField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      hintText: 'Enter your weight',
                      prefixIcon: Icon(Icons.monitor_weight_outlined),
                    ),
                    onChanged: (value) {
                      final weight = double.tryParse(value);
                      if (weight != null) {
                        provider.updateWeight(weight);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Height (cm)',
                      hintText: 'Enter your height',
                      prefixIcon: Icon(Icons.height),
                    ),
                    onChanged: (value) {
                      final height = double.tryParse(value);
                      if (height != null) {
                        provider.updateHeight(height);
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// Step 3: Allergies
class AllergiesPage extends StatefulWidget {
  const AllergiesPage({super.key});

  @override
  State<AllergiesPage> createState() => _AllergiesPageState();
}

class _AllergiesPageState extends State<AllergiesPage> {
  final List<String> commonAllergies = [
    'Peanuts',
    'Tree Nuts',
    'Milk',
    'Eggs',
    'Wheat',
    'Soy',
    'Fish',
    'Shellfish',
    'Sesame',
    'None',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 80,
            color: AppTheme.warning,
          ),
          const SizedBox(height: 24),
          Text(
            'Any food allergies?',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Select all that apply so we can keep you safe',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Consumer<OnboardingProvider>(
            builder: (context, provider, child) {
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: commonAllergies.map((allergy) {
                  final isSelected = provider.data.allergies.contains(allergy);
                  return FilterChip(
                    label: Text(allergy),
                    selected: isSelected,
                    onSelected: (selected) {
                      final allergies = List<String>.from(provider.data.allergies);
                      if (allergy == 'None') {
                        provider.updateAllergies([]);
                      } else {
                        if (selected) {
                          allergies.add(allergy);
                          allergies.remove('None');
                        } else {
                          allergies.remove(allergy);
                        }
                        provider.updateAllergies(allergies);
                      }
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Step 4: Fridge Items
class FridgeItemsPage extends StatefulWidget {
  const FridgeItemsPage({super.key});

  @override
  State<FridgeItemsPage> createState() => _FridgeItemsPageState();
}

class _FridgeItemsPageState extends State<FridgeItemsPage> {
  final _itemController = TextEditingController();

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Icon(
            Icons.kitchen,
            size: 80,
            color: AppTheme.secondary,
          ),
          const SizedBox(height: 24),
          Text(
            'What\'s in your fridge?',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Add some ingredients to get personalized recipe suggestions',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Consumer<OnboardingProvider>(
            builder: (context, provider, child) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _itemController,
                          decoration: const InputDecoration(
                            labelText: 'Add ingredient',
                            hintText: 'e.g., Chicken, Tomatoes',
                            prefixIcon: Icon(Icons.add),
                          ),
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              final items = List<String>.from(provider.data.fridgeItems);
                              items.add(value.trim());
                              provider.updateFridgeItems(items);
                              _itemController.clear();
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        onPressed: () {
                          if (_itemController.text.trim().isNotEmpty) {
                            final items = List<String>.from(provider.data.fridgeItems);
                            items.add(_itemController.text.trim());
                            provider.updateFridgeItems(items);
                            _itemController.clear();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (provider.data.fridgeItems.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: provider.data.fridgeItems.map((item) {
                        return Chip(
                          label: Text(item),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            final items = List<String>.from(provider.data.fridgeItems);
                            items.remove(item);
                            provider.updateFridgeItems(items);
                          },
                        );
                      }).toList(),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// Step 5: Diet Preferences
class DietPreferencesPage extends StatelessWidget {
  const DietPreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dietTypes = [
      {'name': 'Balanced', 'icon': Icons.restaurant, 'description': 'Well-rounded nutrition'},
      {'name': 'Vegetarian', 'icon': Icons.eco, 'description': 'No meat or fish'},
      {'name': 'Vegan', 'icon': Icons.spa, 'description': 'No animal products'},
      {'name': 'Keto', 'icon': Icons.bolt, 'description': 'Low-carb, high-fat'},
      {'name': 'Paleo', 'icon': Icons.fitness_center, 'description': 'Whole foods focused'},
      {'name': 'Mediterranean', 'icon': Icons.wb_sunny, 'description': 'Heart-healthy'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 80,
            color: AppTheme.accent,
          ),
          const SizedBox(height: 24),
          Text(
            'Choose your diet',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'We\'ll recommend recipes that match your preference',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Consumer<OnboardingProvider>(
            builder: (context, provider, child) {
              return Column(
                children: dietTypes.map((diet) {
                  final isSelected = provider.data.dietType == diet['name'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: InkWell(
                      onTap: () => provider.updateDietType(diet['name'] as String),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryLight.withOpacity(0.2)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppTheme.primary : Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              diet['icon'] as IconData,
                              color: isSelected ? AppTheme.primary : Colors.grey,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    diet['name'] as String,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? AppTheme.primary
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    diet['description'] as String,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: AppTheme.primary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
