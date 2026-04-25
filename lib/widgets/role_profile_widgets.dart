import 'package:flutter/material.dart';

class RoleProfileCard extends StatelessWidget {
  const RoleProfileCard({
    super.key,
    required this.name,
    required this.role,
    this.subtitle,
  });

  final String name;
  final String role;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            child: Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: TextStyle(
                    color: textColor?.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor?.withValues(alpha: 0.75),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardStatGrid extends StatelessWidget {
  const DashboardStatGrid({super.key, required this.items});

  final List<DashboardStatItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        if (isWide && items.length >= 4) {
          return Row(
            children: List.generate(items.length, (index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == items.length - 1 ? 0 : 10,
                  ),
                  child: _DashboardStatBox(item: items[index]),
                ),
              );
            }),
          );
        }

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map(
                (item) => SizedBox(
                  width: 220,
                  child: _DashboardStatBox(item: item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class DashboardStatItem {
  const DashboardStatItem({
    required this.title,
    required this.value,
    this.accentColor,
  });

  final String title;
  final String value;
  final Color? accentColor;
}

class _DashboardStatBox extends StatelessWidget {
  const _DashboardStatBox({required this.item});

  final DashboardStatItem item;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final accent = item.accentColor ?? Theme.of(context).colorScheme.primary;
    final background = accent.withValues(alpha: 0.1);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        children: [
          Text(
            item.value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            style: TextStyle(
              color: textColor?.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class RoleProfilePage extends StatelessWidget {
  const RoleProfilePage({
    super.key,
    required this.name,
    required this.role,
    required this.department,
    required this.onLogout,
  });

  final String name;
  final String role;
  final String department;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 30,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                role,
                style: TextStyle(color: textColor?.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _infoCard(
          context,
          [
            ('Name', name),
            ('Role', role),
            ('Department', department),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: onLogout,
          ),
        ),
      ],
    );
  }

  Widget _infoCard(BuildContext context, List<(String, String)> rows) {
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        children: List.generate(
          rows.length,
          (i) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      rows[i].$1,
                      style: TextStyle(color: textColor?.withValues(alpha: 0.7)),
                    ),
                    Text(
                      rows[i].$2,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < rows.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          ),
        ),
      ),
    );
  }
}
