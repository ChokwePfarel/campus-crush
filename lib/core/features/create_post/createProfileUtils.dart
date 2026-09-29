
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../constants/post_constants.dart';
import '../../utils/screen_size.dart';

class LocationPickerSheet extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelected;

  const LocationPickerSheet({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final grouped = LocationTags.grouped;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(SizeConfig.widthPercent(6))),
      ),
      constraints: BoxConstraints(
        maxHeight: SizeConfig.heightPercent(75),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: EdgeInsets.only(
                  top: SizeConfig.heightPercent(1.5),
                  bottom: SizeConfig.heightPercent(1)),
              width: SizeConfig.widthPercent(9),
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDE8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                SizeConfig.widthPercent(5),
                SizeConfig.heightPercent(0.5),
                SizeConfig.widthPercent(5),
                SizeConfig.heightPercent(1.5)),
            child: Row(
              children: [
                Text('📍',
                    style: TextStyle(fontSize: SizeConfig.widthPercent(5.5))),
                SizedBox(width: SizeConfig.widthPercent(2.5)),
                Text(
                  'Where are you right now?',
                  style: TextStyle(
                    fontSize: SizeConfig.widthPercent(4.5),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8E8F0)),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(bottom: SizeConfig.heightPercent(3)),
              children: grouped.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          SizeConfig.widthPercent(5),
                          SizeConfig.heightPercent(2.5),
                          SizeConfig.widthPercent(5),
                          SizeConfig.heightPercent(1)),
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: SizeConfig.widthPercent(3),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF8E8E9A),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    ...entry.value.map((tag) {
                      final isSelected = selected == tag['label'];
                      return GestureDetector(
                        onTap: () => onSelected(tag['label']!),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: EdgeInsets.symmetric(
                              horizontal: SizeConfig.widthPercent(4),
                              vertical: SizeConfig.heightPercent(0.4)),
                          padding: EdgeInsets.symmetric(
                              horizontal: SizeConfig.widthPercent(4),
                              vertical: SizeConfig.heightPercent(1.5)),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2EC4B6).withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(
                                SizeConfig.widthPercent(3.5)),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2EC4B6)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(tag['icon']!,
                                  style: TextStyle(
                                      fontSize: SizeConfig.widthPercent(5))),
                              SizedBox(width: SizeConfig.widthPercent(3)),
                              Text(
                                tag['label']!,
                                style: TextStyle(
                                  fontSize: SizeConfig.widthPercent(3.8),
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFF2EC4B6)
                                      : const Color(0xFF1A1A2E),
                                ),
                              ),
                              const Spacer(),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: const Color(0xFF2EC4B6),
                                  size: SizeConfig.widthPercent(5),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Background Colour Picker Sheet ──────────────────────────────────────────

class BgColorPickerSheet extends StatelessWidget {
  final Color? selected;
  final ValueChanged<Color?> onSelected;

  const BgColorPickerSheet({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          SizeConfig.widthPercent(5),
          SizeConfig.heightPercent(2),
          SizeConfig.widthPercent(5),
          SizeConfig.heightPercent(4)),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: SizeConfig.widthPercent(9),
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDE8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: SizeConfig.heightPercent(2)),
          Text(
            'Card Background',
            style: TextStyle(
              fontSize: SizeConfig.widthPercent(4.5),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          SizedBox(height: SizeConfig.heightPercent(2)),
          Wrap(
            spacing: SizeConfig.widthPercent(3),
            runSpacing: SizeConfig.widthPercent(3),
            children: postBgColors.map((color) {
              final isSelected = color == selected;
              final isNone = color == null;
              return GestureDetector(
                onTap: () => onSelected(color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: SizeConfig.widthPercent(12),
                  height: SizeConfig.widthPercent(12),
                  decoration: BoxDecoration(
                    color: isNone ? Colors.white : color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1A1A2E)
                          : const Color(0xFFE8E8F0),
                      width: isSelected ? 2.5 : 1.5,
                    ),
                  ),
                  child: isNone
                      ? Center(
                    child: Icon(
                      Icons.block_rounded,
                      size: SizeConfig.widthPercent(5),
                      color: Colors.grey,
                    ),
                  )
                      : isSelected
                      ? Center(
                    child: Icon(
                      Icons.check_rounded,
                      size: SizeConfig.widthPercent(5),
                      color: Colors.black54,
                    ),
                  )
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
