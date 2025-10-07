import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:konfipass/designables/user_create_dialog.dart';
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:konfipass/models/user.dart';
import 'package:konfipass/services/user_service.dart';
import 'package:provider/provider.dart';

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final _formKey = GlobalKey<FormState>();

  String vorname = "";
  String nachname = "";
  String username = "";
  String password = "";
  UserRole selectedRole = UserRole.user;

  PlatformFile? pickedFile;

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null) {
      setState(() {
        pickedFile = result.files.first;
      });
    }
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    html.File? webFile;

    if (pickedFile != null) {
      final bytes = pickedFile!.bytes;
      if (bytes != null) {
        webFile = html.File([bytes], pickedFile!.name);
      }
    }

    final result = await context.read<UserService>().createUserWithFile(
      vorname,
      nachname,
      selectedRole,
      webFile,
    );

    if (result != null) {
      final uuid = result['uuid'];
      final username = result['username'];
      final password = result['password'];
      final profileImageUrl = result['profileImageUrl'];

      if(uuid != null || username != null || password != null) {
        if(profileImageUrl.toString().contains("uploads/")) {
          showDialog(context: context, builder: (context) => UserCreateDialog(firstName: vorname, lastName: nachname, username: username, password: password, profileImageUrl: profileImageUrl, uuid: uuid));
        }else{
          showDialog(context: context, builder: (context) => UserCreateDialog(firstName: vorname, lastName: nachname, username: username, password: password, profileImageUrl: "", uuid: uuid));
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User erfolgreich erstellt!")),
        );
      }else{
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fehler beim Erstellen des Users")),
        );
      }

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fehler beim Erstellen des Users")),
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Benutzer erstellen")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Vorname*',
                  border: OutlineInputBorder(),
                ),
                onSaved: (v) => vorname = v ?? "",
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nachname*',
                  border: OutlineInputBorder(),
                ),
                onSaved: (v) => nachname = v ?? "",
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Rolle',
                  border: OutlineInputBorder(),
                ),
                items: UserRole.values.map((role) {
                  return DropdownMenuItem<UserRole>(
                    value: role,
                    child: Text(role.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                  });
                },
                validator: (value) =>
                value == null ? "Bitte eine Rolle auswählen" : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: pickFile,
                icon: const Icon(Icons.upload_file),
                label: Text(pickedFile == null
                    ? "Datei auswählen"
                    : "Ausgewählt: ${pickedFile!.name}"),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: submit,
                child: const Text("Erstellen"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
