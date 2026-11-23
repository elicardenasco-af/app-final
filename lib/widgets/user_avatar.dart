import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../core/theme.dart';
import '../models/user.dart';

/// Avatar del usuario: foto si existe, si no sus iniciales.
class UserAvatar extends StatelessWidget {
  final User? user;
  final double radius;

  const UserAvatar({super.key, required this.user, this.radius = 32});

  @override
  Widget build(BuildContext context) {
    final url = user?.avatarUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.accent,
      foregroundImage: url != null ? NetworkImage(ApiConfig.resolveUrl(url)) : null,
      child: Text(
        user?.initials ?? '',
        style: TextStyle(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
