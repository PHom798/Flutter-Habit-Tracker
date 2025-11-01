import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';



class Habit {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final String category;
  int currentStreak;
  int bestStreak;
  DateTime? lastCompleted;
  Set<DateTime> completedDates;
  int totalCompleted;

  Habit({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.category,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastCompleted,
    Set<DateTime>? completedDates,
    this.totalCompleted = 0,
  }) : completedDates = completedDates ?? {};

  bool get isCompletedToday {
    final today = DateTime.now();
    return completedDates.any((date) =>
    date.year == today.year &&
        date.month == today.month &&
        date.day == today.day
    );
  }

  double get weeklyProgress {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    int completedThisWeek = 0;

    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      if (completedDates.any((date) =>
      date.year == day.year &&
          date.month == day.month &&
          date.day == day.day
      )) {
        completedThisWeek++;
      }
    }

    return completedThisWeek / 7.0;
  }
}

enum CelebrationLevel { small, medium, large, epic, legendary }

class HabitTrackerPage extends StatefulWidget {
  const HabitTrackerPage({super.key});

  @override
  State<HabitTrackerPage> createState() => _HabitTrackerPageState();
}

class _HabitTrackerPageState extends State<HabitTrackerPage>
    with TickerProviderStateMixin {

  // Animation controllers
  late AnimationController _backgroundController;
  late AnimationController _streakController;
  late AnimationController _rippleController;
  late AnimationController _addHabitController;

  // Confetti controllers for different celebrations
  final ConfettiController _smallCelebration = ConfettiController(duration: Duration(seconds: 1));
  final ConfettiController _mediumCelebration = ConfettiController(duration: Duration(seconds: 2));
  final ConfettiController _largeCelebration = ConfettiController(duration: Duration(seconds: 3));
  final ConfettiController _epicCelebration = ConfettiController(duration: Duration(seconds: 4));
  final ConfettiController _legendaryCelebration = ConfettiController(duration: Duration(seconds: 5));

  // Theme management
  int _currentTheme = 0;
  final List<List<Color>> _themes = [
    [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)], // Cosmic
    [Color(0xFF2D1B69), Color(0xFF11998e), Color(0xFF38ef7d)], // Aurora
    [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFF667eea)], // Mystic
    [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243e)], // Dark Magic
  ];

  // Add habit form variables
  final TextEditingController _habitNameController = TextEditingController();
  String _selectedEmoji = '🎯';
  Color _selectedColor = Colors.blue;
  String _selectedCategory = 'Personal';

  final List<String> _habitEmojis = [
    '💪', '🧘‍♀️', '📚', '💧', '🎸', '🏃‍♂️', '🥗', '💤', '🎯', '🖥️',
    '🧠', '💝', '🌱', '🎨', '📝', '☕', '🏋️‍♀️', '🚴‍♂️', '📱', '🎵',
    '🧹', '💰', '📞', '🌞', '🥛', '🏠', '⚽', '🎮', '🍎', '🚗',
    '📖', '✍️', '🧘', '🌿', '🎪', '🎭', '🎬', '📺', '🎲', '🃏',
    '🏆', '🎊', '🎉', '⭐', '🔥', '💎', '👑', '🚀', '⚡', '🌟'
  ];

  final List<String> _categories = [
    'Fitness', 'Health', 'Learning', 'Mindfulness', 'Skills',
    'Personal', 'Work', 'Social', 'Creative', 'Finance'
  ];

  final List<Color> _habitColors = [
    Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
    Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
    Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
    Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
    Colors.brown, Colors.grey, Colors.blueGrey,
  ];

  // Sample habits data
  List<Habit> _habits = [
    Habit(
      id: '1',
      name: 'Morning Workout',
      emoji: '💪',
      color: Colors.orange,
      category: 'Fitness',
      currentStreak: 5,
      totalCompleted: 45,
    ),
    Habit(
      id: '2',
      name: 'Meditation',
      emoji: '🧘‍♀️',
      color: Colors.purple,
      category: 'Mindfulness',
      currentStreak: 12,
      totalCompleted: 78,
    ),
    Habit(
      id: '3',
      name: 'Read Books',
      emoji: '📚',
      color: Colors.blue,
      category: 'Learning',
      currentStreak: 7,
      totalCompleted: 34,
    ),
    Habit(
      id: '4',
      name: 'Drink Water',
      emoji: '💧',
      color: Colors.cyan,
      category: 'Health',
      currentStreak: 3,
      totalCompleted: 89,
    ),
    Habit(
      id: '5',
      name: 'Practice Guitar',
      emoji: '🎸',
      color: Colors.green,
      category: 'Skills',
      currentStreak: 15,
      totalCompleted: 56,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _streakController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _addHabitController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _streakController.dispose();
    _rippleController.dispose();
    _addHabitController.dispose();
    _habitNameController.dispose();
    _smallCelebration.dispose();
    _mediumCelebration.dispose();
    _largeCelebration.dispose();
    _epicCelebration.dispose();
    _legendaryCelebration.dispose();
    super.dispose();
  }

  CelebrationLevel _getCelebrationLevel(int streak) {
    if (streak >= 100) return CelebrationLevel.legendary;
    if (streak >= 50) return CelebrationLevel.epic;
    if (streak >= 21) return CelebrationLevel.large;
    if (streak >= 7) return CelebrationLevel.medium;
    return CelebrationLevel.small;
  }

  void _celebrateStreak(int streak, Color habitColor) {
    final level = _getCelebrationLevel(streak);

    switch (level) {
      case CelebrationLevel.small:
        HapticFeedback.lightImpact();
        _smallCelebration.play();
        break;
      case CelebrationLevel.medium:
        HapticFeedback.mediumImpact();
        _mediumCelebration.play();
        break;
      case CelebrationLevel.large:
        HapticFeedback.heavyImpact();
        _largeCelebration.play();
        break;
      case CelebrationLevel.epic:
        HapticFeedback.heavyImpact();
        _epicCelebration.play();
        Future.delayed(Duration(milliseconds: 500), () => _smallCelebration.play());
        break;
      case CelebrationLevel.legendary:
        HapticFeedback.heavyImpact();
        _legendaryCelebration.play();
        Future.delayed(Duration(milliseconds: 800), () => _epicCelebration.play());
        Future.delayed(Duration(milliseconds: 1200), () => _mediumCelebration.play());
        break;
    }

    _streakController.forward().then((_) => _streakController.reverse());
    _rippleController.forward().then((_) => _rippleController.reverse());
  }

  void _toggleHabit(Habit habit) {
    setState(() {
      final today = DateTime.now();
      final todayKey = DateTime(today.year, today.month, today.day);

      if (habit.isCompletedToday) {
        habit.completedDates.removeWhere((date) =>
        date.year == today.year &&
            date.month == today.month &&
            date.day == today.day
        );
        habit.currentStreak = max(0, habit.currentStreak - 1);
        habit.totalCompleted = max(0, habit.totalCompleted - 1);
      } else {
        habit.completedDates.add(todayKey);
        habit.currentStreak++;
        habit.totalCompleted++;
        habit.lastCompleted = today;

        if (habit.currentStreak > habit.bestStreak) {
          habit.bestStreak = habit.currentStreak;
        }

        _celebrateStreak(habit.currentStreak, habit.color);
      }
    });
  }

  void _addNewHabit() {
    if (_habitNameController.text.trim().isEmpty) return;

    final newHabit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _habitNameController.text.trim(),
      emoji: _selectedEmoji,
      color: _selectedColor,
      category: _selectedCategory,
    );

    setState(() {
      _habits.add(newHabit);
    });

    _smallCelebration.play();
    HapticFeedback.lightImpact();

    _habitNameController.clear();
    _selectedEmoji = '🎯';
    _selectedColor = Colors.blue;
    _selectedCategory = 'Personal';

    Navigator.pop(context);
  }

  void _showAddHabitDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddHabitSheet(),
    );
  }

  Widget _buildAddHabitSheet() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _themes[_currentTheme][0],
                _themes[_currentTheme][1],
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '✨ Create New Habit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Habit Name'),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.white.withOpacity(0.1),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: TextField(
                            controller: _habitNameController,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'e.g., Morning Exercise',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            onChanged: (value) => setModalState(() {}),
                          ),
                        ),

                        const SizedBox(height: 24),

                        _buildSectionTitle('Choose Icon'),
                        Container(
                          height: 200,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.white.withOpacity(0.1),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 8,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                            ),
                            itemCount: _habitEmojis.length,
                            itemBuilder: (context, index) {
                              final emoji = _habitEmojis[index];
                              final isSelected = emoji == _selectedEmoji;

                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    _selectedEmoji = emoji;
                                  });
                                  HapticFeedback.selectionClick();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: isSelected
                                        ? _selectedColor.withOpacity(0.3)
                                        : Colors.white.withOpacity(0.1),
                                    border: Border.all(
                                      color: isSelected
                                          ? _selectedColor
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    boxShadow: isSelected ? [
                                      BoxShadow(
                                        color: _selectedColor.withOpacity(0.3),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ] : [],
                                  ),
                                  child: Center(
                                    child: Text(
                                      emoji,
                                      style: TextStyle(
                                        fontSize: isSelected ? 24 : 20,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        _buildSectionTitle('Choose Color'),
                        Container(
                          height: 80,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.white.withOpacity(0.1),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _habitColors.length,
                            itemBuilder: (context, index) {
                              final color = _habitColors[index];
                              final isSelected = color == _selectedColor;

                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    _selectedColor = color;
                                  });
                                  HapticFeedback.selectionClick();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 48,
                                  height: 48,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? Colors.white : Colors.transparent,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withOpacity(0.4),
                                        blurRadius: isSelected ? 15 : 8,
                                        spreadRadius: isSelected ? 2 : 0,
                                      ),
                                    ],
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, color: Colors.white, size: 24)
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        _buildSectionTitle('Category'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.white.withOpacity(0.1),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            underline: Container(),
                            dropdownColor: _themes[_currentTheme][0],
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            items: _categories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setModalState(() {
                                _selectedCategory = value!;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 32),

                        _buildSectionTitle('Preview'),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.white.withOpacity(0.1),
                            border: Border.all(
                              color: _selectedColor.withOpacity(0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _selectedColor.withOpacity(0.2),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _selectedColor.withOpacity(0.2),
                                  border: Border.all(color: _selectedColor),
                                ),
                                child: Center(
                                  child: Text(_selectedEmoji, style: const TextStyle(fontSize: 20)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _habitNameController.text.isNotEmpty
                                          ? _habitNameController.text
                                          : 'Your Habit Name',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _selectedCategory,
                                      style: TextStyle(
                                        color: _selectedColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _habitNameController.text.trim().isNotEmpty ? _addNewHabit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedColor,
                        foregroundColor: Colors.blueAccent,
                        elevation: 8,
                        shadowColor: _selectedColor.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        '✨ Create Habit',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFloatingParticle(double size, Color color, double delay) {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Positioned(
          left: 50 + (MediaQuery.of(context).size.width - 100) *
              ((sin(_backgroundController.value * 2 * pi + delay) + 1) / 2),
          top: 100 + (MediaQuery.of(context).size.height - 200) *
              ((cos(_backgroundController.value * pi + delay) + 1) / 2),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: size / 2,
                  spreadRadius: size / 4,
                ),
              ],
            ),
          ).animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 3000.ms, color: color.withOpacity(0.4))
              .scale(begin: Offset(0.8, 0.8), end: Offset(1.2, 1.2), duration: 4000.ms)
              .then()
              .scale(begin: Offset(1.2, 1.2), end: Offset(0.8, 0.8), duration: 4000.ms),
        );
      },
    );
  }

  Widget _buildHabitCard(Habit habit) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(
          color: habit.isCompletedToday
              ? habit.color.withOpacity(0.8)
              : Colors.white.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: habit.isCompletedToday
                ? habit.color.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: habit.isCompletedToday ? 20 : 10,
            offset: const Offset(0, 5),
            spreadRadius: habit.isCompletedToday ? 2 : 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _toggleHabit(habit),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: habit.isCompletedToday
                            ? habit.color.withOpacity(0.8)
                            : Colors.white.withOpacity(0.1),
                        border: Border.all(
                          color: habit.color,
                          width: 2,
                        ),
                        boxShadow: habit.isCompletedToday ? [
                          BoxShadow(
                            color: habit.color.withOpacity(0.5),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ] : [],
                      ),
                      child: Center(
                        child: Text(
                          habit.emoji,
                          style: const TextStyle(fontSize: 24),
                        ).animate(target: habit.isCompletedToday ? 1 : 0)
                            .scale(begin: Offset(1, 1), end: Offset(1.2, 1.2))
                            .rotate(begin: 0, end: 0.1),
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            habit.category,
                            style: TextStyle(
                              color: habit.color,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: habit.isCompletedToday
                          ? Icon(
                        Icons.check_circle,
                        color: habit.color,
                        size: 32,
                      ).animate()
                          .scale(begin: Offset(0, 0))
                          .slideX(begin: 1)
                          : Icon(
                        Icons.radio_button_unchecked,
                        color: Colors.white.withOpacity(0.5),
                        size: 32,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: MediaQuery.of(context).size.width * habit.weeklyProgress,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        colors: [habit.color.withOpacity(0.6), habit.color],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: habit.color.withOpacity(0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatChip(
                      '🔥 ${habit.currentStreak}',
                      'Current Streak',
                      habit.color,
                    ),
                    _buildStatChip(
                      '🏆 ${habit.bestStreak}',
                      'Best Streak',
                      Colors.amber,
                    ),
                    _buildStatChip(
                      '✅ ${habit.totalCompleted}',
                      'Total',
                      Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate()
        .fadeIn(duration: 600.ms)
        .slideX(begin: 0.3, duration: 400.ms);
  }

  Widget _buildStatChip(String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withOpacity(0.2),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsOverview() {
    final totalHabits = _habits.length;
    final completedToday = _habits.where((h) => h.isCompletedToday).length;
    final avgStreak = _habits.map((h) => h.currentStreak).reduce((a, b) => a + b) / totalHabits;
    final totalCompleted = _habits.map((h) => h.totalCompleted).reduce((a, b) => a + b);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '📊 Today\'s Progress',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverviewStat('$completedToday/$totalHabits', 'Completed', Colors.green),
              _buildOverviewStat('${avgStreak.toStringAsFixed(1)}', 'Avg Streak', Colors.orange),
              _buildOverviewStat('$totalCompleted', 'Total Done', Colors.blue),
            ],
          ),
        ],
      ),
    ).animate()
        .fadeIn(delay: 200.ms)
        .slideY(begin: -0.2);
  }

  Widget _buildOverviewStat(String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
            border: Border.all(color: color.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 15,
              ),
            ],
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildConfettiWidgets() {
    return [
      Align(
        alignment: Alignment.center,
        child: ConfettiWidget(
          confettiController: _smallCelebration,
          blastDirectionality: BlastDirectionality.explosive,
          emissionFrequency: 0.1,
          numberOfParticles: 20,
          maxBlastForce: 50,
          minBlastForce: 30,
          gravity: 0.3,
          shouldLoop: false,
          colors: [Colors.green, Colors.lightGreen, Colors.yellow],
        ),
      ),

      Align(
        alignment: Alignment.center,
        child: ConfettiWidget(
          confettiController: _mediumCelebration,
          blastDirectionality: BlastDirectionality.explosive,
          emissionFrequency: 0.05,
          numberOfParticles: 40,
          maxBlastForce: 80,
          minBlastForce: 60,
          gravity: 0.25,
          shouldLoop: false,
          colors: [Colors.orange, Colors.amber, Colors.yellow, Colors.red],
        ),
      ),

      Align(
        alignment: Alignment.center,
        child: ConfettiWidget(
          confettiController: _largeCelebration,
          blastDirectionality: BlastDirectionality.explosive,
          emissionFrequency: 0.03,
          numberOfParticles: 60,
          maxBlastForce: 120,
          minBlastForce: 80,
          gravity: 0.2,
          shouldLoop: false,
          colors: [Colors.pink, Colors.purple, Colors.blue, Colors.cyan],
          createParticlePath: (size) {
            final path = Path();
            final width = size.width;
            final height = size.height;
            path.moveTo(width * 0.5, height * 0.6);
            path.cubicTo(width * 0.2, height * 0.1, width * -0.25, height * 0.6, width * 0.5, height);
            path.moveTo(width * 0.5, height * 0.6);
            path.cubicTo(width * 0.8, height * 0.1, width * 1.25, height * 0.6, width * 0.5, height);
            return path;
          },
        ),
      ),

      Align(
        alignment: Alignment.center,
        child: ConfettiWidget(
          confettiController: _epicCelebration,
          blastDirectionality: BlastDirectionality.explosive,
          emissionFrequency: 0.02,
          numberOfParticles: 80,
          maxBlastForce: 150,
          minBlastForce: 100,
          gravity: 0.15,
          shouldLoop: false,
          colors: [Colors.yellow, Colors.orange, Colors.red, Colors.purple],
          createParticlePath: (size) {
            final path = Path();
            final w = size.width;
            final h = size.height;
            path.moveTo(w * 0.3, 0);
            path.lineTo(w * 0.7, h * 0.4);
            path.lineTo(w * 0.5, h * 0.4);
            path.lineTo(w * 0.8, h);
            path.lineTo(w * 0.4, h * 0.6);
            path.lineTo(w * 0.6, h * 0.6);
            path.close();
            return path;
          },
        ),
      ),

      Align(
        alignment: Alignment.center,
        child: ConfettiWidget(
          confettiController: _legendaryCelebration,
          blastDirectionality: BlastDirectionality.explosive,
          emissionFrequency: 0.01,
          numberOfParticles: 100,
          maxBlastForce: 200,
          minBlastForce: 150,
          gravity: 0.1,
          shouldLoop: false,
          colors: [Colors.amber, Colors.yellow, Colors.orange, Colors.red],
          createParticlePath: (size) {
            final path = Path();
            final w = size.width;
            final h = size.height;
            path.moveTo(w * 0.5, 0);
            path.lineTo(w * 0.8, h * 0.3);
            path.lineTo(w * 0.5, h);
            path.lineTo(w * 0.2, h * 0.3);
            path.close();
            return path;
          },
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _themes[_currentTheme][0],
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _themes[_currentTheme],
              ),
            ),
          ),

          ..._themes[_currentTheme].asMap().entries.map((entry) {
            return _buildFloatingParticle(
              8 + (entry.key * 4).toDouble(),
              entry.value,
              entry.key * pi / 3,
            );
          }),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '✨ Epic Habits',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().shimmer(duration: 3000.ms),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.palette, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _currentTheme = (_currentTheme + 1) % _themes.length;
                              });
                              HapticFeedback.selectionClick();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                            onPressed: () {
                              _showAddHabitDialog();
                              HapticFeedback.lightImpact();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                _buildStatsOverview(),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: _habits.length,
                    itemBuilder: (context, index) {
                      return _buildHabitCard(_habits[index]);
                    },
                  ),
                ),
              ],
            ),
          ),

          ..._buildConfettiWidgets(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddHabitDialog();
          HapticFeedback.mediumImpact();
        },
        backgroundColor: _themes[_currentTheme][1],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Habit',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ).animate()
          .scale(delay: 1000.ms)
          .shimmer(duration: 2000.ms),
    );
  }
}