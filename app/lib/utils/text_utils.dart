import 'package:intl/intl.dart';

String formatNumberWithComma(double? number) {
  if (number == null) return '0.00';
  return number.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (Match match) => '${match[1]},',
      );
}

String formatTime(String input) {
  try {
    DateTime dateTime;

    // Check if the input contains a full timestamp
    if (input.contains('-')) {
      // Parse a full timestamp like "2025-03-10 22:19:45.573278"
      dateTime = DateTime.parse(input);
    } else {
      // If only time is provided, assume today's date
      DateTime now = DateTime.now();
      List<String> timeParts = input.split('.')[0].split(':');

      if (timeParts.length < 3) {
        throw FormatException("Invalid time format");
      }

      dateTime = DateTime(now.year, now.month, now.day, int.parse(timeParts[0]),
          int.parse(timeParts[1]), int.parse(timeParts[2]));
    }

    // Format the date and time
    return DateFormat("dd MMM yyyy | HH:mm").format(dateTime);
  } catch (e) {
    return "Invalid time input";
  }
}
