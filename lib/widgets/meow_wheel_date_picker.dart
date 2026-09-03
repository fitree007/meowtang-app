import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/meow_theme.dart';

class MeowWheelDatePicker {
  static const List<String> _thaiMonths = [
    'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
    'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
  ];

  static const List<String> _thaiMonthsShort = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
  ];

  static const List<String> _enMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static const List<String> _enMonthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  /// Shows full Day + Month + Year + Hour + Minute interactive wheel picker
  static Future<DateTime?> showWheelDateTimePicker({
    required BuildContext context,
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    bool isEnglish = false,
    bool isDarkMode = false,
    String? title,
  }) async {
    final startYear = (firstDate ?? DateTime(2000)).year;
    final endYear = (lastDate ?? DateTime(2040)).year;
    final years = List.generate(endYear - startYear + 1, (i) => startYear + i);

    int selectedYear = initialDate.year;
    int selectedMonth = initialDate.month;
    int selectedDay = initialDate.day;
    int selectedHour = initialDate.hour;
    int selectedMinute = initialDate.minute;

    final initialYearIndex = years.indexOf(selectedYear).clamp(0, years.length - 1);
    final initialMonthIndex = (selectedMonth - 1).clamp(0, 11);

    int getDaysInMonth(int y, int m) {
      return DateTime(y, m + 1, 0).day;
    }

    int maxDays = getDaysInMonth(selectedYear, selectedMonth);
    if (selectedDay > maxDays) selectedDay = maxDays;
    final initialDayIndex = (selectedDay - 1).clamp(0, maxDays - 1);

    FixedExtentScrollController dayController = FixedExtentScrollController(initialItem: initialDayIndex);
    FixedExtentScrollController monthController = FixedExtentScrollController(initialItem: initialMonthIndex);
    FixedExtentScrollController yearController = FixedExtentScrollController(initialItem: initialYearIndex);
    FixedExtentScrollController hourController = FixedExtentScrollController(initialItem: selectedHour);
    FixedExtentScrollController minuteController = FixedExtentScrollController(initialItem: selectedMinute);

    final result = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: isDarkMode ? MeowTheme.navySurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final daysInCurMonth = getDaysInMonth(selectedYear, selectedMonth);
            final daysList = List.generate(daysInCurMonth, (i) => i + 1);

            final monthName = isEnglish ? _enMonthsShort[selectedMonth - 1] : _thaiMonthsShort[selectedMonth - 1];
            final yearDisplay = isEnglish ? '$selectedYear' : '${(selectedYear + 543) % 100}';
            final timeDisplay = '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}';

            return Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              height: 390,
              child: Column(
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title ?? (isEnglish ? 'Select Date & Time' : 'เลือกวันที่และเวลา'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$selectedDay $monthName $yearDisplay  •  $timeDisplay น.',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: MeowTheme.actionBlue,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.pop(
                            ctx,
                            DateTime(selectedYear, selectedMonth, selectedDay, selectedHour, selectedMinute),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MeowTheme.actionBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(isEnglish ? 'Done' : 'ตกลง', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(height: 14),
                  // Wheel Picker Rows
                  Expanded(
                    child: Stack(
                      children: [
                        Center(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: MeowTheme.actionBlue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: MeowTheme.actionBlue.withValues(alpha: 0.25), width: 1.2),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            // 1. Day Wheel
                            Expanded(
                              flex: 3,
                              child: CupertinoPicker(
                                scrollController: dayController,
                                itemExtent: 38,
                                selectionOverlay: const SizedBox.shrink(),
                                onSelectedItemChanged: (index) {
                                  HapticFeedback.selectionClick();
                                  setModalState(() {
                                    selectedDay = index + 1;
                                  });
                                },
                                children: daysList.map((d) {
                                  return Center(
                                    child: Text(
                                      '$d',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: selectedDay == d ? FontWeight.bold : FontWeight.normal,
                                        color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            // 2. Month Wheel
                            Expanded(
                              flex: 4,
                              child: CupertinoPicker(
                                scrollController: monthController,
                                itemExtent: 38,
                                selectionOverlay: const SizedBox.shrink(),
                                onSelectedItemChanged: (index) {
                                  HapticFeedback.selectionClick();
                                  setModalState(() {
                                    selectedMonth = index + 1;
                                    final curMax = getDaysInMonth(selectedYear, selectedMonth);
                                    if (selectedDay > curMax) {
                                      selectedDay = curMax;
                                    }
                                  });
                                },
                                children: List.generate(12, (index) {
                                  final m = index + 1;
                                  final name = isEnglish ? _enMonthsShort[index] : _thaiMonthsShort[index];
                                  return Center(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: selectedMonth == m ? FontWeight.bold : FontWeight.normal,
                                        color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            // 3. Year Wheel
                            Expanded(
                              flex: 4,
                              child: CupertinoPicker(
                                scrollController: yearController,
                                itemExtent: 38,
                                selectionOverlay: const SizedBox.shrink(),
                                onSelectedItemChanged: (index) {
                                  HapticFeedback.selectionClick();
                                  setModalState(() {
                                    selectedYear = years[index];
                                    final curMax = getDaysInMonth(selectedYear, selectedMonth);
                                    if (selectedDay > curMax) {
                                      selectedDay = curMax;
                                    }
                                  });
                                },
                                children: years.map((y) {
                                  final displayYear = isEnglish ? '$y' : 'พ.ศ. ${y + 543}';
                                  return Center(
                                    child: Text(
                                      displayYear,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: selectedYear == y ? FontWeight.bold : FontWeight.normal,
                                        color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            // Divider for Time
                            Container(width: 1, height: 120, color: Colors.grey.withValues(alpha: 0.2)),

                            // 4. Hour Wheel (00..23)
                            Expanded(
                              flex: 3,
                              child: CupertinoPicker(
                                scrollController: hourController,
                                itemExtent: 38,
                                selectionOverlay: const SizedBox.shrink(),
                                onSelectedItemChanged: (index) {
                                  HapticFeedback.selectionClick();
                                  setModalState(() {
                                    selectedHour = index;
                                  });
                                },
                                children: List.generate(24, (h) {
                                  final hStr = h.toString().padLeft(2, '0');
                                  return Center(
                                    child: Text(
                                      hStr,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: selectedHour == h ? FontWeight.bold : FontWeight.normal,
                                        color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),

                            Text(
                              ':',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white70 : const Color(0xFF1E293B),
                              ),
                            ),

                            // 5. Minute Wheel (00..59)
                            Expanded(
                              flex: 3,
                              child: CupertinoPicker(
                                scrollController: minuteController,
                                itemExtent: 38,
                                selectionOverlay: const SizedBox.shrink(),
                                onSelectedItemChanged: (index) {
                                  HapticFeedback.selectionClick();
                                  setModalState(() {
                                    selectedMinute = index;
                                  });
                                },
                                children: List.generate(60, (m) {
                                  final mStr = m.toString().padLeft(2, '0');
                                  return Center(
                                    child: Text(
                                      mStr,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: selectedMinute == m ? FontWeight.bold : FontWeight.normal,
                                        color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    return result;
  }

  /// Shows full Day + Month + Year vertical wheel scroll picker (preserving hour/minute)
  static Future<DateTime?> showWheelDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    bool isEnglish = false,
    bool isDarkMode = false,
    String? title,
  }) async {
    final startYear = (firstDate ?? DateTime(2000)).year;
    final endYear = (lastDate ?? DateTime(2040)).year;
    final years = List.generate(endYear - startYear + 1, (i) => startYear + i);

    int selectedYear = initialDate.year;
    int selectedMonth = initialDate.month;
    int selectedDay = initialDate.day;

    final initialYearIndex = years.indexOf(selectedYear).clamp(0, years.length - 1);
    final initialMonthIndex = (selectedMonth - 1).clamp(0, 11);

    int getDaysInMonth(int y, int m) {
      return DateTime(y, m + 1, 0).day;
    }

    int maxDays = getDaysInMonth(selectedYear, selectedMonth);
    if (selectedDay > maxDays) selectedDay = maxDays;
    final initialDayIndex = (selectedDay - 1).clamp(0, maxDays - 1);

    FixedExtentScrollController dayController = FixedExtentScrollController(initialItem: initialDayIndex);
    FixedExtentScrollController monthController = FixedExtentScrollController(initialItem: initialMonthIndex);
    FixedExtentScrollController yearController = FixedExtentScrollController(initialItem: initialYearIndex);

    final result = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: isDarkMode ? MeowTheme.navySurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final daysInCurMonth = getDaysInMonth(selectedYear, selectedMonth);
            final daysList = List.generate(daysInCurMonth, (i) => i + 1);

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              height: 360,
              child: Column(
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title ?? (isEnglish ? 'Select Date' : 'เลือกวันที่'),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          // Preserve initial hour and minute to prevent 00:00 bug
                          Navigator.pop(
                            ctx,
                            DateTime(selectedYear, selectedMonth, selectedDay, initialDate.hour, initialDate.minute),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: MeowTheme.actionBlue,
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        child: Text(isEnglish ? 'Done' : 'ตกลง'),
                      ),
                    ],
                  ),
                  const Divider(height: 12),
                  // Wheel Picker Rows
                  Expanded(
                    child: Stack(
                      children: [
                        Center(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: MeowTheme.actionBlue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: MeowTheme.actionBlue.withValues(alpha: 0.25), width: 1.2),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            // 1. Day Wheel
                            Expanded(
                              flex: 2,
                              child: CupertinoPicker(
                                scrollController: dayController,
                                itemExtent: 40,
                                selectionOverlay: const SizedBox.shrink(),
                                onSelectedItemChanged: (index) {
                                  HapticFeedback.selectionClick();
                                  setModalState(() {
                                    selectedDay = index + 1;
                                  });
                                },
                                children: daysList.map((d) {
                                  return Center(
                                    child: Text(
                                      '$d',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: selectedDay == d ? FontWeight.bold : FontWeight.normal,
                                        color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            // 2. Month Wheel
                            Expanded(
                              flex: 3,
                              child: CupertinoPicker(
                                scrollController: monthController,
                                itemExtent: 40,
                                selectionOverlay: const SizedBox.shrink(),
                                onSelectedItemChanged: (index) {
                                  HapticFeedback.selectionClick();
                                  setModalState(() {
                                    selectedMonth = index + 1;
                                    final curMax = getDaysInMonth(selectedYear, selectedMonth);
                                    if (selectedDay > curMax) {
                                      selectedDay = curMax;
                                    }
                                  });
                                },
                                children: List.generate(12, (index) {
                                  final m = index + 1;
                                  final name = isEnglish ? _enMonths[index] : _thaiMonths[index];
                                  return Center(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: selectedMonth == m ? FontWeight.bold : FontWeight.normal,
                                        color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            // 3. Year Wheel (พ.ศ. / ค.ศ.)
                            Expanded(
                              flex: 3,
                              child: CupertinoPicker(
                                scrollController: yearController,
                                itemExtent: 40,
                                selectionOverlay: const SizedBox.shrink(),
                                onSelectedItemChanged: (index) {
                                  HapticFeedback.selectionClick();
                                  setModalState(() {
                                    selectedYear = years[index];
                                    final curMax = getDaysInMonth(selectedYear, selectedMonth);
                                    if (selectedDay > curMax) {
                                      selectedDay = curMax;
                                    }
                                  });
                                },
                                children: years.map((y) {
                                  final displayYear = isEnglish ? '$y' : 'พ.ศ. ${y + 543}';
                                  return Center(
                                    child: Text(
                                      displayYear,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: selectedYear == y ? FontWeight.bold : FontWeight.normal,
                                        color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    return result;
  }

  /// Shows Month + Year vertical wheel scroll picker
  static Future<DateTime?> showWheelMonthYearPicker({
    required BuildContext context,
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    bool isEnglish = false,
    bool isDarkMode = false,
    String? title,
  }) async {
    final startYear = (firstDate ?? DateTime(2000)).year;
    final endYear = (lastDate ?? DateTime(2040)).year;
    final years = List.generate(endYear - startYear + 1, (i) => startYear + i);

    int selectedYear = initialDate.year;
    int selectedMonth = initialDate.month;

    final initialYearIndex = years.indexOf(selectedYear).clamp(0, years.length - 1);
    final initialMonthIndex = (selectedMonth - 1).clamp(0, 11);

    FixedExtentScrollController monthController = FixedExtentScrollController(initialItem: initialMonthIndex);
    FixedExtentScrollController yearController = FixedExtentScrollController(initialItem: initialYearIndex);

    final result = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: isDarkMode ? MeowTheme.navySurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              height: 350,
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title ?? (isEnglish ? 'Select Month & Year' : 'เลือกเดือนและปี'),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.pop(ctx, DateTime(selectedYear, selectedMonth, 1));
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: MeowTheme.actionBlue,
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        child: Text(isEnglish ? 'Done' : 'ตกลง'),
                      ),
                    ],
                  ),
                  const Divider(height: 12),
                  Expanded(
                    child: Stack(
                      children: [
                        Center(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: MeowTheme.actionBlue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: MeowTheme.actionBlue.withValues(alpha: 0.25), width: 1.2),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            // 1. Month Wheel
                            Expanded(
                              flex: 3,
                              child: CupertinoPicker(
                                scrollController: monthController,
                                itemExtent: 40,
                                selectionOverlay: const SizedBox.shrink(),
                                onSelectedItemChanged: (index) {
                                  HapticFeedback.selectionClick();
                                  setModalState(() {
                                    selectedMonth = index + 1;
                                  });
                                },
                                children: List.generate(12, (index) {
                                  final m = index + 1;
                                  final name = isEnglish ? _enMonths[index] : _thaiMonths[index];
                                  return Center(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: selectedMonth == m ? FontWeight.bold : FontWeight.normal,
                                        color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            // 2. Year Wheel
                            Expanded(
                              flex: 3,
                              child: CupertinoPicker(
                                scrollController: yearController,
                                itemExtent: 40,
                                selectionOverlay: const SizedBox.shrink(),
                                onSelectedItemChanged: (index) {
                                  HapticFeedback.selectionClick();
                                  setModalState(() {
                                    selectedYear = years[index];
                                  });
                                },
                                children: years.map((y) {
                                  final displayYear = isEnglish ? '$y' : 'พ.ศ. ${y + 543}';
                                  return Center(
                                    child: Text(
                                      displayYear,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: selectedYear == y ? FontWeight.bold : FontWeight.normal,
                                        color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    return result;
  }

  /// Shows Year-only vertical wheel scroll picker
  static Future<int?> showWheelYearPicker({
    required BuildContext context,
    required int initialYear,
    int startYear = 2000,
    int endYear = 2040,
    bool isEnglish = false,
    bool isDarkMode = false,
    String? title,
  }) async {
    final years = List.generate(endYear - startYear + 1, (i) => startYear + i);
    int selectedYear = initialYear;
    final initialYearIndex = years.indexOf(selectedYear).clamp(0, years.length - 1);
    FixedExtentScrollController yearController = FixedExtentScrollController(initialItem: initialYearIndex);

    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: isDarkMode ? MeowTheme.navySurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              height: 320,
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title ?? (isEnglish ? 'Select Year' : 'เลือกปี'),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.pop(ctx, selectedYear);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: MeowTheme.actionBlue,
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        child: Text(isEnglish ? 'Done' : 'ตกลง'),
                      ),
                    ],
                  ),
                  const Divider(height: 12),
                  Expanded(
                    child: Stack(
                      children: [
                        Center(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: MeowTheme.actionBlue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: MeowTheme.actionBlue.withValues(alpha: 0.25), width: 1.2),
                            ),
                          ),
                        ),
                        CupertinoPicker(
                          scrollController: yearController,
                          itemExtent: 40,
                          selectionOverlay: const SizedBox.shrink(),
                          onSelectedItemChanged: (index) {
                            HapticFeedback.selectionClick();
                            setModalState(() {
                              selectedYear = years[index];
                            });
                          },
                          children: years.map((y) {
                            final displayYear = isEnglish ? '$y' : 'ปี พ.ศ. ${y + 543}';
                            return Center(
                              child: Text(
                                displayYear,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: selectedYear == y ? FontWeight.bold : FontWeight.normal,
                                  color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    return result;
  }
}
