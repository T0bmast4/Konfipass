import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:konfipass/providers/auth_provider.dart';
import 'package:konfipass/screens/login/login_screen.dart';
import 'package:provider/provider.dart';

class KonfipassAppbar extends StatelessWidget {
  final GlobalKey<NavigatorState> innerNavigatorKey;

  const KonfipassAppbar({super.key, required this.innerNavigatorKey});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return AppBar(
      elevation: 16,
      shadowColor: Colors.black.withOpacity(0.5),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      title: const Text("Konfipass"),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: PopupMenuButton<int>(
            offset: const Offset(0, 50),
            onSelected: (value) {
              switch (value) {
                case 1:
                  final user = auth.user;
                  if (user != null) {
                    innerNavigatorKey.currentState?.pushNamed(
                      '/profileSettings',
                      arguments: user,
                    );
                  }
                  break;
                case 2:
                // Ausloggen
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Ausloggen"),
                      content: const Text("Willst du dich wirklich ausloggen?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Abbrechen"),
                        ),
                        TextButton(
                          onPressed: () {
                            auth.logout();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => LoginScreen()),
                                  (route) => false,
                            );
                          },
                          child: const Text(
                            "Ausloggen",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 1,
                child: Text("Profil Einstellungen"),
              ),
              PopupMenuItem(
                value: 2,
                child: Text("Ausloggen"),
              ),
            ],
            child: Row(
              children: [
                const Icon(Icons.account_circle, size: 32),
                const SizedBox(width: 8),
                Text("${auth.username}", style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
