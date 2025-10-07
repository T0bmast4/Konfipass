import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:konfipass/models/user.dart';
import 'package:konfipass/services/user_service.dart';
import 'package:provider/provider.dart';

class ResetPasswordDialog extends StatefulWidget {
  final User user;

  const ResetPasswordDialog({super.key, required this.user});

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorText;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final newPassword = _passwordController.text.trim();

    if (newPassword.isEmpty || newPassword.length < 6) {
      setState(() {
        _errorText = "Bitte ein Passwort eingeben (mind. 6 Zeichen)";
      });
      return;
    }

    setState(() {
      _errorText = null;
    });

    final result = await context.read<UserService>().resetPassword(widget.user.id, newPassword);

    if(result) {
      print("Passwort von ${widget.user.username} geändert auf: $newPassword");

      Navigator.pop(context, newPassword);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Passwort zurücksetzen"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Neues Passwort für '${widget.user.firstName} ${widget.user.lastName}' eingeben:"),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onChanged: (_) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
            },
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: "Neues Passwort",
              errorText: _errorText,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Abbrechen"),
        ),
        ElevatedButton(
          onPressed: _resetPassword,
          child: const Text("Zurücksetzen"),
        ),
      ],
    );
  }
}
