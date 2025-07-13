import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'services/voice_assistant_service.dart';
import 'screens/home_screen.dart';
import 'screens/voice_assistant_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const ADHDVoiceAssistantApp());
}

class ADHDVoiceAssistantApp extends StatelessWidget {
  const ADHDVoiceAssistantApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => VoiceAssistantService(),
        ),
      ],
      child: MaterialApp(
        title: 'ADHD Voice Assistant',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          
          // ADHD-friendly color scheme
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          
          // Typography optimized for ADHD
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            headlineMedium: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              letterSpacing: 0.2,
              height: 1.5,
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              letterSpacing: 0.1,
              height: 1.4,
            ),
          ),
          
          // Button themes
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // Card theme
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(8),
          ),
          
          // App bar theme
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        
        routes: {
          '/': (context) => const HomeScreen(),
          '/voice': (context) => const VoiceAssistantScreen(),
        },
        
        initialRoute: '/',
      ),
    );
  }
}

class ADHDAppTheme {
  // ADHD-friendly color palette
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);
  static const Color neutralGray = Color(0xFF9E9E9E);
  
  // Task category colors
  static const Color workColor = Color(0xFF2196F3);
  static const Color personalColor = Color(0xFF4CAF50);
  static const Color healthColor = Color(0xFFF44336);
  static const Color learningColor = Color(0xFF9C27B0);
  static const Color socialColor = Color(0xFF00BCD4);
  static const Color creativeColor = Color(0xFFE91E63);
  static const Color maintenanceColor = Color(0xFF795548);
  static const Color urgentColor = Color(0xFFFF5722);
  
  // Priority colors
  static const Color lowPriority = Color(0xFF4CAF50);
  static const Color mediumPriority = Color(0xFFFF9800);
  static const Color highPriority = Color(0xFFFF5722);
  static const Color urgentPriority = Color(0xFFF44336);
  
  // Dopamine-boosting colors
  static const Color motivationGreen = Color(0xFF8BC34A);
  static const Color achievementGold = Color(0xFFFFC107);
  static const Color celebrationPurple = Color(0xFF9C27B0);
  
  // Background colors
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color darkBackground = Color(0xFF121212);
  
  // Text colors
  static const Color primaryText = Color(0xFF212121);
  static const Color secondaryText = Color(0xFF757575);
  static const Color hintText = Color(0xFFBDBDBD);
  
  // Get color for task category
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return workColor;
      case 'personal':
        return personalColor;
      case 'health':
        return healthColor;
      case 'learning':
        return learningColor;
      case 'social':
        return socialColor;
      case 'creative':
        return creativeColor;
      case 'maintenance':
        return maintenanceColor;
      case 'urgent':
        return urgentColor;
      default:
        return neutralGray;
    }
  }
  
  // Get color for task priority
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return lowPriority;
      case 'medium':
        return mediumPriority;
      case 'high':
        return highPriority;
      case 'urgent':
        return urgentPriority;
      default:
        return mediumPriority;
    }
  }
  
  // Get motivation color based on dopamine score
  static Color getMotivationColor(double dopamineScore) {
    if (dopamineScore >= 0.8) {
      return celebrationPurple;
    } else if (dopamineScore >= 0.6) {
      return achievementGold;
    } else if (dopamineScore >= 0.4) {
      return motivationGreen;
    } else {
      return neutralGray;
    }
  }
}

// Custom animations for ADHD-friendly UX
class ADHDAnimations {
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration longDuration = Duration(milliseconds: 500);
  
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve bounceIn = Curves.bounceIn;
  static const Curve elasticOut = Curves.elasticOut;
}

// Constants for ADHD-optimized UI
class ADHDConstants {
  static const double borderRadius = 16.0;
  static const double cardElevation = 2.0;
  static const double buttonHeight = 56.0;
  static const double iconSize = 24.0;
  static const double spacing = 16.0;
  static const double smallSpacing = 8.0;
  static const double largeSpacing = 32.0;
  
  // Text sizes
  static const double titleSize = 24.0;
  static const double subtitleSize = 16.0;
  static const double bodySize = 14.0;
  static const double captionSize = 12.0;
  
  // Timeouts for ADHD attention spans
  static const Duration shortAttentionSpan = Duration(seconds: 15);
  static const Duration mediumAttentionSpan = Duration(seconds: 30);
  static const Duration longAttentionSpan = Duration(minutes: 2);
}