// lib/utils/date_utils.dart
import 'package:intl/intl.dart';

String formatUKDate(DateTime date) {
  return DateFormat('dd-MMM-yyyy').format(date);
}

