import 'package:flutter/material.dart';
import 'package:konfipass/designables/konfipass_appbar.dart';
import 'package:konfipass/models/constants.dart';
import 'package:konfipass/models/event_args.dart';
import 'package:konfipass/providers/auth_provider.dart';
import 'package:konfipass/screens/detail/event_detail_screen.dart';
import 'package:konfipass/screens/login/login_screen.dart';
import 'package:konfipass/screens/overview/event_overview_screen.dart';
import 'package:konfipass/screens/overview/users_overview_screen.dart';
import 'package:konfipass/services/event_service.dart';
import 'package:konfipass/services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authProvider = AuthProvider();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => authProvider,
        ),
        Provider<EventService>(
          create: (_) => EventService(baseUrl: "$serverUrl/api/event", authProvider: authProvider),
        ),
        Provider<UserService>(
          create: (_) => UserService(baseUrl: "$serverUrl/api/user", authProvider: authProvider),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return MaterialApp(
      title: 'Konfipass',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      locale: const Locale('de', 'DE'),
      supportedLocales: const [
        Locale('de', 'DE'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: FutureBuilder<void>(
        future: authProvider.checkLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return authProvider.isLoggedIn ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    AppointmentScreen(),
    UserOverviewScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isExpanded = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: KonfipassAppbar(),
      ),
      body: Row(
        children: [
          NavigationRail(
            extended: isExpanded,
            labelType: isExpanded
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            selectedIndex: _selectedIndex,
            useIndicator: true,
            onDestinationSelected: (int index) {
              setState(() => _selectedIndex = index);
            },
            leading: SizedBox(height: 20),
            minWidth: 72,
            minExtendedWidth: 200,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: Text('Termine'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('Benutzer'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Navigator(
              key: GlobalKey<NavigatorState>(),
              onGenerateRoute: (settings) {
                if (settings.name == '/eventDetail') {
                  final args = settings.arguments as EventArgs;
                  return MaterialPageRoute(
                    builder: (_) => EventDetailScreen(
                      id: args.id,
                      title: args.title,
                      description: args.description,
                      dayFrom: args.dayFrom,
                      dayTo: args.dayTo,
                      month: args.month,
                      timeFrom: args.timeFrom,
                      timeTo: args.timeTo,
                      weekday: args.weekday,
                      status: args.status,
                    ),
                  );
                }
                return MaterialPageRoute(builder: (_) => _pages[_selectedIndex]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
