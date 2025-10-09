import 'package:flutter/material.dart';
import 'package:konfipass/models/user.dart';

class UserProfileImg extends StatelessWidget {
  final User user;

  const UserProfileImg({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: user.profileImgPath != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      child: GestureDetector(
        onTap: () {
          if (user.profileImgPath != null) {
            showDialog(
              context: context,
              builder: (ctx) => Dialog(
                child: InteractiveViewer(
                  child: Image.network(user.profileImgPath!),
                ),
              ),
            );
          }
        },
        child: CircleAvatar(
          radius: 16,
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
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          )
              : null,
        ),
      ),
    );
  }
}
