import 'package:flutter/material.dart';

class ScheduleMask {
  static Set<int> daysFromMask(int? mask) {
    if (mask == null) {
      return <int>{0, 1, 2, 3, 4, 5, 6};
    }
    final days = <int>{};
    for (var i = 0; i < 7; i++) {
      if ((mask & (1 << i)) != 0) {
        days.add(i);
      }
    }
    return days;
  }

  static int maskFromDays(Set<int> days) {
    var mask = 0;
    for (final d in days) {
      if (d < 0 || d > 6) continue;
      mask |= 1 << d;
    }
    return mask;
  }
}

class SchedulePicker extends StatelessWidget {
  const SchedulePicker({
    super.key,
    required this.activeDays,
    required this.onChanged,
    this.compact = false,
    this.disabled = false,
  });

  final Set<int> activeDays; // 0=Mon .. 6=Sun
  final ValueChanged<Set<int>> onChanged;
  final bool compact;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final size = compact ? 28.0 : 32.0;
    final textStyle = Theme.of(context).textTheme.bodySmall;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(labels.length, (i) {
        final active = activeDays.contains(i);
        final borderColor =
            disabled ? Colors.black12 : (active ? Colors.blueAccent : Colors.black12);
        final bgColor = disabled
            ? Colors.transparent
            : (active ? Colors.blue.withValues(alpha: 0.2) : Colors.transparent);
        final labelColor =
            disabled ? Colors.black26 : (active ? Colors.blueAccent : Colors.black54);

        return Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(size / 2),
          child: InkWell(
            borderRadius: BorderRadius.circular(size / 2),
            onTap: disabled
                ? null
                : () {
                    final next = Set<int>.from(activeDays);
                    if (active) {
                      next.remove(i);
                    } else {
                      next.add(i);
                    }
                    onChanged(next);
                  },
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size / 2),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                labels[i],
                style: textStyle?.copyWith(
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  color: labelColor,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
