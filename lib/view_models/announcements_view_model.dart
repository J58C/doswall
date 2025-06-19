import 'package:flutter/foundation.dart';
import '../services/announcement_service.dart';
import '../models/announcement_response.dart';
import '../enums/view_state.dart';

class AnnouncementsViewModel with ChangeNotifier {
  final AnnouncementService _service;

  AnnouncementsViewModel({required AnnouncementService service}) : _service = service;

  List<Announcement> _announcements = [];
  ViewState _state = ViewState.loading;
  String _errorMessage = '';

  List<Announcement> get announcements => _announcements;
  ViewState get state => _state;
  String get errorMessage => _errorMessage;

  void _setState(ViewState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> fetchAnnouncements() async {
    _setState(ViewState.loading);
    try {
      final result = await _service.fetchAnnouncements();
      _announcements = result;
      if (_announcements.isEmpty) {
        _setState(ViewState.empty);
      } else {
        _setState(ViewState.success);
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ViewState.error);
    }
  }

  Future<void> deleteAnnouncement({
    required String announcementId,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      final success = await _service.deleteAnnouncement(announcementId: announcementId);
      if (success) {
        onSuccess('Pengumuman berhasil dihapus.');
        fetchAnnouncements();
      } else {
        onError('Gagal menghapus pengumuman.');
      }
    } catch (e) {
      onError('Error: ${e.toString()}');
    }
  }

  Future<bool> addAnnouncement({
    required String title,
    required String content,
  }) async {
    try {
      final newId = await _service.addAnnouncement(title: title, content: content);
      final success = newId != null;
      if (success) {
        fetchAnnouncements();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateAnnouncement({
    required String announcementId,
    required String title,
    required String content,
  }) async {
    try {
      final success = await _service.updateAnnouncement(
        announcementId: announcementId,
        title: title,
        content: content,
      );
      if (success) {
        fetchAnnouncements();
      }
      return success;
    } catch (e) {
      return false;
    }
  }
}