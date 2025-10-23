import 'dart:async';
import 'package:flutter/material.dart';
import 'package:konfipass/designables/reset_password_dialog.dart';
import 'package:konfipass/designables/user_profile_img.dart';
import 'package:konfipass/designables/user_qr_dialog.dart';
import 'package:konfipass/models/konfipass_pdf.dart';
import 'package:konfipass/models/user.dart';
import 'package:konfipass/screens/create/create_user_screen.dart';
import 'package:konfipass/screens/overview/my_overview_screen.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:konfipass/services/user_service.dart';

class UserOverviewScreen extends StatefulWidget {
  const UserOverviewScreen({super.key});

  @override
  State<UserOverviewScreen> createState() => _UserOverviewPageState();
}

class _UserOverviewPageState extends State<UserOverviewScreen> {
  late UserService userService;

  List<User> users = [];

  List<User> filteredUsers = [];

  bool isLoading = false;
  bool _isLoadingMore = false;
  bool hasMore = true;

  int _page = 0;
  final int _limit = 20;

  String _query = '';
  String selectedCategory = "Alle";

  final ScrollController _scrollController = ScrollController();

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    userService = context.read<UserService>();
    _fetchUsers(reset: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoadingMore && hasMore) {
          _fetchUsers();
        }
      }
    });
  }

  Future<void> _fetchUsers({bool reset = false}) async {
    if (isLoading || _isLoadingMore) return;

    if (reset) {
      setState(() {
        isLoading = true;
        users.clear();
        _page = 1;
        hasMore = true;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final fetched = await userService.getUsers(
        page: _page,
        limit: _limit,
        search: _query,
      );

      setState(() {
        users.addAll(fetched);
        _page++;
        if (fetched.length < _limit) hasMore = false;
        _applyFilter();
      });
    } catch (e) {
      debugPrint("Fehler beim Laden: $e");
    } finally {
      setState(() {
        isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _query = query.trim().toLowerCase();
      });
      _fetchUsers(reset: true);
    });
  }

  void _applyFilter() {
    List<User> temp = users;

    if (selectedCategory != "Alle") {
      temp = temp.where((u) => u.role.name == selectedCategory).toList();
    }

    if (_query.isNotEmpty) {
      List<String> searchTerms = _query.split(" ");
      temp = temp.where((user) {
        final first = user.firstName.toLowerCase();
        final last = user.lastName.toLowerCase();
        final username = user.username.toLowerCase();
        return searchTerms.every(
              (term) =>
          first.contains(term) ||
              last.contains(term) ||
              username.contains(term),
        );
      }).toList();
    }

    setState(() {
      filteredUsers = temp;
    });
  }

  void showQrCode(User user) {
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        builder: (ctx) => UserQrDialog(user: user, pdfDownload: true),
      );
    });
  }

  void confirmDelete(User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Benutzer löschen"),
        content: Text(
          "Sind Sie sicher, dass Sie den Benutzer '${user.username}' löschen möchten?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Abbrechen"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              removeUser(user.id);
            },
            child: const Text("Löschen"),
          ),
        ],
      ),
    );
  }

  Future<void> confirmResetPassword(User user) async {
    final newPassword = await showDialog<String>(
      context: context,
      builder: (context) => ResetPasswordDialog(user: user),
    );

    if (newPassword == null) return;

    print("Neues Passwort für ${user.username}: $newPassword");
  }

  void removeUser(int userId) {
    userService.removeUser(userId);
    setState(() {
      users.removeWhere((u) => u.id == userId);
      filteredUsers = users;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Benutzer gelöscht")));
  }

  void resetPassword(int userId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Passwort wurde zurückgesetzt")),
    );
  }

  int? _sortColumnIndex;
  bool _sortAscending = true;

  void _sort<T>(Comparable<T> Function(User u) getField, int columnIndex, bool ascending) {
    filteredUsers.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      return ascending ? Comparable.compare(aValue, bValue) : Comparable.compare(bValue, aValue);
    });

    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin - Benutzerverwaltung")),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SearchBar(
              hintText: "Suchen...",
              onChanged: _onSearchChanged,
              leading: const Icon(Icons.search),
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator()),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: filteredUsers.isEmpty && !isLoading
                ? const Center(child: Text("Keine Benutzer vorhanden"))
                : Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    columns: [
                      const DataColumn(label: Text("Profilbild")),
                      DataColumn(
                        label: const Text("ID"),
                        numeric: true,
                        onSort: (colIndex, asc) => _sort((u) => u.id, colIndex, asc),
                      ),
                      DataColumn(
                        label: const Text("Vorname"),
                        onSort: (colIndex, asc) => _sort((u) => u.firstName.toLowerCase(), colIndex, asc),
                      ),
                      DataColumn(
                        label: const Text("Nachname"),
                        onSort: (colIndex, asc) => _sort((u) => u.lastName.toLowerCase(), colIndex, asc),
                      ),
                      DataColumn(
                        label: const Text("Username"),
                        onSort: (colIndex, asc) => _sort((u) => u.username.toLowerCase(), colIndex, asc),
                      ),
                      DataColumn(
                        label: const Text("Rolle"),
                        onSort: (colIndex, asc) => _sort((u) => u.role.name, colIndex, asc),
                      ),
                      const DataColumn(label: Text("Aktionen")),
                    ],
                    rows: filteredUsers.map((user) {
                      return DataRow(
                        cells: [
                          DataCell(UserProfileImg(user: user)),
                          DataCell(Text(user.id.toString())),
                          DataCell(Text(user.firstName)),
                          DataCell(Text(user.lastName)),
                          DataCell(Text(user.username)),
                          DataCell(Text(user.role.name)),
                          DataCell(
                            Wrap(
                              children: [
                                IconButton(icon: const Icon(Icons.info_outline), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MyOverviewScreen(user: user)))),
                                IconButton(icon: const Icon(Icons.qr_code), onPressed: () => showQrCode(user)),
                                IconButton(icon: const Icon(Icons.lock_reset), onPressed: () => confirmResetPassword(user)),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => confirmDelete(user)),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => CreateUserPage()));
        },
        label: const Text("Benutzer hinzufügen"),
        icon: const Icon(Icons.person_add_alt_1_rounded),
      ),
    );
  }
}