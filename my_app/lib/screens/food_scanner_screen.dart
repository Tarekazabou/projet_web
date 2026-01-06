import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/nutrition_provider.dart';
import '../utils/mealy_theme.dart';

class FoodScannerScreen extends StatefulWidget {
  const FoodScannerScreen({super.key});

  @override
  State<FoodScannerScreen> createState() => _FoodScannerScreenState();
}

class _FoodScannerScreenState extends State<FoodScannerScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  AnimationController? animationController;
  Animation<double>? topBarAnimation;

  Uint8List? _selectedImageBytes;
  bool _isProcessing = false;
  Map<String, dynamic>? _analysisResult;
  String? _errorMessage;
  String _selectedMealType = 'lunch';
  bool _autoLog = true;

  final List<String> _mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];

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

    animationController?.forward();
  }

  @override
  void dispose() {
    animationController?.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _analysisResult = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _analyzeFood() async {
    if (_selectedImageBytes == null) {
      _showErrorSnackBar('Please select an image first');
      return;
    }

    setState(() {
      _isProcessing = true;
      _analysisResult = null;
      _errorMessage = null;
    });

    try {
      final base64Image = base64Encode(_selectedImageBytes!);
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final response = await _apiService.scanFood(
        base64Image,
        date: today,
        mealType: _selectedMealType,
        autoLog: _autoLog,
      );

      // Debug: Print the response structure
      debugPrint('Food scan response: $response');
      debugPrint('Response type: ${response.runtimeType}');
      debugPrint('Response keys: ${response.keys.toList()}');

      // Extract data from response wrapper - handle nested structure
      Map<String, dynamic> result;
      if (response.containsKey('data') && response['data'] != null) {
        result = response['data'] as Map<String, dynamic>;
      } else {
        result = response;
      }

      debugPrint('Extracted result: $result');
      debugPrint('is_food value: ${result['is_food']}');

      setState(() {
        _isProcessing = false;
        _analysisResult = result;
      });

      if (result['is_food'] == true) {
        if (_autoLog && result['logged'] == true) {
          // Refresh nutrition data after logging
          if (mounted) {
            await context.read<NutritionProvider>().loadNutritionData();
          }
          _showSuccessSnackBar('Meal logged successfully!');
        } else {
          _showSuccessSnackBar('Food analyzed successfully!');
        }
      } else {
        _showErrorSnackBar(result['message'] ?? 'Could not identify food');
      }
    } catch (e, stackTrace) {
      debugPrint('Error in _analyzeFood: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Error: $e';
      });
      _showErrorSnackBar('Failed to analyze food: $e');
    }
  }

  Future<void> _logMeal() async {
    if (_analysisResult == null || _analysisResult!['is_food'] != true) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await _apiService.logScannedFood(
        mealName: _analysisResult!['meal_name'],
        nutrition: _analysisResult!['nutrition'],
        foodItems: List<String>.from(_analysisResult!['food_items'] ?? []),
        date: today,
        mealType: _selectedMealType,
        portionSize: _analysisResult!['portion_size'],
        healthNotes: _analysisResult!['health_notes'],
      );

      setState(() {
        _isProcessing = false;
        _analysisResult!['logged'] = true;
        _analysisResult!['meal_id'] = 'logged';
      });

      // Refresh nutrition data after logging
      if (mounted) {
        await context.read<NutritionProvider>().loadNutritionData();
      }

      _showSuccessSnackBar('Meal logged successfully!');
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorSnackBar('Failed to log meal: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: MealyTheme.nearlyGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
                    color: MealyTheme.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: MealyTheme.grey.withOpacity(0.4),
                        offset: const Offset(1.1, 1.1),
                        blurRadius: 10.0,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 8,
                          right: 16,
                          top: 16,
                          bottom: 12,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: MealyTheme.darkerText,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Expanded(
                              child: Text(
                                'Food Scanner',
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontFamily: MealyTheme.fontName,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22,
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
    return ListView(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 88,
        bottom: 100,
        left: 16,
        right: 16,
      ),
      children: [
        _buildInstructionCard(),
        const SizedBox(height: 24),
        _buildMealTypeSelector(),
        const SizedBox(height: 16),
        _buildAutoLogToggle(),
        const SizedBox(height: 24),
        _buildImagePickerButtons(),
        const SizedBox(height: 24),
        if (_selectedImageBytes != null) ...[
          _buildImagePreview(),
          const SizedBox(height: 24),
          _buildAnalyzeButton(),
          const SizedBox(height: 24),
        ],
        if (_isProcessing) _buildLoadingIndicator(),
        if (_analysisResult != null && _analysisResult!['is_food'] == true)
          _buildNutritionResults(),
      ],
    );
  }

  Widget _buildInstructionCard() {
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
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: MealyTheme.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu,
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
                            'AI Food Scanner',
                            style: TextStyle(
                              fontFamily: MealyTheme.fontName,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: MealyTheme.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Take a photo of your meal to automatically analyze nutrition facts and track your intake',
                            style: TextStyle(
                              fontFamily: MealyTheme.fontName,
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
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
        );
      },
    );
  }

  Widget _buildMealTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MealyTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: MealyTheme.grey.withOpacity(0.2),
            offset: const Offset(1.1, 1.1),
            blurRadius: 8.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Meal Type',
            style: TextStyle(
              fontFamily: MealyTheme.fontName,
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: MealyTheme.darkText,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _mealTypes.map((type) {
              final isSelected = _selectedMealType == type;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMealType = type;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? MealyTheme.nearlyGreen
                        : MealyTheme.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? MealyTheme.nearlyGreen
                          : MealyTheme.grey.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    type[0].toUpperCase() + type.substring(1),
                    style: TextStyle(
                      fontFamily: MealyTheme.fontName,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: isSelected
                          ? MealyTheme.white
                          : MealyTheme.darkText,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoLogToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MealyTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: MealyTheme.grey.withOpacity(0.2),
            offset: const Offset(1.1, 1.1),
            blurRadius: 8.0,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Auto-log meal',
                  style: TextStyle(
                    fontFamily: MealyTheme.fontName,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: MealyTheme.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Automatically save to nutrition tracker',
                  style: TextStyle(
                    fontFamily: MealyTheme.fontName,
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: MealyTheme.grey.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _autoLog,
            onChanged: (value) {
              setState(() {
                _autoLog = value;
              });
            },
            activeColor: MealyTheme.nearlyGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickerButtons() {
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
            child: Row(
              children: [
                Expanded(
                  child: _buildPickerButton(
                    icon: Icons.camera_alt,
                    label: 'Take Photo',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPickerButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: MealyTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: MealyTheme.grey.withOpacity(0.2),
              offset: const Offset(1.1, 1.1),
              blurRadius: 8.0,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: MealyTheme.nearlyGreen),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: MealyTheme.fontName,
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: MealyTheme.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return AnimatedBuilder(
      animation: animationController!,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: MealyTheme.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: MealyTheme.grey.withOpacity(0.2),
                offset: const Offset(1.1, 1.1),
                blurRadius: 8.0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Image.memory(
                  _selectedImageBytes!,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedImageBytes = null;
                        _analysisResult = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyzeButton() {
    return GestureDetector(
      onTap: _isProcessing ? null : _analyzeFood,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isProcessing
                ? [MealyTheme.grey, MealyTheme.grey.withOpacity(0.8)]
                : [
                    MealyTheme.nearlyGreen,
                    MealyTheme.nearlyGreen.withOpacity(0.8),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: MealyTheme.nearlyGreen.withOpacity(0.4),
              offset: const Offset(1.1, 4.0),
              blurRadius: 8.0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isProcessing ? Icons.hourglass_empty : Icons.auto_awesome,
              color: MealyTheme.white,
            ),
            const SizedBox(width: 12),
            Text(
              _isProcessing ? 'Analyzing...' : 'Analyze Food',
              style: const TextStyle(
                fontFamily: MealyTheme.fontName,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: MealyTheme.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(MealyTheme.nearlyGreen),
          ),
          const SizedBox(height: 16),
          Text(
            'Analyzing your meal...',
            style: TextStyle(
              fontFamily: MealyTheme.fontName,
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: MealyTheme.grey.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionResults() {
    final nutrition = _analysisResult!['nutrition'] as Map<String, dynamic>?;
    final mealName = _analysisResult!['meal_name'] as String? ?? 'Unknown Meal';
    final foodItems = List<String>.from(_analysisResult!['food_items'] ?? []);
    final healthNotes = _analysisResult!['health_notes'] as String? ?? '';
    final portionSize = _analysisResult!['portion_size'] as String? ?? 'medium';
    final isLogged = _analysisResult!['logged'] == true;

    return Column(
      children: [
        // Meal Info Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: MealyTheme.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: MealyTheme.grey.withOpacity(0.2),
                offset: const Offset(1.1, 1.1),
                blurRadius: 8.0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.restaurant, color: MealyTheme.nearlyGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      mealName,
                      style: const TextStyle(
                        fontFamily: MealyTheme.fontName,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: MealyTheme.darkText,
                      ),
                    ),
                  ),
                  if (isLogged)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: MealyTheme.nearlyGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: MealyTheme.nearlyGreen,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Logged',
                            style: TextStyle(
                              fontFamily: MealyTheme.fontName,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: MealyTheme.nearlyGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Portion: $portionSize',
                style: TextStyle(
                  fontFamily: MealyTheme.fontName,
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: MealyTheme.grey.withOpacity(0.8),
                ),
              ),
              if (foodItems.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: foodItems.map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: MealyTheme.nearlyGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontFamily: MealyTheme.fontName,
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: MealyTheme.darkText,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Nutrition Facts Card
        if (nutrition != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: MealyTheme.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: MealyTheme.grey.withOpacity(0.2),
                  offset: const Offset(1.1, 1.1),
                  blurRadius: 8.0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nutrition Facts',
                  style: TextStyle(
                    fontFamily: MealyTheme.fontName,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: MealyTheme.darkText,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCaloriesDisplay(nutrition['calories'] ?? 0),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildNutrientItem(
                        'Protein',
                        '${nutrition['protein'] ?? 0}g',
                        MealyTheme.nearlyGreen,
                      ),
                    ),
                    Expanded(
                      child: _buildNutrientItem(
                        'Carbs',
                        '${nutrition['carbs'] ?? 0}g',
                        MealyTheme.nearlyOrange,
                      ),
                    ),
                    Expanded(
                      child: _buildNutrientItem(
                        'Fat',
                        '${nutrition['fat'] ?? 0}g',
                        const Color(0xFF738AE6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildNutrientItem(
                        'Fiber',
                        '${nutrition['fiber'] ?? 0}g',
                        Colors.brown,
                      ),
                    ),
                    Expanded(
                      child: _buildNutrientItem(
                        'Sugar',
                        '${nutrition['sugar'] ?? 0}g',
                        Colors.pink,
                      ),
                    ),
                    Expanded(
                      child: _buildNutrientItem(
                        'Sodium',
                        '${nutrition['sodium'] ?? 0}mg',
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Health Notes Card
        if (healthNotes.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: MealyTheme.nearlyGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: MealyTheme.nearlyGreen.withOpacity(0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: MealyTheme.nearlyGreen,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    healthNotes,
                    style: const TextStyle(
                      fontFamily: MealyTheme.fontName,
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: MealyTheme.darkText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Log Button (if not auto-logged)
        if (!isLogged && !_autoLog)
          GestureDetector(
            onTap: _isProcessing ? null : _logMeal,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    MealyTheme.nearlyOrange,
                    MealyTheme.nearlyOrange.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: MealyTheme.nearlyOrange.withOpacity(0.4),
                    offset: const Offset(1.1, 4.0),
                    blurRadius: 8.0,
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, color: MealyTheme.white),
                  SizedBox(width: 12),
                  Text(
                    'Log This Meal',
                    style: TextStyle(
                      fontFamily: MealyTheme.fontName,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: MealyTheme.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCaloriesDisplay(dynamic calories) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MealyTheme.nearlyOrange.withOpacity(0.2),
            MealyTheme.nearlyOrange.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.local_fire_department,
            color: MealyTheme.nearlyOrange,
            size: 32,
          ),
          const SizedBox(width: 12),
          Text(
            '$calories',
            style: const TextStyle(
              fontFamily: MealyTheme.fontName,
              fontWeight: FontWeight.bold,
              fontSize: 32,
              color: MealyTheme.nearlyOrange,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'kcal',
            style: TextStyle(
              fontFamily: MealyTheme.fontName,
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: MealyTheme.nearlyOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: MealyTheme.fontName,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: MealyTheme.fontName,
            fontWeight: FontWeight.w400,
            fontSize: 12,
            color: MealyTheme.grey.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}
