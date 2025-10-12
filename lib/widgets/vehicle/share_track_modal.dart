import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:luna_iot/app/app_theme.dart';
import 'package:luna_iot/api/services/share_track_api_service.dart';
import 'package:luna_iot/utils/constants.dart';
import 'package:share_plus/share_plus.dart';

class ShareTrackModal extends StatefulWidget {
  final String imei;
  final String vehicleNo;

  const ShareTrackModal({
    super.key,
    required this.imei,
    required this.vehicleNo,
  });

  @override
  State<ShareTrackModal> createState() => _ShareTrackModalState();
}

class _ShareTrackModalState extends State<ShareTrackModal> {
  final ShareTrackApiService _shareTrackApiService =
      Get.find<ShareTrackApiService>();
  bool _isLoading = false;
  String? _existingShareLink;
  String? _newShareLink;

  @override
  void initState() {
    super.initState();
    _checkExistingShare();
  }

  Future<void> _checkExistingShare() async {
    try {
      setState(() => _isLoading = true);
      final existingShare = await _shareTrackApiService.getExistingShare(
        widget.imei,
      );
      if (existingShare != null && existingShare['token'] != null) {
        setState(() {
          _existingShareLink =
              '${Constants.webBaseUrl}/share-track/${existingShare['token']}';
        });
      }
    } catch (e) {
      print('Error checking existing share: $e');
      // Silently handle error - no existing share found or permission denied
      // This is expected behavior, so we don't show error to user
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createShareTrack(int durationMinutes) async {
    try {
      setState(() => _isLoading = true);
      final result = await _shareTrackApiService.createShareTrack(
        widget.imei,
        durationMinutes,
      );

      if (result['success'] == true && result['token'] != null) {
        setState(() {
          _newShareLink =
              '${Constants.webBaseUrl}/share-track/${result['token']}';

          // If this is an existing share track, also set the existing share link
          if (result['is_existing'] == true) {
            _existingShareLink = _newShareLink;
            _newShareLink = null; // Clear new share link since it's existing

            // Show info message about existing share track
            Get.snackbar(
              'Existing Share Track',
              'An active share track already exists for this vehicle',
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );
          }
        });
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Failed to create share link',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: Duration(seconds: 4),
        );
      }
    } catch (e) {
      print('Create share track error: $e');
      String errorMessage = 'Failed to create share link';

      // Provide more specific error messages based on the exception
      if (e.toString().contains('Access Denied')) {
        errorMessage =
            'You do not have permission to share this vehicle. Please contact your administrator.';
      } else if (e.toString().contains('Server Error')) {
        errorMessage =
            'Server is temporarily unavailable. Please try again later.';
      } else if (e.toString().contains('Bad Request')) {
        errorMessage = 'Invalid request. Please check your vehicle details.';
      } else {
        errorMessage = 'Failed to create share link: ${e.toString()}';
      }

      Get.snackbar(
        'Error',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard(String link) {
    Clipboard.setData(ClipboardData(text: link));
    Get.snackbar(
      'Copied',
      'Share link copied to clipboard',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void _shareLink(String link) {
    final shareText =
        'Track my vehicle ${widget.vehicleNo} in real-time!\n\n$link\n\nShared via Luna IoT';

    Share.share(shareText, subject: 'Vehicle Tracking - ${widget.vehicleNo}');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.share, color: AppTheme.primaryColor, size: 24),
              SizedBox(width: 10),
              Text(
                'Share Vehicle Tracking',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.titleColor,
                ),
              ),
              Spacer(),
              IconButton(
                onPressed: () => Get.back(),
                icon: Icon(Icons.close, color: AppTheme.subTitleColor),
              ),
            ],
          ),

          SizedBox(height: 10),

          // Vehicle Info
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.directions_car,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Vehicle: ${widget.vehicleNo}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.titleColor,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          if (_isLoading)
            Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          else if (_existingShareLink != null)
            _buildExistingShareSection()
          else if (_newShareLink != null)
            _buildNewShareSection()
          else
            _buildDurationSelection(),
        ],
      ),
    );
  }

  Widget _buildExistingShareSection() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Active share link already exists',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 15),

        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.secondaryColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share Link:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.subTitleColor,
                ),
              ),
              SizedBox(height: 5),
              SelectableText(
                _existingShareLink!,
                style: TextStyle(fontSize: 12, color: AppTheme.titleColor),
              ),
            ],
          ),
        ),

        SizedBox(height: 15),

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _copyToClipboard(_existingShareLink!),
                icon: Icon(Icons.copy, size: 16),
                label: Text('Copy'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _shareLink(_existingShareLink!),
                icon: Icon(Icons.share, size: 16),
                label: Text('Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _existingShareLink = null;
                    _newShareLink = null;
                  });
                },
                icon: Icon(Icons.refresh, size: 16),
                label: Text('New'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNewShareSection() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.link, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Share link created successfully',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 15),

        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.secondaryColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share Link:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.subTitleColor,
                ),
              ),
              SizedBox(height: 5),
              SelectableText(
                _newShareLink!,
                style: TextStyle(fontSize: 12, color: AppTheme.titleColor),
              ),
            ],
          ),
        ),

        SizedBox(height: 15),

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _copyToClipboard(_newShareLink!),
                icon: Icon(Icons.copy, size: 16),
                label: Text('Copy'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _shareLink(_newShareLink!),
                icon: Icon(Icons.share, size: 16),
                label: Text('Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _newShareLink = null;
                  });
                },
                icon: Icon(Icons.refresh, size: 16),
                label: Text('New'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationSelection() {
    final durations = [
      {'label': '10 Minutes', 'minutes': 10},
      {'label': '30 Minutes', 'minutes': 30},
      {'label': '1 Hour', 'minutes': 60},
      {'label': '2 Hours', 'minutes': 120},
      {'label': '12 Hours', 'minutes': 720},
      {'label': '24 Hours', 'minutes': 1440},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Select sharing duration:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.titleColor,
              ),
            ),
            Spacer(),
            if (_existingShareLink != null)
              TextButton.icon(
                onPressed: () => _shareLink(_existingShareLink!),
                icon: Icon(Icons.share, size: 16),
                label: Text('Quick Share'),
                style: TextButton.styleFrom(foregroundColor: Colors.green),
              ),
          ],
        ),

        SizedBox(height: 15),

        // Show info message if there are permission issues
        if (_isLoading == false &&
            _existingShareLink == null &&
            _newShareLink == null)
          Container(
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Create a shareable link to track this vehicle in real-time',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),

        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: durations.length,
          itemBuilder: (context, index) {
            final duration = durations[index];
            return ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () => _createShareTrack(duration['minutes'] as int),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                duration['label'] as String,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
      ],
    );
  }
}
