import 'package:flutter/material.dart';
import 'package:konfipass/models/user.dart';
import 'package:konfipass/services/user_service.dart';
import 'package:provider/provider.dart';

class UserDetailScreen extends StatefulWidget {
  final User user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late User user;

  @override
  void initState() {
    super.initState();
    user = widget.user;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Benutzerdetails"),
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 8,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar + Name + Rolle (unverändert)
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.purple.shade200,
                backgroundImage: user.profileImgPath != null &&
                    user.profileImgPath!.isNotEmpty
                    ? NetworkImage(user.profileImgPath!)
                    : null,
                child: (user.profileImgPath == null ||
                    user.profileImgPath!.isEmpty)
                    ? Text(
                  "${user.firstName[0].toUpperCase()}${user.lastName.isNotEmpty ? user.lastName[0].toUpperCase() : ''}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "${user.firstName} ${user.lastName}",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Chip(
              label: Text(
                user.role == UserRole.admin ? "Administrator" : "Benutzer",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor:
              user.role == UserRole.admin ? Colors.redAccent : Colors.green,
            ),
            const SizedBox(height: 30),

            // Benutzername-InfoCard
            _infoCard(
              icon: Icons.person_outline,
              label: "Benutzername",
              value: user.username,
              onEdit: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    String? errorText;
                    final TextEditingController controller = TextEditingController(text: user.username);

                    return StatefulBuilder(
                      builder: (context, setStateDialog) {
                        return AlertDialog(
                          title: const Text("Benutzername bearbeiten"),
                          content: TextField(
                            controller: controller, // nur einmal zugewiesen
                            decoration: InputDecoration(
                              labelText: "Benutzername",
                              errorText: errorText,
                            ),
                            onChanged: (val) {
                              setStateDialog(() {
                                errorText = null;
                              });
                            },
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Abbrechen"),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final newUsername = controller.text;
                                final error = await context
                                    .read<UserService>()
                                    .updateUsername(newUsername: newUsername);
                                if (error != null) {
                                  setStateDialog(() {
                                    errorText = error;
                                  });
                                } else {
                                  setState(() {
                                    user = user.copyWith(username: newUsername);
                                  });
                                  Navigator.pop(context);
                                }
                              },
                              child: const Text("Speichern"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),

            // Passwort ändern InfoCard
            _infoCard(
              icon: Icons.lock_outline,
              label: "Passwort ändern",
              value: "********",
              onEdit: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    String newPassword = "";
                    String confirmPassword = "";
                    String? newPasswordError;
                    String? confirmPasswordError;

                    return StatefulBuilder(
                      builder: (context, setStateDialog) {
                        return AlertDialog(
                          title: const Text("Passwort ändern"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: "Neues Passwort",
                                  errorText: newPasswordError,
                                ),
                                onChanged: (val) {
                                  setStateDialog(() {
                                    newPassword = val;
                                    newPasswordError = null;
                                  });
                                },
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: "Passwort bestätigen",
                                  errorText: confirmPasswordError,
                                ),
                                onChanged: (val) {
                                  setStateDialog(() {
                                    confirmPassword = val;
                                    confirmPasswordError = null;
                                  });
                                },
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Abbrechen"),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                bool hasError = false;

                                setStateDialog(() {
                                  if (newPassword.isEmpty) {
                                    newPasswordError = "Bitte neues Passwort eingeben";
                                    hasError = true;
                                  }
                                  if (confirmPassword.isEmpty) {
                                    confirmPasswordError = "Bitte Passwort bestätigen";
                                    hasError = true;
                                  }
                                  if (newPassword.isNotEmpty &&
                                      confirmPassword.isNotEmpty &&
                                      newPassword != confirmPassword) {
                                    confirmPasswordError = "Passwörter stimmen nicht überein";
                                    hasError = true;
                                  }
                                });

                                if (!hasError) {
                                  final error = await context
                                      .read<UserService>()
                                      .updatePassword(newPassword: newPassword);
                                  if (error != null) {
                                    // Zeige Fehlermeldung vom Server unter dem entsprechenden Feld
                                    setStateDialog(() {
                                      newPasswordError = error;
                                    });
                                  } else {
                                    Navigator.pop(context); // schließen, wenn erfolgreich
                                  }
                                }
                              },
                              child: const Text("Speichern"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),

            _infoCard(
              icon: Icons.badge_outlined,
              label: "ID",
              value: user.id.toString(),
            ),
            _infoCard(
              icon: Icons.fingerprint,
              label: "UUID",
              value: user.uuid,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onEdit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54, size: 26),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueAccent),
              onPressed: onEdit,
            ),
        ],
      ),
    );
  }
}
