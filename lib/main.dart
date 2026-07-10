import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/user_model.dart';
import 'models/room_model.dart';
import 'models/game_model.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/rooms_screen.dart';
import 'screens/voice_room_screen.dart';
import 'screens/games_screen.dart';
import 'screens/avatar_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(const WePlayApp());
}

class WePlayApp extends StatelessWidget {
  const WePlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserModel()),
        ChangeNotifierProvider(create: (_) => RoomModel()),
        ChangeNotifierProvider(create: (_) => GameModel()),
      ],
      child: MaterialApp(
        title: 'WePlay Clone',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          scaffoldBackgroundColor: const Color(0xFF1A1A2E),
          colorScheme: ColorScheme.fromSwatch().copyWith(
            secondary: Colors.pinkAccent,
            surface: const Color(0xFF16213E),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1A1A2E),
            elevation: 0,
          ),
          cardTheme: CardTheme(
            color: const Color(0xFF16213E),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/rooms': (context) => const RoomsScreen(),
          '/voice-room': (context) => const VoiceRoomScreen(),
          '/games': (context) => const GamesScreen(),
          '/avatar': (context) => const AvatarScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}