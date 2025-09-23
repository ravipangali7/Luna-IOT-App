import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/api/services/popup_api_service.dart';
import 'package:luna_iot/models/popup_model.dart';
import 'package:luna_iot/widgets/popup_modal_widget.dart';

class PopupService {
  static final PopupService _instance = PopupService._internal();
  factory PopupService() => _instance;
  PopupService._internal();

  PopupApiService get _popupApiService => Get.find<PopupApiService>();

  // Track shown popups to avoid showing them multiple times
  final Set<int> _shownPopups = <int>{};

  /// Show active popups when app opens
  Future<void> showActivePopups(BuildContext context) async {
    try {
      final activePopups = await _popupApiService.getActivePopups();

      // Filter out already shown popups
      final newPopups = activePopups
          .where((popup) => !_shownPopups.contains(popup.id))
          .toList();

      // Show each popup one by one
      for (final popup in newPopups) {
        await _showPopupModal(context, popup);
        _shownPopups.add(popup.id);
      }
    } catch (e) {
      print('Error showing active popups: $e');
    }
  }

  /// Show a single popup modal
  Future<void> _showPopupModal(BuildContext context, Popup popup) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopupModalWidget(
          popup: popup,
          onClose: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  /// Clear shown popups history (useful for testing or reset)
  void clearShownPopups() {
    _shownPopups.clear();
  }

  /// Check if a popup has been shown
  bool hasBeenShown(int popupId) {
    return _shownPopups.contains(popupId);
  }
}
