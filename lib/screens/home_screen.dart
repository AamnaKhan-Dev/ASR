import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../services/voice_assistant_service.dart';
import '../models/task.dart';
import '../main.dart';
import '../widgets/task_card.dart';
import '../widgets/energy_level_selector.dart';
import '../widgets/quick_stats_card.dart';
import 'voice_assistant_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _motivationController;
  late Animation<double> _motivationAnimation;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeAssistant();
  }

  void _setupAnimations() {
    _motivationController = AnimationController(
      duration: ADHDAnimations.longDuration,
      vsync: this,
    );
    _motivationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _motivationController,
      curve: ADHDAnimations.easeInOut,
    ));
  }

  Future<void> _initializeAssistant() async {
    final assistant = Provider.of<VoiceAssistantService>(context, listen: false);
    if (!assistant.isInitialized) {
      final success = await assistant.initialize();
      if (success) {
        setState(() {
          _isInitialized = true;
        });
        _motivationController.forward();
      }
    } else {
      setState(() {
        _isInitialized = true;
      });
      _motivationController.forward();
    }
  }

  @override
  void dispose() {
    _motivationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ADHDAppTheme.lightBackground,
      appBar: _buildAppBar(),
      body: _isInitialized ? _buildBody() : _buildLoadingScreen(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('ADHD Voice Assistant'),
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            // Navigate to settings
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Consumer<VoiceAssistantService>(
      builder: (context, assistant, child) {
        return RefreshIndicator(
          onRefresh: () async {
            // Refresh tasks
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(ADHDConstants.spacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(assistant),
                const SizedBox(height: ADHDConstants.spacing),
                _buildEnergyLevelSection(assistant),
                const SizedBox(height: ADHDConstants.spacing),
                _buildQuickStatsSection(assistant),
                const SizedBox(height: ADHDConstants.spacing),
                _buildOptimalTasksSection(assistant),
                const SizedBox(height: ADHDConstants.spacing),
                _buildQuickTasksSection(assistant),
                const SizedBox(height: ADHDConstants.largeSpacing),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: ADHDConstants.spacing),
          Text(
            'Initializing your ADHD-friendly assistant...',
            style: TextStyle(fontSize: ADHDConstants.subtitleSize),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(VoiceAssistantService assistant) {
    final timeOfDay = DateTime.now().hour;
    String greeting;
    String emoji;
    
    if (timeOfDay < 12) {
      greeting = 'Good morning';
      emoji = '🌅';
    } else if (timeOfDay < 17) {
      greeting = 'Good afternoon';
      emoji = '☀️';
    } else {
      greeting = 'Good evening';
      emoji = '🌙';
    }

    return FadeTransition(
      opacity: _motivationAnimation,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(ADHDConstants.spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: ADHDConstants.smallSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting!',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const Text(
                          'Ready to tackle your tasks with voice commands?',
                          style: TextStyle(
                            fontSize: ADHDConstants.bodySize,
                            color: ADHDAppTheme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ADHDConstants.spacing),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VoiceAssistantScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.mic),
                      label: const Text('Start Voice Assistant'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ADHDAppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnergyLevelSection(VoiceAssistantService assistant) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(_motivationAnimation),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(ADHDConstants.spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.battery_charging_full,
                    color: ADHDAppTheme.accentGreen,
                  ),
                  const SizedBox(width: ADHDConstants.smallSpacing),
                  Text(
                    'Energy Level',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: ADHDConstants.spacing),
              EnergyLevelSelector(
                currentLevel: assistant.currentEnergyLevel,
                onLevelChanged: (level) {
                  assistant.setEnergyLevel(level);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsSection(VoiceAssistantService assistant) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(_motivationAnimation),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(ADHDConstants.spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.analytics,
                    color: ADHDAppTheme.achievementGold,
                  ),
                  const SizedBox(width: ADHDConstants.smallSpacing),
                  Text(
                    'Today\'s Progress',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: ADHDConstants.spacing),
              QuickStatsCard(
                completedTasks: assistant.tasksCompletedToday,
                totalTasks: assistant.tasksCompletedToday + 3, // Mock pending tasks
                streakDays: 5, // Mock streak
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptimalTasksSection(VoiceAssistantService assistant) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.7),
        end: Offset.zero,
      ).animate(_motivationAnimation),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(ADHDConstants.spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.lightbulb,
                    color: ADHDAppTheme.motivationGreen,
                  ),
                  const SizedBox(width: ADHDConstants.smallSpacing),
                  Text(
                    'Optimal for You Right Now',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: ADHDConstants.spacing),
              FutureBuilder<List<Task>>(
                future: assistant.getOptimalTasks(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyTasksMessage(
                      'No optimal tasks found',
                      'Try adjusting your energy level or creating new tasks',
                    );
                  }
                  
                  return Column(
                    children: snapshot.data!.take(3).map((task) {
                      return TaskCard(
                        task: task,
                        onTap: () {
                          // Handle task tap
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTasksSection(VoiceAssistantService assistant) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.9),
        end: Offset.zero,
      ).animate(_motivationAnimation),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(ADHDConstants.spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.flash_on,
                    color: ADHDAppTheme.achievementGold,
                  ),
                  const SizedBox(width: ADHDConstants.smallSpacing),
                  Text(
                    'Quick Tasks (15 min or less)',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: ADHDConstants.spacing),
              FutureBuilder<List<Task>>(
                future: assistant.getQuickTasks(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyTasksMessage(
                      'No quick tasks found',
                      'Create some short tasks to build momentum',
                    );
                  }
                  
                  return Column(
                    children: snapshot.data!.take(3).map((task) {
                      return TaskCard(
                        task: task,
                        onTap: () {
                          // Handle task tap
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTasksMessage(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(ADHDConstants.spacing),
      child: Column(
        children: [
          const Icon(
            Icons.task_alt,
            size: 48,
            color: ADHDAppTheme.neutralGray,
          ),
          const SizedBox(height: ADHDConstants.smallSpacing),
          Text(
            title,
            style: const TextStyle(
              fontSize: ADHDConstants.subtitleSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ADHDConstants.smallSpacing),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: ADHDConstants.bodySize,
              color: ADHDAppTheme.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Consumer<VoiceAssistantService>(
      builder: (context, assistant, child) {
        return FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const VoiceAssistantScreen(),
              ),
            );
          },
          icon: Icon(
            assistant.isListening ? Icons.mic : Icons.mic_none,
            color: Colors.white,
          ),
          label: Text(
            assistant.isListening ? 'Listening...' : 'Voice Assistant',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: assistant.isListening
              ? ADHDAppTheme.accentGreen
              : ADHDAppTheme.primaryBlue,
        );
      },
    );
  }
}