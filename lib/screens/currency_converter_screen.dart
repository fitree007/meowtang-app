import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../theme/meow_theme.dart';
import '../services/currency_exchange_service.dart';
import '../utils/format_utils.dart';
import 'add_transaction_screen.dart';
import 'zakat_calculator_screen.dart';

class CurrencyConverterScreen extends StatefulWidget {
  final ExpenseController controller;
  final String initialSourceCurrency;

  const CurrencyConverterScreen({
    super.key,
    required this.controller,
    this.initialSourceCurrency = 'sar',
  });

  @override
  State<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  late String _fromCurrency;
  String _toCurrency = 'thb';
  final TextEditingController _amountController = TextEditingController(text: '100');
  double _inputAmount = 100.0;
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fromCurrency = widget.initialSourceCurrency;
    _refreshRates();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _refreshRates() async {
    setState(() => _isLoading = true);
    await CurrencyExchangeService.fetchLatestRates();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onAmountChanged(String val) {
    final parsed = double.tryParse(val.replaceAll(',', '')) ?? 0.0;
    setState(() => _inputAmount = parsed);
  }

  void _swapCurrencies() {
    HapticFeedback.mediumImpact();
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
  }

  void _openCurrencyPicker({required bool isSource}) {
    HapticFeedback.selectionClick();
    final isDark = widget.controller.isDarkMode;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final cardBg = isDark ? MeowTheme.navySurface : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String filter = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final list = CurrencyExchangeService.supportedCurrencies.values.where((c) {
              if (filter.isEmpty) return true;
              final q = filter.toLowerCase();
              return c.code.toLowerCase().contains(q) ||
                  c.nameTh.toLowerCase().contains(q) ||
                  c.nameEn.toLowerCase().contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isSource ? 'เลือกสกุลเงินต้นทาง' : 'เลือกสกุลเงินปลายทาง',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    style: TextStyle(color: textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'ค้นหาชื่อสกุลเงิน หรือรหัส เช่น SAR, USD, JPY...',
                      hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onChanged: (val) => setModalState(() => filter = val),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, idx) {
                        final item = list[idx];
                        final isSelected = isSource ? (_fromCurrency == item.code) : (_toCurrency == item.code);
                        final rateToThb = CurrencyExchangeService.getRateToThb(item.code);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          leading: Text(item.flag, style: const TextStyle(fontSize: 26)),
                          title: Row(
                            children: [
                              Text(item.code.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.nameTh,
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey[700]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            item.code == 'thb'
                                ? 'สกุลเงินหลัก (1.00 ฿)'
                                : '1 ${item.code.toUpperCase()} ≈ ฿${CurrencyFormat.format(rateToThb)}',
                            style: const TextStyle(fontSize: 11, color: MeowTheme.actionBlue),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded, color: MeowTheme.incomeGreen, size: 22)
                              : null,
                          onTap: () {
                            setState(() {
                              if (isSource) {
                                _fromCurrency = item.code;
                              } else {
                                _toCurrency = item.code;
                              }
                            });
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _recordAsExpense(double calculatedThb) {
    HapticFeedback.mediumImpact();
    final fromInfo = CurrencyExchangeService.supportedCurrencies[_fromCurrency] ??
        CurrencyInfo(code: _fromCurrency, nameTh: _fromCurrency.toUpperCase(), nameEn: '', symbol: '', flag: '🌐');

    final noteText = 'จ่ายด้วย ${FormatUtils.formatCurrency(_inputAmount)} ${fromInfo.code.toUpperCase()} (เรท 1 ${fromInfo.code.toUpperCase()} = ${FormatUtils.formatCurrency(CurrencyExchangeService.getRateToThb(_fromCurrency))} THB)';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          controller: widget.controller,
          initialAmount: calculatedThb,
          initialNote: noteText,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = widget.controller.currentTheme;
    final isDark = widget.controller.isDarkMode;
    final isEn = widget.controller.isEnglish;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardBg = isDark ? MeowTheme.navySurface : Colors.white;
    final borderColor = isDark ? MeowTheme.borderColor : const Color(0xFFE2E8F0);

    final fromInfo = CurrencyExchangeService.supportedCurrencies[_fromCurrency] ??
        CurrencyInfo(code: _fromCurrency, nameTh: _fromCurrency.toUpperCase(), nameEn: '', symbol: '', flag: '🌐');
    final toInfo = CurrencyExchangeService.supportedCurrencies[_toCurrency] ??
        CurrencyInfo(code: _toCurrency, nameTh: _toCurrency.toUpperCase(), nameEn: '', symbol: '', flag: '🌐');

    final convertedAmount = CurrencyExchangeService.convert(_inputAmount, _fromCurrency, _toCurrency);
    final unitRate = CurrencyExchangeService.convert(1.0, _fromCurrency, _toCurrency);

    final goldPricePerBaht = CurrencyExchangeService.getGoldPricePerBahtWeight();
    final silverPricePerGram = CurrencyExchangeService.getSilverPricePerGram();

    return Scaffold(
      backgroundColor: currentTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Text('💱 ', style: TextStyle(fontSize: 18)),
            Expanded(
              child: Text(
                isEn ? 'Live Currency Converter' : 'แปลงค่าเงิน & ตลาดอัตราแลกเปลี่ยน',
                style: TextStyle(color: textPrimary, fontSize: 16.5, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: MeowTheme.mustardYellow))
                : Icon(Icons.refresh_rounded, color: textPrimary, size: 22),
            onPressed: _refreshRates,
            tooltip: 'อัปเดตเรทสด',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
        children: [
          // 1. Live Exchange Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F1E36) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: MeowTheme.incomeGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    CurrencyExchangeService.getLastUpdatedText(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                    ),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: MeowTheme.mustardYellow.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Real-time 🛡️',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: MeowTheme.mustardYellow),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Interactive Two-Way Converter Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Source Currency Box
                _buildCurrencyBox(
                  label: 'คุณจ่าย (สกุลเงินต้นทาง)',
                  currencyInfo: fromInfo,
                  isSource: true,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  isDark: isDark,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: '0.00',
                    ),
                    onChanged: _onAmountChanged,
                  ),
                ),
                const SizedBox(height: 8),

                // Quick Amount Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickChip('+10', 10),
                      _buildQuickChip('+50', 50),
                      _buildQuickChip('+100', 100),
                      _buildQuickChip('+500', 500),
                      _buildQuickChip('+1,000', 1000),
                      _buildQuickChip('+5,000', 5000),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Swap Button Row
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const Divider(),
                    GestureDetector(
                      onTap: _swapCurrencies,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: MeowTheme.mustardYellow,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.swap_vert_rounded, color: Colors.black87, size: 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Target Currency Box
                _buildCurrencyBox(
                  label: 'แปลงเป็นเงินไทย (หรือสกุลปลายทาง)',
                  currencyInfo: toInfo,
                  isSource: false,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  isDark: isDark,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      CurrencyFormat.format(convertedAmount),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: MeowTheme.incomeGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Rate Equation Box (Wrapped for overflow prevention)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F1E36) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        '1 ${fromInfo.code.toUpperCase()} = ${unitRate.toStringAsFixed(4)} ${toInfo.code.toUpperCase()}',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      Text(
                        '1 ${toInfo.code.toUpperCase()} = ${(1.0 / (unitRate > 0 ? unitRate : 1.0)).toStringAsFixed(4)} ${fromInfo.code.toUpperCase()}',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action: Use this amount in Expense Tracker
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MeowTheme.mustardYellow,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      final thbValue = _toCurrency == 'thb'
                          ? convertedAmount
                          : CurrencyExchangeService.convert(_inputAmount, _fromCurrency, 'thb');
                      _recordAsExpense(thbValue);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_circle_outline_rounded, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'บันทึกเป็นรายจ่าย (฿${CurrencyFormat.format(_toCurrency == "thb" ? convertedAmount : CurrencyExchangeService.convert(_inputAmount, _fromCurrency, "thb"))})',
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Live Precious Metals Card (ทองคำแท่ง & ทองรูปพรรณ & โลหะเงิน)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Text('🥇 ', style: TextStyle(fontSize: 18)),
                              Flexible(
                                child: Text(
                                  'ราคาทองคำ & โลหะเงินสมาคมไทย',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFFD97706)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            CurrencyExchangeService.getGoldLastUpdatedText(),
                            style: TextStyle(fontSize: 10.5, color: textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ZakatCalculatorScreen(controller: widget.controller),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('คำนวณซากาต ➔', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 2 Columns: ทองคำแท่ง & ทองรูปพรรณ
                Row(
                  children: [
                    // 1. ทองคำแท่ง
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('🥇 ทองคำแท่ง', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(color: const Color(0xFFD97706).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                                  child: const Text('96.5%', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text('ขายออก: ฿${CurrencyFormat.format(CurrencyExchangeService.getGoldBarSellPrice())}',
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text('รับซื้อ: ฿${CurrencyFormat.format(CurrencyExchangeService.getGoldBarBuyPrice())}',
                                  style: TextStyle(fontSize: 11, color: textSecondary)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 2. ทองรูปพรรณ
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('📿 ทองรูปพรรณ', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(color: const Color(0xFFB45309).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                                  child: const Text('96.5%', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text('ขายออก: ฿${CurrencyFormat.format(CurrencyExchangeService.getGoldOrnamentSellPrice())}',
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text('ฐานภาษี: ฿${CurrencyFormat.format(CurrencyExchangeService.getGoldOrnamentBuyPrice())}',
                                  style: TextStyle(fontSize: 11, color: textSecondary)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 3. โลหะเงินบริสุทธิ์ (Silver)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text('🥈 โลหะเงินบริสุทธิ์ (XAG)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Text(
                        '฿${FormatUtils.formatCurrency(silverPricePerGram)} / กรัม',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // 4. Live Rates Comparison Table
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ตารางเรทแลกเปลี่ยนสด (เทียบเงิน 1 บาทไทย 🇹🇭)',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Search Field for Rates Table
          TextField(
            style: TextStyle(color: textPrimary, fontSize: 12.5),
            decoration: InputDecoration(
              hintText: 'ค้นหาสกุลเงินในตาราง เช่น USD, MYR, SAR...',
              hintStyle: const TextStyle(fontSize: 11.5, color: Colors.grey),
              prefixIcon: const Icon(Icons.filter_list_rounded, size: 18),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F1E36) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 10),

          // Rates List
          ..._buildRatesList(cardBg, borderColor, textPrimary, textSecondary),
        ],
      ),
    );
  }

  Widget _buildCurrencyBox({
    required String label,
    required CurrencyInfo currencyInfo,
    required bool isSource,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1E36) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: () => _openCurrencyPicker(isSource: isSource),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      Text(currencyInfo.flag, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 6),
                      Text(currencyInfo.code.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: child),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, double addAmount) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        backgroundColor: widget.controller.isDarkMode ? Colors.white10 : const Color(0xFFF1F5F9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.zero,
        onPressed: () {
          HapticFeedback.selectionClick();
          final newAmount = _inputAmount + addAmount;
          setState(() {
            _inputAmount = newAmount;
            _amountController.text = newAmount.toStringAsFixed(0);
          });
        },
      ),
    );
  }

  List<Widget> _buildRatesList(Color cardBg, Color borderColor, Color textPrimary, Color textSecondary) {
    final items = CurrencyExchangeService.getPopularRateItems().where((item) {
      if (item.info.code == 'thb') return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return item.info.code.toLowerCase().contains(q) ||
          item.info.nameTh.toLowerCase().contains(q) ||
          item.info.nameEn.toLowerCase().contains(q);
    }).toList();

    return items.map((item) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Text(item.info.flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(item.info.code.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: textPrimary)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.info.nameTh,
                          style: TextStyle(fontSize: 11, color: textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '100 ฿ = ${FormatUtils.formatCurrency(100.0 * item.thbToRate)} ${item.info.code.toUpperCase()}',
                    style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '฿${CurrencyFormat.format(item.rateToThb)}',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: MeowTheme.actionBlue),
                ),
                Text(
                  'ต่อ 1 ${item.info.code.toUpperCase()}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }
}
