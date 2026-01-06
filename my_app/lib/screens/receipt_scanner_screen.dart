import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/fridge_provider.dart';
import '../services/api_service.dart';
import '../utils/mealy_theme.dart';

class ReceiptScannerScreen extends StatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  AnimationController? animationController;
  Animation<double>? topBarAnimation;

  Uint8List? _selectedImageBytes;
  bool _isProcessing = false;
  String? _resultMessage;
  List<dynamic> _extractedItems = [];
  bool _isSuccess = false;

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
        // Read bytes - works on all platforms including web
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _resultMessage = null;
          _extractedItems = [];
          _isSuccess = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _processReceipt() async {
    if (_selectedImageBytes == null) {
      _showErrorSnackBar('Please select an image first');
      return;
    }

    setState(() {
      _isProcessing = true;
      _resultMessage = null;
      _extractedItems = [];
    });

    try {
      // Convert image to base64
      final base64Image = base64Encode(_selectedImageBytes!);

      // Send to backend
      final response = await _apiService.scanReceipt(base64Image);

      // Extract data from response wrapper
      final result = response['data'] as Map<String, dynamic>? ?? response;

      debugPrint('Receipt scan result: $result');
      debugPrint('is_receipt: ${result['is_receipt']}');
      debugPrint('items_added: ${result['items_added']}');
      debugPrint('items_updated: ${result['items_updated']}');
      debugPrint('items: ${result['items']}');

      
      

      // Handle both wrapped API responses ({data: {...}}) and plain payloads
      final payload = (result['data'] as Map<String, dynamic>?) ?? result;
      final itemsAdded = (payload['items_added'] ?? 0) as num;
      final itemsUpdated = (payload['items_updated'] ?? 0) as num;
      final isReceipt = payload['is_receipt'] == true;
      final totalProcessed = itemsAdded + itemsUpdated;
      setState(() {
        _isProcessing = false;
        _isSuccess = isReceipt && (itemsAdded + itemsUpdated) > 0;
        _resultMessage =
            (result['message'] ?? payload['message'] ?? 'Processing complete')
                .toString();
        _extractedItems = (payload['items'] as List<dynamic>?) ?? [];
      });

      debugPrint('_isSuccess: $_isSuccess (totalProcessed: $totalProcessed)');

      if (_isSuccess) {
        // Refresh fridge items
        debugPrint('Receipt scan successful! Refreshing fridge items...');
        if (mounted) {
          await context.read<FridgeProvider>().loadFridgeItems();
          debugPrint('Fridge items refresh completed');
        }

        // Build appropriate message
        String message;
        if (itemsAdded > 0 && itemsUpdated > 0) {
          message = '$itemsAdded new items added, $itemsUpdated items updated!';
        } else if (itemsUpdated > 0) {
          message = '$itemsUpdated items updated in your fridge!';
        } else {
          message = '$itemsAdded items added to your fridge!';
        }
        _showSuccessSnackBar(message);
      } else if (result['is_receipt'] == false) {
        _showErrorSnackBar(result['message'] ?? 'This is not a valid receipt');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _resultMessage = 'Error: $e';
        _isSuccess = false;
      });
      _showErrorSnackBar('Failed to process receipt: $e');
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
                                'Scan Receipt',
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
        _buildImagePickerButtons(),
        const SizedBox(height: 24),
        if (_selectedImageBytes != null) ...[
          _buildImagePreview(),
          const SizedBox(height: 24),
          _buildProcessButton(),
          const SizedBox(height: 24),
        ],
        if (_isProcessing) _buildLoadingIndicator(),
        if (_extractedItems.isNotEmpty) _buildExtractedItemsList(),
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
                        Icons.receipt_long,
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
                            'Smart Receipt Scanner',
                            style: TextStyle(
                              fontFamily: MealyTheme.fontName,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: MealyTheme.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Take a photo or upload a shopping receipt to automatically add food items to your fridge',
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
                    label: 'Choose from Gallery',
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: MealyTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: MealyTheme.grey.withOpacity(0.2),
              offset: const Offset(1.1, 1.1),
              blurRadius: 10.0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: MealyTheme.nearlyOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: MealyTheme.nearlyOrange, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: MealyTheme.fontName,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: MealyTheme.darkerText,
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
        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animationController!,
            curve: const Interval(0.3, 0.8, curve: Curves.fastOutSlowIn),
          ),
        );
        return FadeTransition(
          opacity: animation,
          child: Container(
            decoration: BoxDecoration(
              color: MealyTheme.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: MealyTheme.grey.withOpacity(0.2),
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
                      const Text(
                        'Selected Image',
                        style: TextStyle(
                          fontFamily: MealyTheme.fontName,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: MealyTheme.darkerText,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedImageBytes = null;
                            _resultMessage = null;
                            _extractedItems = [];
                          });
                        },
                        icon: Icon(
                          Icons.close,
                          color: MealyTheme.grey.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: Image.memory(
                    _selectedImageBytes!,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProcessButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processReceipt,
        style: ElevatedButton.styleFrom(
          backgroundColor: MealyTheme.nearlyOrange,
          disabledBackgroundColor: MealyTheme.nearlyOrange.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: MealyTheme.nearlyOrange.withOpacity(0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.document_scanner,
              color: MealyTheme.white.withOpacity(_isProcessing ? 0.5 : 1),
            ),
            const SizedBox(width: 12),
            Text(
              _isProcessing ? 'Processing...' : 'Scan Receipt',
              style: TextStyle(
                fontFamily: MealyTheme.fontName,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: MealyTheme.white.withOpacity(_isProcessing ? 0.5 : 1),
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
            color: MealyTheme.nearlyOrange,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Analyzing your receipt...',
            style: TextStyle(
              fontFamily: MealyTheme.fontName,
              fontSize: 14,
              color: MealyTheme.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few seconds',
            style: TextStyle(
              fontFamily: MealyTheme.fontName,
              fontSize: 12,
              color: MealyTheme.grey.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractedItemsList() {
    return Container(
      decoration: BoxDecoration(
        color: MealyTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: MealyTheme.grey.withOpacity(0.2),
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _isSuccess
                        ? MealyTheme.nearlyGreen.withOpacity(0.1)
                        : Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isSuccess ? Icons.check_circle : Icons.info,
                    color: _isSuccess ? MealyTheme.nearlyGreen : Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSuccess ? 'Items Added!' : 'Results',
                        style: const TextStyle(
                          fontFamily: MealyTheme.fontName,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: MealyTheme.darkerText,
                        ),
                      ),
                      Text(
                        '${_extractedItems.length} food items found',
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
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _extractedItems.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = _extractedItems[index];
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(
                      item['category'] ?? 'Other',
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getCategoryIcon(item['category'] ?? 'Other'),
                    color: _getCategoryColor(item['category'] ?? 'Other'),
                    size: 20,
                  ),
                ),
                title: Text(
                  item['ingredientName'] ?? item['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontFamily: MealyTheme.fontName,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: MealyTheme.darkerText,
                  ),
                ),
                subtitle: Text(
                  '${item['quantity']} ${item['unit']} • ${item['category'] ?? 'Other'}',
                  style: TextStyle(
                    fontFamily: MealyTheme.fontName,
                    fontSize: 12,
                    color: MealyTheme.grey,
                  ),
                ),
                trailing: Icon(
                  Icons.check_circle,
                  color: MealyTheme.nearlyGreen,
                  size: 20,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'fruits':
        return const Color(0xFFFA7D82);
      case 'vegetables':
        return const Color(0xFF738AE6);
      case 'dairy':
        return const Color(0xFFFEB95A);
      case 'meat':
        return const Color(0xFFE57373);
      case 'grains':
        return const Color(0xFF81C784);
      default:
        return const Color(0xFF6F72CA);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fruits':
        return Icons.apple;
      case 'vegetables':
        return Icons.eco;
      case 'dairy':
        return Icons.egg;
      case 'meat':
        return Icons.set_meal;
      case 'grains':
        return Icons.grass;
      default:
        return Icons.kitchen;
    }
  }
}
