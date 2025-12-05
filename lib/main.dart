import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:priyanakaenterprises/screens/auth_gate.dart';
import 'package:priyanakaenterprises/services/auth_provider.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
      ],
      child: const PriyankaApp(),
    ),
  );
}

class PriyankaApp extends StatelessWidget {
  const PriyankaApp({super.key});

  // Define the Corporate Palette here for easy reference
  static const Color _navyPrimary = Color(0xFF0D47A1); // Deep Banking Navy
  static const Color _goldAccent = Color(0xFFFFA000);  // Premium Gold

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Priyanka Enterprises',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        
        // 1. COLOR SCHEME: Switch from Purple to Navy/Gold
        colorScheme: ColorScheme.fromSeed(
          seedColor: _navyPrimary,
          brightness: Brightness.light,
          primary: _navyPrimary,
          secondary: _goldAccent,
          surface: Colors.white,
        ),
        
        // 2. BACKGROUND: Professional slate/grey tone
        scaffoldBackgroundColor: Colors.blueGrey[50],
        primaryColor: _navyPrimary,

        // 3. TYPOGRAPHY & SELECTION
        // Make the cursor and text selection Gold (Premium feel)
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: _goldAccent,
          selectionColor: _goldAccent.withOpacity(0.3),
          selectionHandleColor: _goldAccent,
        ),

        // 4. APP BAR: Classic Corporate Navy
        appBarTheme: const AppBarTheme(
          backgroundColor: _navyPrimary,
          foregroundColor: Colors.white, // White text/icons on Navy
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Colors.white),
        ),

        // 5. BUTTONS: Rectangular, Navy, Gold Text/Icon support
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _navyPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6), // Sharper corners (Corporate)
            ),
            elevation: 2,
          ),
        ),

        // 6. INPUT FIELDS: Clean, sharp, Gold focus border
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          // Default Border (Grey)
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6), // Sharper corners
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          // Focus Border -> GOLD (Premium interaction)
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: _goldAccent, width: 2),
          ),
          // Error styling
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.red[700]!, width: 1.5),
          ),
          // Text Colors
          labelStyle: TextStyle(color: Colors.grey[700]),
          floatingLabelStyle: const TextStyle(color: _navyPrimary, fontWeight: FontWeight.bold),
          prefixIconColor: Colors.grey[600], // Default icon color
        ),

        // 7. CARDS: Cleaner, sharper
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Sharper than the previous 16
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        ),
        
        // 8. FAB (Floating Action Button) - Make it Gold for high visibility
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _goldAccent,
          foregroundColor: Colors.white,
        ),
      ),
      home: const AuthGate(),
    );
  }
}