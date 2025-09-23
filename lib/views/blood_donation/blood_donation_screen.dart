import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/controllers/auth_controller.dart';
import 'package:luna_iot/controllers/blood_donation_controller.dart';
import 'package:luna_iot/models/blood_donation_model.dart';
import 'package:luna_iot/views/blood_donation/blood_donation_form_screen.dart';
import 'package:luna_iot/widgets/loading_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class BloodDonationScreen extends StatefulWidget {
  const BloodDonationScreen({super.key});

  @override
  State<BloodDonationScreen> createState() => _BloodDonationScreenState();
}

class _BloodDonationScreenState extends State<BloodDonationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final BloodDonationController _controller;
  late final AuthController _authController;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _controller = Get.find<BloodDonationController>();
    _authController = Get.find<AuthController>();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _controller.switchTab(
          _tabController.index == 0
              ? ApplyTypeOptions.need
              : ApplyTypeOptions.donate,
        );
      }
    });

    // Load blood donations after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadBloodDonations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper methods for role-based permissions
  bool get canEditBloodDonation {
    final user = _authController.currentUser.value;
    if (user == null) return false;
    return user.role.name.toLowerCase() == 'super admin' ||
        user.role.name.toLowerCase() == 'dealer' ||
        user.hasPermission('Can view blood donation');
  }

  bool get canDeleteBloodDonation {
    final user = _authController.currentUser.value;
    if (user == null) return false;
    return user.role.name.toLowerCase() == 'super admin';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Blood Donation',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.loadBloodDonations(),
          ),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Colors.red,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.red,
            dividerColor: Colors.white,
            tabs: const [
              Tab(icon: Icon(Icons.bloodtype), text: 'Need Blood'),
              Tab(icon: Icon(Icons.favorite), text: 'Donate Blood'),
            ],
          ),

          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                // Search Bar
                Obx(
                  () => TextField(
                    onChanged: (value) =>
                        _controller.searchBloodDonations(value),
                    decoration: InputDecoration(
                      hintText: 'Search by name, phone, or address...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _controller.searchQuery.value.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () =>
                                  _controller.searchBloodDonations(''),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Blood Group Filter
                Obx(
                  () => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text('Filter by Blood Group: '),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('All'),
                          selected:
                              _controller.selectedBloodGroup.value.isEmpty,
                          onSelected: (selected) {
                            if (selected) {
                              _controller.filterByBloodGroup('');
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ..._controller.bloodGroupOptions.map((bloodGroup) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(bloodGroup),
                              selected:
                                  _controller.selectedBloodGroup.value ==
                                  bloodGroup,
                              onSelected: (selected) {
                                _controller.filterByBloodGroup(
                                  selected ? bloodGroup : '',
                                );
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Obx(() {
              if (_controller.isLoading.value) {
                return const Center(child: LoadingWidget());
              }

              if (_controller.errorMessage.value.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _controller.errorMessage.value,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _controller.loadBloodDonations(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final currentDonations = _controller.currentTabBloodDonations;

              if (currentDonations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _controller.selectedTab.value == ApplyTypeOptions.need
                            ? Icons.bloodtype_outlined
                            : Icons.favorite_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _controller.selectedTab.value == ApplyTypeOptions.need
                            ? 'No blood requests found'
                            : 'No blood donors found',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Be the first to ${_controller.selectedTab.value == ApplyTypeOptions.need ? "request" : "donate"} blood!',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: currentDonations.length,
                itemBuilder: (context, index) {
                  final donation = currentDonations[index];
                  return _buildBloodDonationCard(donation);
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const BloodDonationFormScreen()),
        backgroundColor: Colors.red,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Apply', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.shade100,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color.shade700),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodDonationCard(BloodDonation donation) {
    final isNeed = donation.applyType == ApplyTypeOptions.need;
    final bloodGroupColor = _getBloodGroupColor(donation.bloodGroup);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: bloodGroupColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                bloodGroupColor.withOpacity(0.02),
                Colors.grey.shade50,
              ],
            ),
            border: Border.all(
              color: bloodGroupColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Blood Group, Type, and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Blood Group Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            bloodGroupColor,
                            bloodGroupColor.withOpacity(0.8),
                            bloodGroupColor.withOpacity(0.9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: bloodGroupColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.water_drop,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            donation.bloodGroup,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Type and Status Badges
                    Row(
                      children: [
                        // Type Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isNeed
                                  ? [
                                      Colors.orange.shade400,
                                      Colors.orange.shade600,
                                    ]
                                  : [
                                      Colors.green.shade400,
                                      Colors.green.shade600,
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (isNeed ? Colors.orange : Colors.green)
                                    .withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isNeed ? Icons.emergency : Icons.favorite,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ApplyTypeOptions.getDisplayName(
                                  donation.applyType,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: donation.status
                                  ? [
                                      Colors.green.shade400,
                                      Colors.green.shade600,
                                    ]
                                  : [
                                      Colors.grey.shade400,
                                      Colors.grey.shade600,
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (donation.status
                                            ? Colors.green
                                            : Colors.grey)
                                        .withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                donation.status
                                    ? (isNeed
                                          ? Icons.check_circle
                                          : Icons.favorite)
                                    : Icons.pending,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                donation.status
                                    ? (isNeed ? 'Received' : 'Donated')
                                    : 'Pending',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Name and Phone in one row
                Row(
                  children: [
                    // Name
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 16,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Name',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    donation.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.blue.shade800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Phone
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () => _makePhoneCall(donation.phone),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 16,
                                color: Colors.green.shade600,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Contact',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      donation.phone,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.green.shade800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Address
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple.shade100),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.purple.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Location',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              donation.address,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.purple.shade800,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Last Donated Date (for donors) - compact version
                if (donation.applyType == ApplyTypeOptions.donate &&
                    donation.lastDonatedAt != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 14,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Last donated: ${_formatDate(donation.lastDonatedAt!)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.amber.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Created Date - compact footer
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date info
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_outlined,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Posted ${_formatDate(donation.createdAt ?? DateTime.now())}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Action buttons - wrapped
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        // Call button
                        _buildActionButton(
                          icon: Icons.call,
                          label: isNeed ? 'Help Now' : 'Contact',
                          color: isNeed ? Colors.orange : Colors.green,
                          onTap: () => _makePhoneCall(donation.phone),
                        ),

                        // Edit button (if user has permission)
                        if (canEditBloodDonation)
                          _buildActionButton(
                            icon: Icons.edit,
                            label: 'Edit',
                            color: Colors.blue,
                            onTap: () => _editBloodDonation(donation),
                          ),

                        // Delete button (if user has permission)
                        if (canDeleteBloodDonation)
                          _buildActionButton(
                            icon: Icons.delete,
                            label: 'Delete',
                            color: Colors.red,
                            onTap: () => _deleteBloodDonation(donation),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBloodGroupColor(String bloodGroup) {
    switch (bloodGroup.toUpperCase()) {
      case 'A+':
        return Colors.red.shade500;
      case 'A-':
        return Colors.red.shade400;
      case 'B+':
        return Colors.blue.shade500;
      case 'B-':
        return Colors.blue.shade400;
      case 'AB+':
        return Colors.purple.shade500;
      case 'AB-':
        return Colors.purple.shade400;
      case 'O+':
        return Colors.orange.shade500;
      case 'O-':
        return Colors.orange.shade400;
      default:
        return Colors.grey.shade500;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      debugPrint('Opening phone dialer with: $phoneNumber');

      // Try different URI formats
      List<Uri> uriOptions = [
        Uri(scheme: 'tel', path: phoneNumber),
        Uri.parse('tel:$phoneNumber'),
        Uri(scheme: 'tel', path: '+$phoneNumber'),
        Uri.parse('tel:+$phoneNumber'),
      ];

      bool success = false;

      for (Uri uri in uriOptions) {
        try {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
            success = true;
            break;
          } else {
            debugPrint('Cannot launch: $uri');
          }
        } catch (e) {
          debugPrint('Error with $uri: $e');
          continue;
        }
      }

      if (!success) {
        // Try using launchUrl with mode
        try {
          final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          success = true;
        } catch (e) {
          debugPrint('External application mode failed: $e');
        }
      }

      if (!success) {
        Get.snackbar(
          'Error',
          'Could not open phone dialer. Please call $phoneNumber manually.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      debugPrint('Phone call error: $e');
      Get.snackbar(
        'Error',
        'Failed to open phone dialer: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Edit blood donation - status and last_donated_at based on apply type
  void _editBloodDonation(BloodDonation donation) {
    bool currentStatus = donation.status;
    DateTime? selectedDate = donation.lastDonatedAt;
    final TextEditingController dateController = TextEditingController();
    final isNeed = donation.applyType == ApplyTypeOptions.need;

    if (selectedDate != null) {
      dateController.text = _formatDate(selectedDate);
    }

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.edit, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  isNeed ? 'Update Status' : 'Update Donation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isNeed ? "Requester" : "Donor"}: ${donation.name}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Blood Group: ${donation.bloodGroup}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),

                // Status toggle
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: currentStatus
                        ? (isNeed ? Colors.green.shade50 : Colors.blue.shade50)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: currentStatus
                          ? (isNeed
                                ? Colors.green.shade200
                                : Colors.blue.shade200)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        currentStatus
                            ? (isNeed ? Icons.check_circle : Icons.favorite)
                            : Icons.pending,
                        color: currentStatus
                            ? (isNeed
                                  ? Colors.green.shade600
                                  : Colors.blue.shade600)
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isNeed ? 'Blood Received' : 'Blood Donated',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: currentStatus
                                    ? (isNeed
                                          ? Colors.green.shade700
                                          : Colors.blue.shade700)
                                    : Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              currentStatus
                                  ? (isNeed
                                        ? 'Blood has been received'
                                        : 'Blood has been donated')
                                  : (isNeed
                                        ? 'Blood not received yet'
                                        : 'Blood not donated yet'),
                              style: TextStyle(
                                fontSize: 12,
                                color: currentStatus
                                    ? (isNeed
                                          ? Colors.green.shade600
                                          : Colors.blue.shade600)
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: currentStatus,
                        onChanged: (value) {
                          setState(() {
                            currentStatus = value;
                          });
                        },
                        activeColor: isNeed ? Colors.green : Colors.blue,
                      ),
                    ],
                  ),
                ),

                // Date picker (only for donate type)
                if (!isNeed) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: dateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Last Donated Date',
                      hintText: 'Select date',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            selectedDate = null;
                            dateController.clear();
                          });
                        },
                      ),
                    ),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                          dateController.text = _formatDate(picked);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Leave empty if never donated before',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (donation.id != null) {
                    // Create updated donation
                    final updatedDonation = BloodDonation(
                      id: donation.id,
                      name: donation.name,
                      phone: donation.phone,
                      address: donation.address,
                      bloodGroup: donation.bloodGroup,
                      applyType: donation.applyType,
                      status: currentStatus,
                      lastDonatedAt: isNeed
                          ? donation.lastDonatedAt
                          : selectedDate,
                      createdAt: donation.createdAt,
                      updatedAt: DateTime.now(),
                    );

                    final success = await _controller.updateBloodDonation(
                      donation.id!,
                      updatedDonation,
                    );

                    if (success) {
                      // Close edit modal - force close
                      Navigator.of(context).pop();
                      Get.snackbar(
                        'Success',
                        isNeed
                            ? 'Status updated successfully!'
                            : 'Donation updated successfully!',
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                      );
                    } else {
                      // Close edit modal even on failure
                      Navigator.of(context).pop();
                      Get.snackbar(
                        'Error',
                        'Failed to update blood donation. Please try again.',
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Delete blood donation
  void _deleteBloodDonation(BloodDonation donation) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text(
              'Delete Blood Donation',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this blood donation?',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Donor Details:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Name: ${donation.name}'),
                  Text('Blood Group: ${donation.bloodGroup}'),
                  Text(
                    'Type: ${ApplyTypeOptions.getDisplayName(donation.applyType)}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isDeleting ? null : () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isDeleting ? null : () => _performDelete(donation),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: _isDeleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Perform the actual delete operation
  Future<void> _performDelete(BloodDonation donation) async {
    if (_isDeleting || donation.id == null) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final success = await _controller.deleteBloodDonation(donation.id!);

      // Close confirmation dialog - force close
      Navigator.of(context).pop();

      if (success) {
        Get.snackbar(
          'Success',
          'Blood donation deleted successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to delete blood donation. Please try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      // Close confirmation dialog - force close
      Navigator.of(context).pop();
      Get.snackbar(
        'Error',
        'An error occurred while deleting: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      // Always reset the loading state
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }
}
