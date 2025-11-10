import 'package:flutter/material.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  DateTime _selectedDate = DateTime.now();
  
  final Map<String, List<Map<String, String>>> _mealPlans = {
    'breakfast': [],
    'lunch': [],
    'dinner': [],
    'snacks': [],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planner'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                      });
                    },
                  ),
                  Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _selectedDate = _selectedDate.add(const Duration(days: 1));
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMealSection('Breakfast', 'breakfast', Icons.free_breakfast),
                const SizedBox(height: 16),
                _buildMealSection('Lunch', 'lunch', Icons.lunch_dining),
                const SizedBox(height: 16),
                _buildMealSection('Dinner', 'dinner', Icons.dinner_dining),
                const SizedBox(height: 16),
                _buildMealSection('Snacks', 'snacks', Icons.cookie),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMealDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Meal'),
      ),
    );
  }

  Widget _buildMealSection(String title, String mealType, IconData icon) {
    final meals = _mealPlans[mealType] ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (meals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No meals planned',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            else
              ...meals.map((meal) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(meal['name'] ?? ''),
                    subtitle: meal['calories'] != null
                        ? Text('${meal['calories']} calories')
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          meals.remove(meal);
                        });
                      },
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  void _showAddMealDialog() {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    String selectedMealType = 'breakfast';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Meal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedMealType,
              decoration: const InputDecoration(
                labelText: 'Meal Type',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: 'breakfast', child: Text('Breakfast')),
                const DropdownMenuItem(value: 'lunch', child: Text('Lunch')),
                const DropdownMenuItem(value: 'dinner', child: Text('Dinner')),
                const DropdownMenuItem(value: 'snacks', child: Text('Snacks')),
              ],
              onChanged: (value) => selectedMealType = value!,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Meal Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: caloriesController,
              decoration: const InputDecoration(
                labelText: 'Calories (optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              
              setState(() {
                _mealPlans[selectedMealType]!.add({
                  'name': nameController.text,
                  if (caloriesController.text.isNotEmpty)
                    'calories': caloriesController.text,
                });
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
