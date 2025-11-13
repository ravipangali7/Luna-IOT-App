import 'dart:io';
import 'package:get/get.dart';
import 'package:luna_iot/api/services/luna_tag_api_service.dart';
import 'package:luna_iot/models/luna_tag_model.dart';
import 'package:luna_iot/models/pagination_model.dart';

class LunaTagController extends GetxController {
  final LunaTagApiService _api;
  LunaTagController(this._api);

  final RxList<UserLunaTag> userTags = <UserLunaTag>[].obs;
  final Rxn<LunaTagData> latestData = Rxn<LunaTagData>();
  final RxMap<String, LunaTagData?> latestDataByKey = <String, LunaTagData?>{}.obs;
  final RxList<LunaTagData> playbackData = <LunaTagData>[].obs;
  final RxBool playbackLoading = false.obs;
  final Rx<PaginationInfo> pagination = PaginationInfo(
    count: 0,
    next: null,
    previous: null,
    currentPage: 1,
    totalPages: 1,
    pageSize: 25,
  ).obs;
  final RxBool loading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserTags();
  }

  Future<void> fetchUserTags({int page = 1, int pageSize = 15}) async {
    try {
      loading.value = true;
      error.value = '';
      final res = await _api.getUserLunaTags(page: page, pageSize: pageSize);
      userTags.assignAll(res.data);
      pagination.value = res.pagination;
      // Prefetch latest data for visible tags
      _prefetchLatestData();
    } catch (e) {
      error.value = 'Failed to load Luna Tags';
    } finally {
      loading.value = false;
    }
  }

  Future<void> goToPage(int page) async {
    await fetchUserTags(page: page, pageSize: pagination.value.pageSize);
  }

  Future<void> fetchLatestData(String publicKey) async {
    // Validate publicKey is not empty
    if (publicKey.isEmpty) {
      latestData.value = null;
      return;
    }
    
    try {
      latestData.value = null;
      final data = await _api.getLatestData(publicKey);
      latestData.value = data;
      latestDataByKey[publicKey] = data;
    } catch (_) {
      latestData.value = null;
      latestDataByKey[publicKey] = null;
    }
  }

  Future<void> fetchLatestDataForKey(String publicKey) async {
    if (latestDataByKey.containsKey(publicKey)) return;
    await fetchLatestData(publicKey);
  }

  Future<void> _prefetchLatestData() async {
    final keys = userTags.map((e) => e.publicKey).where((key) => key.isNotEmpty).toSet().toList();
    // Prefetch latest data for each key if missing
    for (final key in keys) {
      if (!latestDataByKey.containsKey(key)) {
        // Fire and forget
        _api.getLatestData(key).then((data) => latestDataByKey[key] = data).catchError((_) => null);
      }
    }
  }

  Future<void> fetchPlaybackData({
    required String publicKey,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (publicKey.isEmpty) {
      playbackData.clear();
      return;
    }

    try {
      playbackLoading.value = true;
      final data = await _api.getLunaTagDataByDateRange(
        publicKey: publicKey,
        startDate: startDate,
        endDate: endDate,
      );
      playbackData.assignAll(data);
    } catch (e) {
      playbackData.clear();
      error.value = 'Failed to fetch playback data';
    } finally {
      playbackLoading.value = false;
    }
  }

  Future<bool> createUserLunaTag({
    required String publicKey,
    required String name,
    File? imageFile,
    String? imageUrl,
    DateTime? expireDate,
    bool isActive = true,
  }) async {
    try {
      loading.value = true;
      error.value = '';
      final expireDateIso = expireDate?.toIso8601String();
      await _api.createUserLunaTag(
        publicKey: publicKey,
        name: name,
        imageFile: imageFile,
        imageUrl: imageUrl,
        expireDateIso: expireDateIso,
        isActive: isActive,
      );
      // Refresh the list
      await fetchUserTags();
      return true;
    } on Exception catch (e) {
      // Extract error message from Exception
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      error.value = errorMsg.isNotEmpty ? errorMsg : 'Failed to create Luna Tag';
      return false;
    } catch (e) {
      // Catch any other type of error
      error.value = 'Failed to create Luna Tag: ${e.toString()}';
      return false;
    } finally {
      loading.value = false;
    }
  }

  Future<bool> updateUserLunaTag({
    required int id,
    String? name,
    File? imageFile,
    DateTime? expireDate,
    bool? isActive,
  }) async {
    try {
      loading.value = true;
      error.value = '';
      final expireDateIso = expireDate?.toIso8601String();
      await _api.updateUserLunaTag(
        id: id,
        name: name,
        imageFile: imageFile,
        expireDateIso: expireDateIso,
        isActive: isActive,
      );
      // Refresh the list
      await fetchUserTags();
      return true;
    } on Exception catch (e) {
      // Extract error message from Exception
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      error.value = errorMsg.isNotEmpty ? errorMsg : 'Failed to update Luna Tag';
      return false;
    } catch (e) {
      // Catch any other type of error
      error.value = 'Failed to update Luna Tag: ${e.toString()}';
      return false;
    } finally {
      loading.value = false;
    }
  }
}