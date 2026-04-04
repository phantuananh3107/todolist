import 'package:intl/intl.dart';

class Formatters {
  static String date(DateTime? date) {
    if (date == null) return '--';
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
