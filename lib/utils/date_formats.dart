import 'package:intl/intl.dart';

/// Centralized date formatting patterns for consistent display across the app
class DateFormats {
  DateFormats._();

  /// Standard date and time format: 2024-12-27 14:30
  static final DateFormat standardDateTime = DateFormat('yyyy-MM-dd HH:mm');

  /// Date only format: 2024-12-27
  static final DateFormat dateOnly = DateFormat('yyyy-MM-dd');

  /// Time only format: 14:30
  static final DateFormat timeOnly = DateFormat('HH:mm');

  /// Long format: December 27, 2024
  static final DateFormat longDate = DateFormat('MMMM dd, yyyy');

  /// Short format with time: Dec 27, 2:30 PM
  static final DateFormat shortDateTime = DateFormat('MMM dd, h:mm a');
}
