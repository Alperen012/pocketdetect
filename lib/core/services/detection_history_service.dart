import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/detection_history_entry.dart';

/// Manages detection history with local persistence via [SharedPreferences].
class DetectionHistoryService extends ChangeNotifier {
  DetectionHistoryService(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;
  static const _key = 'detection_history';
  static const _maxEntries = 50;

  List<DetectionHistoryEntry> _entries = [];

  List<DetectionHistoryEntry> get entries =>
      List<DetectionHistoryEntry>.unmodifiable(_entries);

  int get count => _entries.length;

  bool get isEmpty => _entries.isEmpty;

  void _load() {
    final raw = _prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        _entries = DetectionHistoryEntry.decodeList(raw);
      } catch (e) {
        debugPrint('Failed to load detection history: $e');
        _entries = [];
      }
    }
  }

  Future<void> _save() async {
    await _prefs.setString(_key, DetectionHistoryEntry.encodeList(_entries));
  }

  /// Add a new detection entry to history.
  Future<void> addEntry(DetectionHistoryEntry entry) async {
    _entries.insert(0, entry); // newest first
    // Cap at max entries
    if (_entries.length > _maxEntries) {
      _entries = _entries.sublist(0, _maxEntries);
    }
    await _save();
    notifyListeners();
  }

  /// Remove a specific entry by ID.
  Future<void> removeEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    await _save();
    notifyListeners();
  }

  /// Clear all history.
  Future<void> clearAll() async {
    _entries.clear();
    await _prefs.remove(_key);
    notifyListeners();
  }
}
