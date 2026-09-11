import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction_item.dart';
import '../models/category_item.dart';
import '../theme/meow_theme.dart';
import '../utils/format_utils.dart';

class AnalyticsCarouselChartCard extends StatefulWidget {
  final List<TransactionItem> transactions;
  final TransactionType selectedType;
  final double totalAmount;
  final String periodTypeStr; // 'year', 'month', 'day', 'customRange', 'allTime'
  final DateTime anchorDate;
  final bool isDark;
  final bool isEnglish;
  final List<CategoryItem> allCategories;
  final bool isProcessingSlips;
  final bool isInitialScan;
  final bool hasNoTransactionsAtAll;
  final VoidCallback? onTriggerScan;

  const AnalyticsCarouselChartCard({
    super.key,
    required this.transactions,
    required this.selectedType,
    required this.totalAmount,
    required this.periodTypeStr,
    required this.anchorDate,
    required this.isDark,
    this.isEnglish = false,
    required this.allCategories,
    this.isProcessingSlips = false,
    this.isInitialScan = false,
    this.hasNoTransactionsAtAll = false,
    this.onTriggerScan,
  });

  @override
  State<AnalyticsCarouselChartCard> createState() => _AnalyticsCarouselChartCardState();
}

class _AnalyticsCarouselChartCardState extends State<AnalyticsCarouselChartCard>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _selectedTrendMonthIndex = -1;

  late AnimationController _animController;
  late Animation<double> _curvedAnim;

  static const List<Color> _chartPalette = [
    Color(0xFFFFD166), // Soft Yellow / Amber
    Color(0xFF38BDF8), // Sky Cyan
    Color(0xFFF72585), // Soft Rose / Pink
    Color(0xFF10B981), // Emerald / Teal
    Color(0xFF8B5CF6), // Purple
    Color(0xFFFB8500), // Orange
    Color(0xFF3B82F6), // Royal Blue
    Color(0xFF06D6A0), // Green
    Color(0xFFA855F7), // Neon Purple
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _curvedAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward(from: 0.0);
  }

  @override
  void didUpdateWidget(covariant AnalyticsCarouselChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool typeChanged = oldWidget.selectedType != widget.selectedType;
    final bool amountChanged = oldWidget.totalAmount != widget.totalAmount;
    final bool periodChanged = oldWidget.periodTypeStr != widget.periodTypeStr;
    final bool countChanged = oldWidget.transactions.length != widget.transactions.length;

    if (typeChanged || amountChanged || periodChanged || countChanged) {
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _triggerSlideAnimation() {
    _animController.forward(from: 0.0);
  }

  void _goToSlide(int index) {
    HapticFeedback.selectionClick();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage = index);
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDark ? MeowTheme.navySurface : Colors.white;
    final borderColor = widget.isDark ? MeowTheme.borderColor : const Color(0xFFE2E8F0);
    final textPrimary = widget.isDark ? Colors.white : const Color(0xFF0F172A);

    final bool showProcessingCard = widget.isProcessingSlips && widget.isInitialScan;

    if (showProcessingCard) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 58,
                  height: 58,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                    ),
                  ),
                ),
                Icon(
                  Icons.receipt_long_rounded,
                  color: widget.isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              widget.isEnglish
                  ? 'Processing slips on device...'
                  : 'กำลังประมวลผลสลิปในเครื่อง...',
              style: TextStyle(
                color: textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              widget.isEnglish
                  ? 'Searching and reading bank slips automatically.\nCharts will appear once completed.'
                  : 'ระบบกำลังค้นหาและอ่านสลิปธนาคารอัตโนมัติ\nกราฟจะแสดงทันทีเมื่อเสร็จสิ้น',
              style: TextStyle(
                color: widget.isDark ? Colors.white60 : const Color(0xFF64748B),
                fontSize: 12.5,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.onTriggerScan != null && !widget.isProcessingSlips) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: widget.onTriggerScan,
                icon: const Icon(Icons.sync_rounded, size: 16),
                label: Text(
                  widget.isEnglish ? 'Scan Slips Now' : 'ค้นหาและอ่านสลิปในเครื่อง',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: widget.isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                  side: BorderSide(
                    color: widget.isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.5) : const Color(0xFF2563EB).withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (widget.transactions.isEmpty || widget.totalAmount <= 0) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.pie_chart_outline_rounded, color: widget.isDark ? Colors.white38 : Colors.grey, size: 44),
            const SizedBox(height: 8),
            Text(
              widget.isEnglish ? 'No transaction data for this period' : 'ไม่มีข้อมูลธุรกรรมในช่วงเวลานี้',
              style: TextStyle(color: widget.isDark ? Colors.white54 : Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _curvedAnim,
      builder: (context, _) {
        final animProgress = _curvedAnim.value;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // 1. Chart Type Switcher Tabs (เอาเลข 1-3 ออกตามสั่ง)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: widget.isDark ? const Color(0xFF0F1E36) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      _buildChartTypeTab(0, 'หมวดหมู่', Icons.donut_large_rounded),
                      _buildChartTypeTab(1, 'สัปดาห์ 1-4', Icons.calendar_view_week_rounded),
                      _buildChartTypeTab(2, 'แนวโน้มรายปี', Icons.auto_graph_rounded),
                    ],
                  ),
                ),
              ),

              // Micro Hint Label
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 2),
                child: Text(
                  '💡 แตะเลือกดูกราฟได้ 3 แบบ หรือปัดซ้าย-ขวา',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: widget.isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                ),
              ),

              // 2. Carousel Pages
              SizedBox(
                height: 235,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    HapticFeedback.selectionClick();
                    setState(() => _currentPage = index);
                    _triggerSlideAnimation();
                  },
                  children: [
                    _buildSlide1CategoryDonut(animProgress),
                    _buildSlide2PeriodDonut(animProgress),
                    _buildSlide3CoolTrendLine(animProgress),
                  ],
                ),
              ),

              // 3. Navigation Controls (Arrow Buttons & Dots)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      color: _currentPage > 0 ? textPrimary : Colors.grey.withValues(alpha: 0.3),
                      onPressed: _currentPage > 0 ? () => _goToSlide(_currentPage - 1) : null,
                    ),

                    // Page indicator dots
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        final isSel = i == _currentPage;
                        return GestureDetector(
                          onTap: () => _goToSlide(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isSel ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSel
                                  ? MeowTheme.mustardYellow
                                  : (widget.isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      }),
                    ),

                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      color: _currentPage < 2 ? textPrimary : Colors.grey.withValues(alpha: 0.3),
                      onPressed: _currentPage < 2 ? () => _goToSlide(_currentPage + 1) : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartTypeTab(int index, String title, IconData icon) {
    final isSel = _currentPage == index;
    final textPrimary = widget.isDark ? Colors.white : const Color(0xFF0F172A);

    return Expanded(
      child: GestureDetector(
        onTap: () => _goToSlide(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 6.5),
          decoration: BoxDecoration(
            color: isSel
                ? (widget.isDark ? MeowTheme.navySurface : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: isSel
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSel ? MeowTheme.mustardYellow : (widget.isDark ? Colors.white54 : Colors.grey),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSel ? textPrimary : (widget.isDark ? Colors.white54 : Colors.grey),
                    fontSize: 11.5,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // SLIDE 1: Donut Chart by Category (แสดงถึง 8 หมวดหมู่ ฟอนต์กะทัดรัด เห็นเยอะขึ้น)
  // ==========================================================
  Widget _buildSlide1CategoryDonut(double progress) {
    final textColor = widget.isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    final Map<String, double> catMap = {};
    for (final tx in widget.transactions) {
      catMap[tx.categoryName] = (catMap[tx.categoryName] ?? 0.0) + tx.amount;
    }

    final sorted = catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final List<Map<String, dynamic>> displayItems = [];
    double othersSum = 0.0;

    // Show up to 8 categories with compact font
    const maxItems = 8;
    for (int i = 0; i < sorted.length; i++) {
      if (i < maxItems) {
        displayItems.add({
          'name': sorted[i].key,
          'amount': sorted[i].value,
          'percent': (sorted[i].value / widget.totalAmount) * 100,
          'color': _chartPalette[i % _chartPalette.length],
        });
      } else {
        othersSum += sorted[i].value;
      }
    }

    if (othersSum > 0) {
      displayItems.add({
        'name': widget.isEnglish ? 'Other' : 'หมวดหมู่อื่นๆ',
        'amount': othersSum,
        'percent': (othersSum / widget.totalAmount) * 100,
        'color': _chartPalette[8],
      });
    }

    final totalFormatted = FormatUtils.formatCurrency(widget.totalAmount * progress);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          // Donut Chart
          Expanded(
            flex: 5,
            child: Center(
              child: SizedBox(
                width: 135,
                height: 135,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(135, 135),
                      painter: _CleanDonutPainter(
                        items: displayItems,
                        total: widget.totalAmount,
                        progress: progress,
                        isDark: widget.isDark,
                      ),
                    ),
                    Transform.scale(
                      scale: 0.85 + (0.15 * progress),
                      child: SizedBox(
                        width: 76,
                        height: 76,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.isEnglish ? 'Total' : 'ยอดรวม',
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    totalFormatted,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Right Category List (กะทัดรัด ชัดเจน เห็นถึง 8 หมวดหมู่)
          Expanded(
            flex: 6,
            child: Transform.translate(
              offset: Offset(15 * (1 - progress), 0),
              child: Opacity(
                opacity: progress.clamp(0.0, 1.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: displayItems.map((item) {
                      final color = item['color'] as Color;
                      final name = item['name'] as String;
                      final pct = (item['percent'] as double) * progress;
                      final amt = (item['amount'] as double) * progress;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1.8),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${pct.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '(${FormatUtils.formatCurrency(amt)})',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SLIDE 2: เรียงสัปดาห์ที่ 1 2 3 4 ตามลำดับวันในเดือนอย่างถูกต้อง
  // ==========================================================
  Widget _buildSlide2PeriodDonut(double progress) {
    final textColor = widget.isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    final List<Map<String, dynamic>> displayItems = [];

    if (widget.periodTypeStr == 'year' || widget.periodTypeStr == 'allTime') {
      const thaiMonthsShort = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
      for (int m = 1; m <= 12; m++) {
        final sum = widget.transactions
            .where((t) => t.date.month == m)
            .fold(0.0, (s, t) => s + t.amount);
        if (sum > 0) {
          displayItems.add({
            'name': thaiMonthsShort[m - 1],
            'subLabel': 'เดือน ${thaiMonthsShort[m - 1]}',
            'amount': sum,
            'percent': (sum / widget.totalAmount) * 100,
            'color': _chartPalette[(m - 1) % _chartPalette.length],
          });
        }
      }
    } else {
      // Monthly: เรียงสัปดาห์ที่ 1, 2, 3, 4, 5 อย่างถูกต้อง
      final Map<int, double> weekMap = {1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0, 5: 0.0};
      for (final tx in widget.transactions) {
        final weekNum = ((tx.date.day - 1) ~/ 7) + 1;
        weekMap[weekNum] = (weekMap[weekNum] ?? 0.0) + tx.amount;
      }

      final weekSubLabels = {
        1: 'วันที่ 1-7',
        2: 'วันที่ 8-14',
        3: 'วันที่ 15-21',
        4: 'วันที่ 22-28',
        5: 'วันที่ 29-สิ้นเดือน',
      };

      for (int w = 1; w <= 5; w++) {
        final amt = weekMap[w] ?? 0.0;
        if (amt > 0 || (w <= 4 && widget.totalAmount > 0)) {
          displayItems.add({
            'name': 'สัปดาห์ที่ $w',
            'subLabel': weekSubLabels[w] ?? '',
            'amount': amt,
            'percent': widget.totalAmount > 0 ? (amt / widget.totalAmount) * 100 : 0.0,
            'color': _chartPalette[(w - 1) % _chartPalette.length],
          });
        }
      }
    }

    final totalFormatted = FormatUtils.formatCurrency(widget.totalAmount * progress);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          // Donut Chart
          Expanded(
            flex: 5,
            child: Center(
              child: SizedBox(
                width: 135,
                height: 135,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(135, 135),
                      painter: _CleanDonutPainter(
                        items: displayItems,
                        total: widget.totalAmount,
                        progress: progress,
                        isDark: widget.isDark,
                      ),
                    ),
                    Transform.scale(
                      scale: 0.85 + (0.15 * progress),
                      child: SizedBox(
                        width: 76,
                        height: 76,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.isEnglish ? 'Total' : 'ยอดรวม',
                                style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    totalFormatted,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Right Week 1 2 3 4 List (เรียงลำดับวันชัดเจน)
          Expanded(
            flex: 6,
            child: Transform.translate(
              offset: Offset(15 * (1 - progress), 0),
              child: Opacity(
                opacity: progress.clamp(0.0, 1.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: displayItems.map((item) {
                      final color = item['color'] as Color;
                      final name = item['name'] as String;
                      final subLabel = item['subLabel'] as String? ?? '';
                      final amt = (item['amount'] as double) * progress;
                      final pct = (item['percent'] as double) * progress;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.2),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      color: subTextColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (subLabel.isNotEmpty)
                                    Text(
                                      subLabel,
                                      style: TextStyle(
                                        color: subTextColor.withValues(alpha: 0.7),
                                        fontSize: 9,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '฿${FormatUtils.formatCurrency(amt)}',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${pct.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SLIDE 3: Cool Futuristic Glowing Trend Chart (พร้อมชี้บอกเดือนและยอดใช้จ่าย)
  // ==========================================================
  Widget _buildSlide3CoolTrendLine(double progress) {
    final textColor = widget.isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final txs = widget.transactions;
    final List<_TrendPoint> points = [];

    final monthLabels = widget.isEnglish
        ? ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
        : const ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
    final monthFull = widget.isEnglish
        ? ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
        : const [
            'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
            'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
          ];
    final year = widget.anchorDate.year;

    int maxMonthIndex = 0;
    double maxMonthAmount = 0.0;

    for (int m = 1; m <= 12; m++) {
      final monthTxs = txs.where((t) => t.date.year == year && t.date.month == m);
      final sum = monthTxs.fold(0.0, (s, t) => s + t.amount);
      if (sum > maxMonthAmount) {
        maxMonthAmount = sum;
        maxMonthIndex = m - 1;
      }
      points.add(_TrendPoint(
        label: monthLabels[m - 1],
        amount: sum,
        color: _chartPalette[(m - 1) % _chartPalette.length],
      ));
    }

    final double avg = (widget.totalAmount / 12.0) * progress;

    double maxVal = points.fold(0.0, (max, p) => p.amount > max ? p.amount : max);
    if (maxVal <= 0) maxVal = 20000.0;
    final ceilMax = ((maxVal / 5000).ceil() * 5000.0).clamp(10000.0, 10000000.0);

    final peakMonthName = monthLabels[maxMonthIndex];

    final activeMonthIdx = (_selectedTrendMonthIndex >= 0 && _selectedTrendMonthIndex < 12)
        ? _selectedTrendMonthIndex
        : (maxMonthAmount > 0 ? maxMonthIndex : (DateTime.now().month - 1));
    final activePoint = points[activeMonthIdx];
    final activePct = widget.totalAmount > 0 ? ((activePoint.amount / widget.totalAmount) * 100).toStringAsFixed(1) : '0';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      widget.isEnglish ? '$year' : 'พ.ศ. ${year + 543}',
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (maxMonthAmount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        widget.isEnglish ? '🔥 Peak: $peakMonthName' : '🔥 พีคสุด: $peakMonthName',
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  Text(
                    widget.isEnglish ? 'Avg ' : 'เฉลี่ย ',
                    style: TextStyle(color: subTextColor, fontSize: 10.5),
                  ),
                  Text(
                    '฿${FormatUtils.formatCurrency(avg)}/${widget.isEnglish ? "mo" : "ด."}',
                    style: const TextStyle(
                      color: Color(0xFFFFD166),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Interactive Tooltip Badge (ชี้บอกยอดเงินเดือนที่เลือก)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: activePoint.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: activePoint.color.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.touch_app_rounded, size: 13, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 4),
                    Text(
                      '${monthFull[activeMonthIdx]} ${widget.isEnglish ? year : year + 543}:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
                    ),
                  ],
                ),
                Text(
                  '฿${FormatUtils.formatCurrency(activePoint.amount)} ($activePct%)',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: activePoint.color),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Glowing Cyber Wave Canvas with touch & drag interaction
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                void updateSelectedMonth(Offset localPos) {
                  final step = constraints.maxWidth / 12.0;
                  final idx = (localPos.dx / step).floor().clamp(0, 11);
                  if (idx != _selectedTrendMonthIndex) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedTrendMonthIndex = idx;
                    });
                  }
                }

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => updateSelectedMonth(d.localPosition),
                  onHorizontalDragUpdate: (d) => updateSelectedMonth(d.localPosition),
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _CoolGlowingTrendPainter(
                      points: points,
                      maxVal: ceilMax,
                      avgVal: avg,
                      maxMonthIndex: maxMonthIndex,
                      selectedMonthIndex: activeMonthIdx,
                      progress: progress,
                      isDark: widget.isDark,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),

          // Clean 12-Month Quick Selector Bar (แสดงครบ 12 เดือนทันที ไม่ต้องเลื่อน)
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            decoration: BoxDecoration(
              color: widget.isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: List.generate(12, (idx) {
                final isSel = idx == activeMonthIdx;
                final isCurrent = (DateTime.now().month - 1) == idx && DateTime.now().year == year;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedTrendMonthIndex = idx;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        color: isSel ? points[idx].color : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: isSel
                              ? points[idx].color
                              : (isCurrent
                                  ? const Color(0xFFFFD166).withValues(alpha: 0.7)
                                  : Colors.transparent),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          monthLabels[idx],
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: isSel ? FontWeight.w900 : (isCurrent ? FontWeight.bold : FontWeight.w500),
                            color: isSel
                                ? Colors.white
                                : (isCurrent ? const Color(0xFFFFD166) : subTextColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendPoint {
  final String label;
  final double amount;
  final Color color;

  _TrendPoint({required this.label, required this.amount, required this.color});
}

class _CleanDonutPainter extends CustomPainter {
  final List<Map<String, dynamic>> items;
  final double total;
  final double progress;
  final bool isDark;

  _CleanDonutPainter({
    required this.items,
    required this.total,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0 || items.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 6;
    const strokeWidth = 18.0;

    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    double startAngle = -math.pi / 2;
    final totalAngle = 2 * math.pi * progress;

    for (final item in items) {
      final amt = item['amount'] as double;
      final color = item['color'] as Color;
      if (amt <= 0) continue;

      final sweepAngle = (amt / total) * totalAngle;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _CleanDonutPainter oldDelegate) => true;
}

/// Cool Glowing Cyber-styled Curved Area Line Painter
class _CoolGlowingTrendPainter extends CustomPainter {
  final List<_TrendPoint> points;
  final double maxVal;
  final double avgVal;
  final int maxMonthIndex;
  final int selectedMonthIndex;
  final double progress;
  final bool isDark;

  _CoolGlowingTrendPainter({
    required this.points,
    required this.maxVal,
    required this.avgVal,
    required this.maxMonthIndex,
    required this.selectedMonthIndex,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final bottomPadding = 12.0;
    final topPadding = 10.0;
    final chartHeight = size.height - bottomPadding - topPadding;
    final stepX = size.width / points.length;

    // 1. Grid Lines (Horizontal Subtle Neon Lines)
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0))
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= 3; i++) {
      final y = topPadding + (chartHeight * (i / 4.0));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Highlight Beam for Selected Month
    if (selectedMonthIndex >= 0 && selectedMonthIndex < points.length) {
      final selX = (selectedMonthIndex * stepX) + (stepX / 2);
      final beamRect = Rect.fromLTWH(selectedMonthIndex * stepX + 1, topPadding, stepX - 2, chartHeight);
      final beamPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            points[selectedMonthIndex].color.withValues(alpha: isDark ? 0.28 : 0.18),
            points[selectedMonthIndex].color.withValues(alpha: 0.02),
          ],
        ).createShader(beamRect);
      canvas.drawRRect(RRect.fromRectAndRadius(beamRect, const Radius.circular(5)), beamPaint);

      // Subtle vertical dash/line marker
      final guidePaint = Paint()
        ..color = points[selectedMonthIndex].color.withValues(alpha: 0.45)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(selX, topPadding), Offset(selX, topPadding + chartHeight), guidePaint);
    }

    // 3. Average Glowing Dashed Line
    if (avgVal > 0 && maxVal > 0) {
      final avgY = topPadding + chartHeight - ((avgVal / maxVal) * chartHeight * progress);
      final avgPaint = Paint()
        ..color = const Color(0xFFFFD166).withValues(alpha: isDark ? 0.4 : 0.6)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      const dashWidth = 4.0;
      const dashSpace = 3.0;
      double startX = 0.0;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, avgY),
          Offset(math.min(startX + dashWidth, size.width), avgY),
          avgPaint,
        );
        startX += dashWidth + dashSpace;
      }
    }

    // Calculate Point Coordinates
    final List<Offset> coords = [];
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final x = (i * stepX) + (stepX / 2);
      final ratio = maxVal > 0 ? (p.amount / maxVal) : 0.0;
      final y = topPadding + chartHeight - (ratio * chartHeight * progress);
      coords.add(Offset(x, y));
    }

    // 4. Smooth Glowing Gradient Area Fill (Under the Curve)
    if (coords.length > 1) {
      final path = Path();
      path.moveTo(coords[0].dx, coords[0].dy);

      for (int i = 0; i < coords.length - 1; i++) {
        final p0 = coords[i];
        final p1 = coords[i + 1];
        final ctrlX = (p0.dx + p1.dx) / 2;
        path.cubicTo(ctrlX, p0.dy, ctrlX, p1.dy, p1.dx, p1.dy);
      }

      final areaPath = Path.from(path);
      areaPath.lineTo(coords.last.dx, topPadding + chartHeight);
      areaPath.lineTo(coords.first.dx, topPadding + chartHeight);
      areaPath.close();

      final areaShader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                const Color(0xFF38BDF8).withValues(alpha: 0.35 * progress),
                const Color(0xFF818CF8).withValues(alpha: 0.15 * progress),
                const Color(0xFF818CF8).withValues(alpha: 0.0),
              ]
            : [
                const Color(0xFF38BDF8).withValues(alpha: 0.25 * progress),
                const Color(0xFF818CF8).withValues(alpha: 0.08 * progress),
                Colors.white.withValues(alpha: 0.0),
              ],
      ).createShader(Rect.fromLTWH(0, topPadding, size.width, chartHeight));

      final areaPaint = Paint()
        ..shader = areaShader
        ..style = PaintingStyle.fill;

      canvas.drawPath(areaPath, areaPaint);

      // Glowing Neon Line Stroke
      final lineShader = const LinearGradient(
        colors: [Color(0xFF38BDF8), Color(0xFF818CF8), Color(0xFFEC4899), Color(0xFFFFD166)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      if (isDark) {
        final glowPaint = Paint()
          ..shader = lineShader
          ..strokeWidth = 4.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
        canvas.drawPath(path, glowPaint);
      }

      final linePaint = Paint()
        ..shader = lineShader
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, linePaint);
    }

    // 5. Point Halos & Node Bullets
    for (int i = 0; i < coords.length; i++) {
      final c = coords[i];
      final p = points[i];
      final isMax = i == maxMonthIndex;
      final isSel = i == selectedMonthIndex;

      if (p.amount > 0 || isSel) {
        // Outer halo
        final haloPaint = Paint()
          ..color = (isSel
                  ? points[i].color
                  : (isMax ? const Color(0xFFEF4444) : const Color(0xFF38BDF8)))
              .withValues(alpha: isSel ? 0.45 : (isMax ? 0.35 : 0.2))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(c, isSel ? 9.0 : (isMax ? 7.0 : 4.5), haloPaint);

        // Core dot
        final dotPaint = Paint()
          ..color = isSel
              ? points[i].color
              : (isMax ? const Color(0xFFEF4444) : Colors.white)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(c, isSel ? 5.0 : (isMax ? 4.0 : 2.5), dotPaint);

        final dotBorder = Paint()
          ..color = isSel ? Colors.white : (isMax ? Colors.white : const Color(0xFF38BDF8))
          ..strokeWidth = isSel ? 2.0 : 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(c, isSel ? 5.0 : (isMax ? 4.0 : 2.5), dotBorder);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CoolGlowingTrendPainter oldDelegate) => true;
}
