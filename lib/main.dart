import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:re_mind/firebase_options.dart';
import 'package:re_mind/services/auth/i_auth_service.dart';
import 'package:re_mind/services/auth/firebase_auth_service.dart';
import 'package:re_mind/services/user_service.dart';
import 'package:re_mind/services/deepseek_service.dart';
import 'package:re_mind/ui/themes/theme_config.dart';
import 'package:re_mind/ui/view/app_wrapper.dart';
import 'package:re_mind/viewmodels/auth_view_model.dart';
import 'package:re_mind/viewmodels/login_view_model.dart';
import 'package:re_mind/viewmodels/navigation_view_model.dart';
import 'package:re_mind/viewmodels/on_boarding_viewmodel.dart';
import 'package:re_mind/viewmodels/chat_view_model.dart';
import 'package:re_mind/viewmodels/user_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:re_mind/viewmodels/tips_view_model.dart';
Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
  bool useSystemTheme = prefs.getBool('useSystemTheme') ?? true;
  bool isDarkMode = prefs.getBool('isDarkMode') ?? false;
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  
  runApp(MainApp(
    hasSeenOnboarding: hasSeenOnboarding,
    useSystemTheme: useSystemTheme,
    isDarkMode: isDarkMode,
  ));
}

class MainApp extends StatefulWidget {
  const MainApp({
    super.key, 
    required this.hasSeenOnboarding,
    required this.useSystemTheme,
    required this.isDarkMode,
  });
  
  final bool hasSeenOnboarding;
  final bool useSystemTheme;
  final bool isDarkMode;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late bool _useSystemTheme;
  late bool _isDarkMode;
  
  @override
  void initState() {
    
    super.initState();
    initializeSplash();
    _useSystemTheme = widget.useSystemTheme;
    _isDarkMode = widget.isDarkMode;
  }
  void initializeSplash() async{
    await Future.delayed(const Duration(seconds: 2));
    FlutterNativeSplash.remove();
  }

  void toggleTheme() async {
    setState(() {
      _useSystemTheme = false;
      _isDarkMode = !_isDarkMode;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useSystemTheme', _useSystemTheme);
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  void useSystemTheme() async {
    setState(() {
      _useSystemTheme = true;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useSystemTheme', _useSystemTheme);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserViewModel>(
          create: (_) => UserViewModel(),
        ),
        Provider<IAuthService>(
          create: (_) => FirebaseAuthService(),
        ),
        Provider<UserService>(
          create: (_) => UserService(),
        ),
        Provider<DeepSeekService>(
          create: (_) => DeepSeekService(),
        ),
        ChangeNotifierProvider(create: (context) => OnBoardingViewmodel()),
        ChangeNotifierProvider(
          create: (context) => AuthViewModel(
            context.read<IAuthService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => LoginViewModel(
            context.read<IAuthService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => NavigationViewModel(),
        ),
        ChangeNotifierProvider(
          create: (context) => ChatViewModel(
            context.read<DeepSeekService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => TipsViewModel()..loadTips(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: Themes.lightTheme,
        darkTheme: Themes.darkTheme,
        themeMode: _useSystemTheme ? ThemeMode.system : (_isDarkMode ? ThemeMode.dark : ThemeMode.light),
        title: 'ReMind',
        home: const AppWrapper(),
      ),
    );
  }
}
