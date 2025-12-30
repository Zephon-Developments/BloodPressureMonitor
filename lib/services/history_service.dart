import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/services/database_service.dart';
import 'package:blood_pressure_monitor/services/reading_service.dart';

/// Service responsible for retrieving history data with pagination
/// and tag filtering support.
class HistoryService {
  HistoryService({
    DatabaseService? databaseService,
    ReadingService? readingService,
  })  : _databaseService = databaseService ?? DatabaseService(),
        _readingService = readingService ?? ReadingService();

  final DatabaseService _databaseService;
  final ReadingService _readingService;

  /// Default number of rows to fetch per page.
  static const int defaultPageSize = 20;

  /// Retrieves averaged reading groups ordered by newest first.
  ///
  /// Parameters:
  /// - [profileId]: Profile to query.
  /// - [start]/[end]: Optional inclusive bounds on `groupStartAt`.
  /// - [before]: Keyset cursor (exclusive upper bound) for pagination.
  /// - [limit]: Maximum rows to return (defaults to [defaultPageSize]).
  /// - [tags]: Optional case-insensitive tag filter applied to the
  ///   readings that compose each averaged group.
  ///
  /// Returns the ordered list of summaries already filtered by any tag
  /// constraint.
  Future<List<ReadingGroup>> fetchGroupedHistory({
    required int profileId,
    DateTime? start,
    DateTime? end,
    DateTime? before,
    int limit = defaultPageSize,
    List<String> tags = const <String>[],
  }) async {
    final normalizedTags = _normalizeTags(tags);
    final results = <ReadingGroup>[];
    DateTime? cursor = before;
    var hasMore = true;

    while (results.length < limit && hasMore) {
      final page = await _queryGroupedHistory(
        profileId: profileId,
        start: start,
        end: end,
        before: cursor,
        limit: limit,
      );
      if (page.isEmpty) {
        break;
      }

      cursor = page.last.groupStartAt;
      hasMore = page.length == limit;

      if (normalizedTags.isEmpty) {
        results.addAll(page);
      } else {
        final filtered = await _filterGroupsByTags(page, normalizedTags);
        results.addAll(filtered);
      }
    }

    return results.length > limit ? results.sublist(0, limit) : results;
  }

  /// Retrieves raw readings ordered by newest first.
  ///
  /// Parameters mirror [fetchGroupedHistory] but operate directly on
  /// the raw readings table. Tag filtering is handled by matching each
  /// normalized tag against the comma-separated `tags` column.
  ///
  /// Returns the filtered readings, ordered by `takenAt` descending.
  Future<List<Reading>> fetchRawHistory({
    required int profileId,
    DateTime? start,
    DateTime? end,
    DateTime? before,
    int limit = defaultPageSize,
    List<String> tags = const <String>[],
  }) async {
    final normalizedTags = _normalizeTags(tags);
    final results = <Reading>[];
    DateTime? cursor = before;
    var hasMore = true;

    while (results.length < limit && hasMore) {
      final page = await _queryRawHistory(
        profileId: profileId,
        start: start,
        end: end,
        before: cursor,
        limit: limit,
      );
      if (page.isEmpty) {
        break;
      }

      cursor = page.last.takenAt;
      hasMore = page.length == limit;

      if (normalizedTags.isEmpty) {
        results.addAll(page);
      } else {
        results.addAll(
          page.where((reading) => _readingMatchesTags(reading, normalizedTags)),
        );
      }
    }

    return results.length > limit ? results.sublist(0, limit) : results;
  }

  /// Retrieves the raw readings for a given averaged group.
  ///
  /// Readings are sorted descending by `takenAt` to match the UI
  /// expectation that newest values appear first.
  Future<List<Reading>> fetchGroupMembers(ReadingGroup group) async {
    final ids = _parseMemberIds(group.memberReadingIds);
    final readings = await _readingService.getReadingsByIds(ids);
    readings.sort((a, b) => b.takenAt.compareTo(a.takenAt));
    return readings;
  }

  Future<List<ReadingGroup>> _filterGroupsByTags(
    List<ReadingGroup> groups,
    Set<String> normalizedTags,
  ) async {
    if (groups.isEmpty) {
      return groups;
    }

    if (normalizedTags.isEmpty) {
      return groups;
    }

    final idSet = <int>{};
    for (final group in groups) {
      idSet.addAll(_parseMemberIds(group.memberReadingIds));
    }

    final readings = await _readingService.getReadingsByIds(idSet.toList());
    final readingsById = {for (final reading in readings) reading.id!: reading};

    return groups.where((group) {
      final memberIds = _parseMemberIds(group.memberReadingIds);
      for (final id in memberIds) {
        final reading = readingsById[id];
        if (reading == null) continue;
        if (_readingMatchesTags(reading, normalizedTags)) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  Future<List<ReadingGroup>> _queryGroupedHistory({
    required int profileId,
    DateTime? start,
    DateTime? end,
    DateTime? before,
    required int limit,
  }) async {
    final db = await _databaseService.database;
    final where = <String>['profileId = ?'];
    final args = <Object>[profileId];

    if (start != null) {
      where.add('groupStartAt >= ?');
      args.add(start.toIso8601String());
    }
    if (end != null) {
      where.add('groupStartAt <= ?');
      args.add(end.toIso8601String());
    }
    if (before != null) {
      where.add('groupStartAt < ?');
      args.add(before.toIso8601String());
    }

    final rows = await db.query(
      'ReadingGroup',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'groupStartAt DESC',
      limit: limit,
    );

    return rows.map(ReadingGroup.fromMap).toList();
  }

  Future<List<Reading>> _queryRawHistory({
    required int profileId,
    DateTime? start,
    DateTime? end,
    DateTime? before,
    required int limit,
  }) async {
    final db = await _databaseService.database;
    final where = <String>['profileId = ?'];
    final args = <Object>[profileId];

    if (start != null) {
      where.add('takenAt >= ?');
      args.add(start.toIso8601String());
    }
    if (end != null) {
      where.add('takenAt <= ?');
      args.add(end.toIso8601String());
    }
    if (before != null) {
      where.add('takenAt < ?');
      args.add(before.toIso8601String());
    }

    final rows = await db.query(
      'Reading',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'takenAt DESC',
      limit: limit,
    );

    return rows.map(Reading.fromMap).toList();
  }

  Set<String> _normalizeTags(List<String> tags) {
    return tags
        .map((tag) => tag.trim().toLowerCase())
        .where((tag) => tag.isNotEmpty)
        .toSet();
  }

  bool _readingMatchesTags(Reading reading, Set<String> normalizedTags) {
    if (normalizedTags.isEmpty) {
      return true;
    }
    final tagValues = reading.tags
        ?.split(',')
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty);
    if (tagValues == null) {
      return false;
    }
    return tagValues.any(normalizedTags.contains);
  }

  List<int> _parseMemberIds(String memberIds) {
    return memberIds
        .split(',')
        .map((value) => int.tryParse(value.trim()))
        .whereType<int>()
        .toList();
  }
}
