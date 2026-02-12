import 'package:flutter/material.dart';

class QuestsSkeleton extends StatelessWidget {
  const QuestsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget box(double height, {double? width, double radius = 10}) {
      return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Row(
          children: [
            box(26, width: 110),
            const Spacer(),
            box(36, width: 36, radius: 12),
            const SizedBox(width: 8),
            box(36, width: 36, radius: 12),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(5, (_) => box(34, width: 92, radius: 18)),
        ),
        const SizedBox(height: 12),
        box(54, width: double.infinity, radius: 16),
        const SizedBox(height: 10),
        Row(
          children: List.generate(
            5,
            (i) => Padding(
              padding: EdgeInsets.only(right: i == 4 ? 0 : 8),
              child: box(34, width: 92, radius: 18),
            ),
          ),
        ),
        const SizedBox(height: 14),
        ...List.generate(
          5,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: i == 4 ? 0 : 10),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    box(72, width: 4, radius: 6),
                    const SizedBox(width: 10),
                    box(42, width: 42, radius: 10),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          box(16, width: 160),
                          const SizedBox(height: 8),
                          box(12, width: 180),
                          const SizedBox(height: 6),
                          box(12, width: 120),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        box(22, width: 70, radius: 999),
                        const SizedBox(height: 8),
                        box(28, width: 28, radius: 14),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
