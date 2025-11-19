import 'dart:async';
import 'package:flutter/material.dart' hide Banner;
import 'package:get/get.dart';
import 'package:luna_iot/api/api_client.dart';
import 'package:luna_iot/api/services/banner_api_service.dart';
import 'package:luna_iot/models/banner_model.dart';
import 'package:url_launcher/url_launcher.dart';

class BannerCarouselWidget extends StatefulWidget {
  const BannerCarouselWidget({super.key});

  @override
  State<BannerCarouselWidget> createState() => _BannerCarouselWidgetState();
}

class _BannerCarouselWidgetState extends State<BannerCarouselWidget> {
  final PageController _pageController = PageController();
  Timer? _autoPlayTimer;
  int _currentPage = 0;
  List<Banner> _banners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    try {
      // Get ApiClient from GetX
      if (!Get.isRegistered<ApiClient>()) {
        Get.put(ApiClient());
      }
      if (!Get.isRegistered<BannerApiService>()) {
        Get.put(BannerApiService(Get.find<ApiClient>()));
      }

      final bannerApiService = Get.find<BannerApiService>();
      final banners = await bannerApiService.getActiveBanners();

      if (mounted) {
        // Sort banners by orderPosition (ascending)
        banners.sort((a, b) => a.orderPosition.compareTo(b.orderPosition));
        
        setState(() {
          _banners = banners;
          _isLoading = false;
        });

        // Start auto-play if we have banners
        if (_banners.isNotEmpty) {
          _startAutoPlay();
        }
      }
    } catch (e) {
      print('Error loading banners: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_banners.isEmpty) {
        timer.cancel();
        return;
      }

      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % _banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  Future<void> _onBannerTap(Banner banner) async {
    // Only handle tap if URL exists and is not empty
    if (banner.url == null || banner.url!.isEmpty) {
      return; // Do nothing if no URL
    }

    try {
      // Increment click count
      if (!Get.isRegistered<BannerApiService>()) {
        Get.put(BannerApiService(Get.find<ApiClient>()));
      }
      final bannerApiService = Get.find<BannerApiService>();
      await bannerApiService.incrementBannerClick(banner.id);

      // Launch URL
      final uri = Uri.parse(banner.url!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('Could not launch ${banner.url}');
      }
    } catch (e) {
      print('Error handling banner tap: $e');
      // Still try to launch URL even if click increment fails
      try {
        final uri = Uri.parse(banner.url!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (urlError) {
        print('Error launching URL: $urlError');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink(); // Don't show anything while loading
    }

    if (_banners.isEmpty) {
      return const SizedBox.shrink(); // Don't show anything if no banners
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          // Banner carousel with 16:5 aspect ratio
          AspectRatio(
            aspectRatio: 16 / 4,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _banners.length,
              itemBuilder: (context, index) {
                final banner = _banners[index];
                return GestureDetector(
                  onTap: () => _onBannerTap(banner),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: banner.imageUrl != null
                          ? Image.network(
                              banner.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(Icons.broken_image),
                                  ),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.image, size: 48),
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Page indicators
          if (_banners.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _banners.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? Colors.blue
                          : Colors.grey.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
