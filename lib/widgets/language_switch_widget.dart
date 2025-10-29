import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/controllers/language_controller.dart';

class LanguageSwitchWidget extends StatelessWidget {
  final bool showText;
  final bool showFlag;
  final double? iconSize;
  final Color? iconColor;
  final TextStyle? textStyle;
  final EdgeInsets? padding;
  final String? tooltip;

  const LanguageSwitchWidget({
    Key? key,
    this.showText = false,
    this.showFlag = true,
    this.iconSize,
    this.iconColor,
    this.textStyle,
    this.padding,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LanguageController>(
      builder: (controller) {
        return IconButton(
          onPressed: () => controller.toggleLanguage(),
          icon: _buildIcon(controller),
          tooltip: tooltip ?? 'language'.tr,
          padding: padding ?? const EdgeInsets.all(8.0),
        );
      },
    );
  }

  Widget _buildIcon(LanguageController controller) {
    if (showText && showFlag) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showFlag) ...[
            Text(
              controller.getCurrentLanguageFlag(),
              style: TextStyle(fontSize: iconSize ?? 16),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            controller.getCurrentLanguageDisplayName(),
            style: textStyle ?? const TextStyle(fontSize: 12),
          ),
        ],
      );
    } else if (showFlag) {
      return Text(
        controller.getCurrentLanguageFlag(),
        style: TextStyle(fontSize: iconSize ?? 20, color: iconColor),
      );
    } else if (showText) {
      return Text(
        controller.getCurrentLanguageDisplayName(),
        style: textStyle ?? const TextStyle(fontSize: 12),
      );
    } else {
      // Default: Show flag with language code
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            controller.getCurrentLanguageFlag(),
            style: TextStyle(fontSize: iconSize ?? 16),
          ),
          Text(
            controller.currentLanguageCode.value.toUpperCase(),
            style: TextStyle(
              fontSize: (iconSize ?? 16) * 0.6,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }
  }
}

// Alternative compact widget for app bars
class CompactLanguageSwitchWidget extends StatelessWidget {
  final double? size;
  final Color? color;

  const CompactLanguageSwitchWidget({Key? key, this.size, this.color})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LanguageController>(
      builder: (controller) {
        return GestureDetector(
          onTap: () => controller.toggleLanguage(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: color ?? Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.getCurrentLanguageFlag(),
                  style: TextStyle(fontSize: size ?? 14),
                ),
                const SizedBox(width: 4),
                Text(
                  controller.currentLanguageCode.value.toUpperCase(),
                  style: TextStyle(
                    fontSize: (size ?? 14) * 0.7,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Language selection dropdown widget
class LanguageDropdownWidget extends StatelessWidget {
  final bool showFlags;
  final bool showNativeNames;
  final TextStyle? textStyle;
  final Color? dropdownColor;

  const LanguageDropdownWidget({
    Key? key,
    this.showFlags = true,
    this.showNativeNames = true,
    this.textStyle,
    this.dropdownColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LanguageController>(
      builder: (controller) {
        return DropdownButton<String>(
          value: controller.currentLocaleString.value,
          isDense: true,
          underline: const SizedBox(),
          style: textStyle,
          dropdownColor: dropdownColor,
          items: controller.getAvailableLanguages().map((language) {
            return DropdownMenuItem<String>(
              value: language['code'],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showFlags) ...[
                    Text(
                      language['flag']!,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    showNativeNames
                        ? language['nativeName']!
                        : language['name']!,
                    style: textStyle,
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              controller.switchToLocale(newValue);
            }
          },
        );
      },
    );
  }
}
