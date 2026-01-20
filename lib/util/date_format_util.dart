import 'package:intl/intl.dart';

class DateFormatUtil {
  static String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  // 26/12/2025 3:45 PM
  static String formatDateTimeAmPm(String dateString) {
    try {
      final date = DateTime.parse(dateString);

      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final amPm = date.hour >= 12 ? 'PM' : 'AM';

      return '${date.day}/${date.month}/${date.year} '
          '$hour:$minute $amPm';
    } catch (e) {
      return dateString;
    }
  }

  static String formatNotificationDate(DateTime date) {
    final month = DateFormat('MMMM').format(date);
    final day = date.day;
    final year = date.year;
    final hour = date.hour;
    final minute = date.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');

    return '$month $day, $year at ${displayHour.toString().padLeft(2, '0')}:$displayMinute $period';
  }

  static String timeAgoSinceDate({
    required DateTime dateTime,
    bool numericDates = true,
  }) {
    final localDate = dateTime.toLocal();
    final now = DateTime.now();
    final difference = now.difference(localDate);

    if (difference.inSeconds < 10) {
      return 'Just now';
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return (difference.inMinutes == 1)
          ? (numericDates ? '1 minute ago' : 'A minute ago')
          : '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return (difference.inHours == 1)
          ? (numericDates ? '1 hour ago' : 'An hour ago')
          : '${difference.inHours} hours ago';
    } else if (difference.inDays < 3) {
      return (difference.inDays == 1)
          ? (numericDates ? '1 day ago' : 'Yesterday')
          : '${difference.inDays} days ago';
    }

    return DateFormat('MMM d, y • h:mm a').format(localDate);
  }
}
