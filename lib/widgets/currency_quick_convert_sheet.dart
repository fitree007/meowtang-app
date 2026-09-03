import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/currency_exchange_service.dart';
import '../theme/meow_theme.dart';
import '../utils/format_utils.dart';

class CurrencyQuickConvertSheet extends StatefulWidget {
  final bool isDark;
  final ValueChanged<({double thbAmount, String noteTag})> onConverted;

  const CurrencyQuickConvertSheet({
    super.key,
    required this.isDark,
    required this.onConverted,
  });

  static Future<void> show({
    required BuildContext context,
    required bool isDark,
    required ValueChanged<({double thbAmount, String noteTag})> onConverted,
  }) {
    HapticFeedback.selectionClick();
    return showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? MeowTheme.navySurface : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CurrencyQuickConvertSheet(isDark: isDark, onConverted: onConverted),
    );
  }

  @override
  State<CurrencyQuickConvertSheet> createState() => _CurrencyQuickConvertSheetState();
}

class _CurrencyQuickConvertSheetState extends State<CurrencyQuickConvertSheet> {
  String _selectedCurrency = 'sar';
  final TextEditingController _amountController = TextEditingController(text: '100');
  double _inputAmount = 100.0;

  @override
  void initState() {
    super.initState();
    CurrencyExchangeService.fetchLatestRates();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _openFullCurrencySearch() {
    HapticFeedback.selectionClick();
    final allCurrencies = CurrencyExchangeService.supportedCurrencies.values
        .where((c) => c.code != 'xau' && c.code != 'xag' && c.code != 'btc' && c.code != 'thb')
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (searchCtx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = allCurrencies.where((c) {
              if (query.trim().isEmpty) return true;
              final q = query.toLowerCase().trim();
              return c.code.toLowerCase().contains(q) ||
                  c.nameTh.toLowerCase().contains(q) ||
                  c.nameEn.toLowerCase().contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              padding: const EdgeInsets.only(top: 16),
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
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'เลือกสกุลเงินที่ต้องการแปลง',
                          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(searchCtx),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    child: TextField(
                      autofocus: true,
                      onChanged: (val) => setModalState(() => query = val),
                      decoration: InputDecoration(
                        hintText: 'ค้นหาชื่อสกุลเงิน เช่น USD, SAR, MYR, เยน...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: widget.isDark ? MeowTheme.borderColor : const Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final item = filtered[idx];
                        final rate = CurrencyExchangeService.getRateToThb(item.code);
                        final isChosen = _selectedCurrency == item.code;

                        return ListTile(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedCurrency = item.code);
                            Navigator.pop(searchCtx);
                          },
                          leading: Text(item.flag, style: const TextStyle(fontSize: 24)),
                          title: Row(
                            children: [
                              Text(
                                item.code.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isChosen ? MeowTheme.mustardYellowDark : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.nameTh,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          trailing: Text(
                            '1 ${item.code.toUpperCase()} ≈ ฿${rate.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
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

  @override
  Widget build(BuildContext context) {
    final textPrimary = widget.isDark ? Colors.white : const Color(0xFF0F172A);
    final borderColor = widget.isDark ? MeowTheme.borderColor : const Color(0xFFE2E8F0);

    final currencyInfo = CurrencyExchangeService.supportedCurrencies[_selectedCurrency] ??
        CurrencyInfo(code: _selectedCurrency, nameTh: _selectedCurrency.toUpperCase(), nameEn: '', symbol: '', flag: '🌐');

    final rateToThb = CurrencyExchangeService.getRateToThb(_selectedCurrency);
    final calculatedThb = _inputAmount * rateToThb;

    // Popular Quick Currencies: SAR, MYR, USD, JPY, EUR, SGD, CNY, KRW, AED, GBP, AUD, TWD, HKD
    final popularCodes = ['sar', 'myr', 'usd', 'jpy', 'eur', 'sgd', 'cny', 'krw', 'aed', 'gbp', 'aud', 'twd', 'hkd'];

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('💱 ', style: TextStyle(fontSize: 20)),
                  Text(
                    'แปลงค่าเงินต่างประเทศ ➔ เงินบาท',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Horizontal list of popular currency buttons + Search Any Currency Button
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                // Quick Search Button
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: const Icon(Icons.search_rounded, size: 16, color: MeowTheme.textDarkPrimary),
                    label: const Text('ค้นหาทุกสกุลเงิน...'),
                    backgroundColor: MeowTheme.mustardYellow.withValues(alpha: 0.25),
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: MeowTheme.textDarkPrimary,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onPressed: _openFullCurrencySearch,
                  ),
                ),

                // Popular Currency Chips
                ...popularCodes.map((code) {
                  final info = CurrencyExchangeService.supportedCurrencies[code];
                  if (info == null) return const SizedBox.shrink();
                  final isSelected = _selectedCurrency == code;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${info.flag} ${info.code.toUpperCase()}'),
                      selected: isSelected,
                      selectedColor: MeowTheme.mustardYellow,
                      backgroundColor: widget.isDark ? const Color(0xFF0F1E36) : const Color(0xFFF1F5F9),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.black87 : textPrimary,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) {
                        if (val) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedCurrency = code);
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Amount Input Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF0F1E36) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Text(currencyInfo.flag, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            currencyInfo.code.toUpperCase(),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: _openFullCurrencySearch,
                            child: const Text(
                              '(เปลี่ยน)',
                              style: TextStyle(fontSize: 11, color: MeowTheme.actionBlue, decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '1 ${currencyInfo.code.toUpperCase()} ≈ ฿${rateToThb.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 11, color: MeowTheme.actionBlue),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: TextField(
                    controller: _amountController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: '0.00',
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val.replaceAll(',', '')) ?? 0.0;
                      setState(() => _inputAmount = parsed);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Converted Result Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: MeowTheme.incomeGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: MeowTheme.incomeGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'แปลงเป็นเงินไทย (THB):',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: MeowTheme.incomeGreen),
                ),
                Text(
                  '฿${CurrencyFormat.format(calculatedThb)} บาท',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: MeowTheme.incomeGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: MeowTheme.mustardYellow,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                final noteTag = '${_inputAmount.toStringAsFixed(2)} ${currencyInfo.code.toUpperCase()} (เรท ฿${rateToThb.toStringAsFixed(2)})';
                widget.onConverted((thbAmount: calculatedThb, noteTag: noteTag));
                Navigator.pop(context);
              },
              child: Text(
                'ใช้ยอดนี้ (฿${CurrencyFormat.format(calculatedThb)})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
