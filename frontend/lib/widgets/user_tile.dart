import 'package:flutter/material.dart';

import '../models/user.dart';
import '../theme.dart';
import 'common.dart';

class UserTile extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const UserTile({super.key, required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.outline),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Avatar(name: user.displayName, size: 48, heroTag: 'avatar-${user.id}'),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(user.displayName,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
