import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../services/currency_exchange_service.dart';
import '../utils/format_utils.dart';
import '../theme/app_theme_model.dart';
import '../widgets/meow_fx.dart';
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
  bool _showAllRates = false;
  static const int _collapsedRateCount = 6;

  static const List<double> _quickAmounts = [50, 100, 500, 1000];

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

  void _setQuickAmount(double amount) {
    HapticFeedback.selectionClick();
    setState(() {
      _inputAmount = amount;
      _amountController.text = amount.toStringAsFixed(0);
    });
  }

  CurrencyInfo _infoFor(String code) =>
      CurrencyExchangeService.supportedCurrencies[code] ??
      CurrencyInfo(code: code, nameTh: code.toUpperCase(), nameEn: '', symbol: '', flag: '🌐');

  /// "฿3,250.00" for baht, "3,250.00 USD" for anything else.
  String _money(double amount, String code) {
    if (code == 'thb') return '฿${CurrencyFormat.format(amount)}';
    return '${CurrencyFormat.format(amount)} ${code.toUpperCase()}';
  }

  /// "อัปเดตล่าสุด: 9 ต.ค. 2569 เวลา 15:57 น." -> "อัปเดต 15:57 น." when it is today.
  String _shortUpdated(String raw) {
    final text = raw.replaceFirst('อัปเดตล่าสุด: ', '');
    final today = CurrencyExchangeService.formatThaiDateTime(DateTime.now()).split(' เวลา ').first;
    final time = RegExp(r'(\d{1,2}:\d{2}) น\.').firstMatch(text)?.group(1);
    if (time != null && text.startsWith(today)) return 'อัปเดต $time น.';
    return 'อัปเดต ${text.replaceFirst(' เวลา ', ' ')}';
  }

  String _rateText(double rate) {
    if (rate >= 1) return CurrencyFormat.format(rate);
    return rate.toStringAsFixed(4);
  }

  void _openCurrencyPicker({required bool isSource}) {
    HapticFeedback.selectionClick();
    final theme = widget.controller.currentTheme;
    final textPrimary = theme.textColor;
    final textSecondary = theme.textSecondaryColor;
    final cardBg = theme.cardBackground;
    final primary = theme.primaryColor;

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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isSource ? 'เลือกสกุลเงินต้นทาง' : 'เลือกสกุลเงินปลายทาง',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, size: 22, color: textSecondary),
                        tooltip: 'ปิด',
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _SearchField(
                    hint: 'ค้นหาชื่อสกุลเงิน หรือรหัส เช่น SAR, USD, JPY',
                    theme: theme,
                    onChanged: (val) => setModalState(() => filter = val),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, _) => Divider(height: 1, color: theme.borderColor),
                      itemBuilder: (_, idx) {
                        final item = list[idx];
                        final isSelected = isSource ? (_fromCurrency == item.code) : (_toCurrency == item.code);
                        final rateToThb = CurrencyExchangeService.getRateToThb(item.code);

                        return InkWell(
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
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 64),
                            child: Row(
                              children: [
                                _FlagDot(flag: item.flag, size: 40, ring: theme.borderColor),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text.rich(
                                        TextSpan(children: [
                                          TextSpan(
                                            text: item.code.toUpperCase(),
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          TextSpan(
                                            text: ' • ${item.nameTh}',
                                            style: TextStyle(color: textSecondary),
                                          ),
                                        ]),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 14.5, color: textPrimary),
                                      ),
                                      Text(
                                        item.code == 'thb'
                                            ? 'สกุลเงินหลัก (1.00 ฿)'
                                            : '1 ${item.code.toUpperCase()} ≈ ฿${CurrencyFormat.format(rateToThb)}',
                                        style: TextStyle(fontSize: 12, color: textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected) Icon(Icons.check_rounded, color: primary, size: 22),
                              ],
                            ),
                          ),
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
    final theme = widget.controller.currentTheme;
    final isDark = widget.controller.isDarkMode;
    final isEn = widget.controller.isEnglish;
    final textPrimary = theme.textColor;
    final textSecondary = theme.textSecondaryColor;
    final cardBg = theme.cardBackground;
    final borderColor = theme.borderColor;
    final primary = theme.primaryColor;
    final heroText = theme.heroTextColor(isDark);
    final tint = Color.alphaBlend(primary.withValues(alpha: isDark ? 0.14 : 0.06), cardBg);

    final fromInfo = _infoFor(_fromCurrency);
    final toInfo = _infoFor(_toCurrency);

    final convertedAmount = CurrencyExchangeService.convert(_inputAmount, _fromCurrency, _toCurrency);
    final unitRate = CurrencyExchangeService.convert(1.0, _fromCurrency, _toCurrency);
    final thbValue = _toCurrency == 'thb'
        ? convertedAmount
        : CurrencyExchangeService.convert(_inputAmount, _fromCurrency, 'thb');

    final updated = _shortUpdated(CurrencyExchangeService.getLastUpdatedText());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.isHeroLight(isDark) ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackground,
        bottomNavigationBar: _BottomBar(
          theme: theme,
          child: FxPress(
            onTap: () => _recordAsExpense(thbValue),
            child: Container(
              height: 56,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(18)),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: FxProgress(
                  value: thbValue,
                  builder: (_, v) => Text(
                    'บันทึกเป็นรายจ่าย ฿${CurrencyFormat.format(v)}',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                decoration: BoxDecoration(gradient: theme.heroGradient),
                padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 10, 8, 64),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.chevron_left_rounded, color: heroText, size: 28),
                          tooltip: 'ย้อนกลับ',
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            isEn ? 'Currency Converter' : 'แปลงค่าเงิน',
                            style: TextStyle(color: heroText, fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: Material(
                        color: heroText.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: _isLoading ? null : _refreshRates,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 44),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isLoading)
                                    SizedBox(
                                      width: 10,
                                      height: 10,
                                      child: CircularProgressIndicator(strokeWidth: 1.6, color: heroText),
                                    )
                                  else
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle),
                                    ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _isLoading ? 'กำลังอัปเดตเรทสด…' : 'เรทสด • $updated • แตะเพื่อรีเฟรช',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: heroText, fontSize: 12.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Transform.translate(
                offset: const Offset(0, -52),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Converter card
                      FxFadeUp(
                        index: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(22),
                            border: isDark ? Border.all(color: borderColor) : null,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.3 : 0.10),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('คุณจ่าย', style: TextStyle(fontSize: 12.5, color: textSecondary)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _CurrencyPill(
                                          info: fromInfo,
                                          theme: theme,
                                          background: theme.scaffoldBackground,
                                          semantic: 'เลือกสกุลเงินต้นทาง ${fromInfo.nameTh}',
                                          onTap: () => _openCurrencyPicker(isSource: true),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextField(
                                            controller: _amountController,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            textAlign: TextAlign.right,
                                            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: textPrimary),
                                            decoration: InputDecoration(
                                              isDense: true,
                                              border: InputBorder.none,
                                              hintText: '0.00',
                                              hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5)),
                                            ),
                                            onChanged: _onAmountChanged,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Divider band with the swap button
                              SizedBox(
                                height: 48,
                                child: Stack(
                                  children: [
                                    Column(
                                      children: [
                                        Expanded(child: Container(color: cardBg)),
                                        Expanded(child: Container(color: tint)),
                                      ],
                                    ),
                                    Positioned(
                                      left: 16,
                                      right: 16,
                                      top: 23.5,
                                      child: Container(height: 1, color: borderColor),
                                    ),
                                    Positioned(
                                      right: 40,
                                      top: 0,
                                      child: Semantics(
                                        button: true,
                                        label: 'สลับสกุลเงิน',
                                        child: FxPress(
                                          onTap: _swapCurrencies,
                                          child: Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: primary,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: cardBg, width: 4),
                                            ),
                                            child: const Icon(Icons.swap_vert_rounded, color: Colors.white, size: 20),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                decoration: BoxDecoration(
                                  color: tint,
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('ได้รับ', style: TextStyle(fontSize: 12.5, color: textSecondary)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _CurrencyPill(
                                          info: toInfo,
                                          theme: theme,
                                          background: cardBg,
                                          semantic: 'เลือกสกุลเงินปลายทาง ${toInfo.nameTh}',
                                          onTap: () => _openCurrencyPicker(isSource: false),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.centerRight,
                                              child: FxProgress(
                                                value: convertedAmount,
                                                builder: (_, v) => Text(
                                                  _money(v, _toCurrency),
                                                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: _accentText(theme)),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '1 ${fromInfo.code.toUpperCase()} = ${_toCurrency == 'thb' ? '฿${_rateText(unitRate)}' : '${_rateText(unitRate)} ${toInfo.code.toUpperCase()}'}',
                                      style: TextStyle(fontSize: 12, color: textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Quick amounts
                      Row(
                        children: [
                          for (int i = 0; i < _quickAmounts.length; i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            Expanded(
                              child: _QuickAmount(
                                label: CurrencyFormat.format(_quickAmounts[i], trimZero: true),
                                selected: _inputAmount == _quickAmounts[i],
                                theme: theme,
                                onTap: () => _setQuickAmount(_quickAmounts[i]),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Popular currencies
                      FxFadeUp(
                        index: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'สกุลเงินยอดนิยม',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                                    ),
                                  ),
                                  Text('ราคาต่อ 1 หน่วย', style: TextStyle(fontSize: 12, color: textSecondary)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            _SearchField(
                              hint: 'ค้นหาชื่อประเทศหรือรหัส เช่น SAR, MYR',
                              theme: theme,
                              onChanged: (val) => setState(() => _searchQuery = val),
                            ),
                            const SizedBox(height: 10),
                            _buildRatesCard(theme),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Thai gold association prices (kept from the previous layout)
                      FxFadeUp(index: 2, child: _buildMetalsCard(theme)),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatesCard(AppThemeModel theme) {
    final textPrimary = theme.textColor;
    final textSecondary = theme.textSecondaryColor;
    var items = CurrencyExchangeService.getPopularRateItems().where((item) {
      if (item.info.code == 'thb') return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return item.info.code.toLowerCase().contains(q) ||
          item.info.nameTh.toLowerCase().contains(q) ||
          item.info.nameEn.toLowerCase().contains(q);
    }).toList();
    final total = items.length;
    final collapsed = _searchQuery.isEmpty && !_showAllRates && total > _collapsedRateCount;
    if (collapsed) items = items.take(_collapsedRateCount).toList();

    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: _softCard(theme, 20),
      child: items.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'ไม่พบสกุลเงินที่ค้นหา',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: textSecondary),
              ),
            )
          : Column(
              children: [
                for (int i = 0; i < items.length; i++)
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _fromCurrency = items[i].info.code);
                    },
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 64),
                      decoration: BoxDecoration(
                        border: i == items.length - 1
                            ? null
                            : Border(bottom: BorderSide(color: theme.borderColor)),
                      ),
                      child: Row(
                        children: [
                          _FlagDot(flag: items[i].info.flag, size: 40, ring: theme.borderColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text.rich(
                                  TextSpan(children: [
                                    TextSpan(
                                      text: items[i].info.code.toUpperCase(),
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    TextSpan(
                                      text: ' • ${items[i].info.nameTh}',
                                      style: TextStyle(color: textSecondary),
                                    ),
                                  ]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 14.5, color: textPrimary),
                                ),
                                Text(
                                  '100 ฿ = ${FormatUtils.formatCurrency(100.0 * items[i].thbToRate)} ${items[i].info.code.toUpperCase()}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                '฿${CurrencyFormat.format(items[i].rateToThb)}',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
    if (!collapsed && (_searchQuery.isNotEmpty || total <= _collapsedRateCount)) return card;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card,
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: _accentText(theme),
            minimumSize: const Size(44, 44),
          ),
          onPressed: () => setState(() => _showAllRates = !_showAllRates),
          child: Text(
            collapsed ? 'ดูทั้งหมด $total สกุลเงิน' : 'ย่อรายการ',
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildMetalsCard(AppThemeModel theme) {
    final textPrimary = theme.textColor;
    final textSecondary = theme.textSecondaryColor;
    final silverPricePerGram = CurrencyExchangeService.getSilverPricePerGram();

    Widget row(String label, String sub, String value, {bool last = false}) {
      return Container(
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: theme.borderColor)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                  Text(sub, style: TextStyle(fontSize: 12, color: textSecondary)),
                ],
              ),
            ),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ราคาทองคำ & โลหะเงิน',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                    Text(
                      CurrencyExchangeService.getGoldLastUpdatedText(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ],
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: _accentText(theme),
                  minimumSize: const Size(44, 44),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ZakatCalculatorScreen(controller: widget.controller),
                    ),
                  );
                },
                child: const Text('คำนวณซะกาต', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: _softCard(theme, 20),
          child: Column(
            children: [
              row(
                'ทองคำแท่ง 96.5%',
                'รับซื้อ ฿${CurrencyFormat.format(CurrencyExchangeService.getGoldBarBuyPrice())}',
                '฿${CurrencyFormat.format(CurrencyExchangeService.getGoldBarSellPrice())}',
              ),
              row(
                'ทองรูปพรรณ 96.5%',
                'ฐานภาษี ฿${CurrencyFormat.format(CurrencyExchangeService.getGoldOrnamentBuyPrice())}',
                '฿${CurrencyFormat.format(CurrencyExchangeService.getGoldOrnamentSellPrice())}',
              ),
              row(
                'โลหะเงินบริสุทธิ์ (XAG)',
                'ราคาต่อกรัม',
                '฿${FormatUtils.formatCurrency(silverPricePerGram)}',
                last: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Primary colour for text; lifted towards white in dark mode so it stays readable.
  Color _accentText(AppThemeModel theme) =>
      widget.controller.isDarkMode ? Color.lerp(theme.primaryColor, Colors.white, 0.55)! : theme.primaryColor;

  BoxDecoration _softCard(AppThemeModel theme, double radius) {
    final isDark = widget.controller.isDarkMode;
    return BoxDecoration(
      color: theme.cardBackground,
      borderRadius: BorderRadius.circular(radius),
      border: isDark ? Border.all(color: theme.borderColor) : null,
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: isDark ? 0.2 : 0.06),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

/// Round flag "coin": the flag emoji cropped to a circle with a thin ring.
class _FlagDot extends StatelessWidget {
  final String flag;
  final double size;
  final Color ring;

  const _FlagDot({required this.flag, required this.size, required this.ring});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ring)),
      child: ClipOval(
        child: OverflowBox(
          maxWidth: size * 2,
          maxHeight: size * 2,
          child: Text(flag, style: TextStyle(fontSize: size * 1.05, height: 1.0)),
        ),
      ),
    );
  }
}

class _CurrencyPill extends StatelessWidget {
  final CurrencyInfo info;
  final AppThemeModel theme;
  final Color background;
  final String semantic;
  final VoidCallback onTap;

  const _CurrencyPill({
    required this.info,
    required this.theme,
    required this.background,
    required this.semantic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantic,
      child: Material(
        color: background,
        shape: StadiumBorder(side: BorderSide(color: theme.borderColor)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FlagDot(flag: info.flag, size: 34, ring: theme.borderColor),
                const SizedBox(width: 8),
                Text(
                  info.code.toUpperCase(),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.textColor),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: theme.textColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAmount extends StatelessWidget {
  final String label;
  final bool selected;
  final AppThemeModel theme;
  final VoidCallback onTap;

  const _QuickAmount({required this.label, required this.selected, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = theme.primaryColor;
    return FxPress(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? primary : theme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? primary : theme.borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.white : theme.textColor,
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final String hint;
  final AppThemeModel theme;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.hint, required this.theme, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: theme.borderColor, width: 1.5),
    );
    return TextField(
      style: TextStyle(color: theme.textColor, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14, color: theme.textSecondaryColor),
        prefixIcon: Icon(Icons.search_rounded, size: 20, color: theme.textSecondaryColor),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: theme.cardBackground,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(borderSide: BorderSide(color: theme.primaryColor, width: 1.5)),
      ),
      onChanged: onChanged,
    );
  }
}

class _BottomBar extends StatelessWidget {
  final AppThemeModel theme;
  final Widget child;

  const _BottomBar({required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(top: BorderSide(color: theme.borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: child,
        ),
      ),
    );
  }
}
