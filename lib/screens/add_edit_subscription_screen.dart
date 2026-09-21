import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/subscription_item.dart';
import '../state/expense_controller.dart';
import '../services/currency_exchange_service.dart';
import '../utils/format_utils.dart';
import '../widgets/tactile_button.dart';
import '../widgets/bank_badge.dart';
import '../widgets/meow_permission_dialog.dart';
import '../widgets/meow_wheel_date_picker.dart';

class AddEditSubscriptionScreen extends StatefulWidget {
  final ExpenseController controller;
  final SubscriptionItem? existingItem;

  const AddEditSubscriptionScreen({
    super.key,
    required this.controller,
    this.existingItem,
  });

  @override
  State<AddEditSubscriptionScreen> createState() => _AddEditSubscriptionScreenState();
}

class _AddEditSubscriptionScreenState extends State<AddEditSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _notesController;
  final FocusNode _nameFocusNode = FocusNode();

  String _selectedCategory = 'สตรีมมิ่ง & ดูหนัง';
  String _selectedCurrency = 'THB';
  String _billingCycle = 'monthly';
  DateTime _firstChargeDate = DateTime.now();
  DateTime _nextBillingDate = DateTime.now().add(const Duration(days: 30));
  bool _hasTrial = false;
  DateTime _trialEndDate = DateTime.now().add(const Duration(days: 7));
  String _paymentMethod = 'บัตรเครดิต/เดบิต';
  String? _selectedAccountId;
  String? _selectedAccountName;
  bool _enableReminder = true;
  bool _showInOverview = false;
  bool _autoRecordExpense = false;
  String? _logoAssetPath;
  String? _customLogoUrl;
  Color? _customColor;
  int _reminderDaysBefore = 3;
  bool _isActive = true;

  // Duration / End rule state
  String _endRuleType = 'never'; // 'never', 'untilDate', 'fixedCycles'
  DateTime? _endDate;
  int? _totalCycles;
  late TextEditingController _totalCyclesController;
  int _completedCycles = 0;

  List<SubscriptionPreset> _autocompleteSuggestions = [];

  final List<String> _categories = [
    'สตรีมมิ่ง & ดูหนัง',
    'เพลง & พอดแคสต์',
    'สตรีมมิ่ง & ซีรีส์',
    'AI & ซอฟต์แวร์',
    'AI & ตัดต่อวิดีโอ',
    'กราฟิก & ออกแบบ',
    'เอกสาร & พื้นที่จัดเก็บ',
    'พื้นที่จัดเก็บคลาวด์',
    'จัดการงาน & โน้ต',
    'มือถือ & เน็ตบ้าน',
    'สาธารณูปโภค',
    'เกม & บันเทิง',
    'โซเชียล & สื่อสาร',
    'ส่งอาหาร & เดินทาง',
    'ช้อปปิ้งออนไลน์',
    'การเรียนรู้ & คอร์ส',
    'สุขภาพ & ฟิตเนส',
    'อื่นๆ',
  ];

  List<CurrencyInfo> get _allCurrencies {
    return CurrencyExchangeService.supportedCurrencies.values
        .where((c) => !c.isCommodity || c.code == 'btc')
        .toList();
  }

  DateTime _calculateEndDateFromCycles(DateTime startDate, int cycles, String cycle) {
    if (cycles <= 0) return startDate;
    DateTime d = startDate;
    for (int i = 0; i < cycles; i++) {
      if (cycle == 'yearly') {
        d = DateTime(d.year + 1, d.month, d.day);
      } else if (cycle == 'weekly') {
        d = d.add(const Duration(days: 7));
      } else if (cycle == 'quarterly') {
        d = DateTime(d.year, d.month + 3, d.day);
      } else {
        final nextMonth = d.month + 1;
        final nextYear = d.year + (nextMonth > 12 ? 1 : 0);
        final adjustedMonth = nextMonth > 12 ? 1 : nextMonth;
        d = DateTime(nextYear, adjustedMonth, d.day);
      }
    }
    return d;
  }

  int _calculateCyclesBetween(DateTime startDate, DateTime endDate, String cycle) {
    if (endDate.isBefore(startDate)) return 0;
    int count = 0;
    DateTime d = startDate;
    while (!d.isAfter(endDate)) {
      count++;
      if (cycle == 'yearly') {
        d = DateTime(d.year + 1, d.month, d.day);
      } else if (cycle == 'weekly') {
        d = d.add(const Duration(days: 7));
      } else if (cycle == 'quarterly') {
        d = DateTime(d.year, d.month + 3, d.day);
      } else {
        final nextMonth = d.month + 1;
        final nextYear = d.year + (nextMonth > 12 ? 1 : 0);
        final adjustedMonth = nextMonth > 12 ? 1 : nextMonth;
        d = DateTime(nextYear, adjustedMonth, d.day);
      }
    }
    return count;
  }

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    if (item != null) {
      _nameController = TextEditingController(text: item.name);
      _priceController = TextEditingController(
        text: item.price > 0 ? (item.currency.toUpperCase() == 'BTC' ? item.price.toString() : item.price.toStringAsFixed(item.price.truncateToDouble() == item.price ? 0 : 2)) : '',
      );
      _notesController = TextEditingController(text: item.notes ?? '');
      _totalCyclesController = TextEditingController(text: item.totalCycles?.toString() ?? '6');
      _selectedCategory = item.category;
      _selectedCurrency = item.currency.toUpperCase();
      _billingCycle = item.billingCycle;
      _firstChargeDate = item.firstChargeDate;
      _nextBillingDate = item.nextBillingDate;
      _hasTrial = item.hasTrial;
      _trialEndDate = item.trialEndDate ?? DateTime.now().add(const Duration(days: 7));
      _paymentMethod = item.paymentMethod;
      _selectedAccountId = item.accountId;
      _selectedAccountName = item.accountName ?? item.paymentMethod;
      _enableReminder = item.enableReminder;
      _showInOverview = item.showInOverview;
      _autoRecordExpense = item.autoRecordExpense;
      _logoAssetPath = item.logoAssetPath;
      _customLogoUrl = item.logoUrl;
      _customColor = item.customColor;
      _reminderDaysBefore = item.reminderDaysBefore;
      _isActive = item.isActive;
      _endRuleType = item.endRuleType;
      _endDate = item.endDate;
      _totalCycles = item.totalCycles;
      _completedCycles = item.completedCycles;
    } else {
      _nameController = TextEditingController();
      _priceController = TextEditingController();
      _notesController = TextEditingController();
      _totalCyclesController = TextEditingController(text: '6');
      _totalCycles = 6;
      _enableReminder = true;
      _showInOverview = false;
      _autoRecordExpense = false;
      _endRuleType = 'never';
      _completedCycles = 0;
      if (widget.controller.accounts.isNotEmpty) {
        final defAcc = widget.controller.accounts.first;
        _selectedAccountId = defAcc.id;
        _selectedAccountName = defAcc.name;
        _paymentMethod = defAcc.name;
      }
    }
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    _totalCyclesController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    final text = _nameController.text;
    final suggestions = text.trim().isNotEmpty
        ? SubscriptionPreset.searchPresets(text, limit: 5)
        : <SubscriptionPreset>[];

    final matched = SubscriptionPreset.findMatchingPreset(text);

    setState(() {
      _autocompleteSuggestions = suggestions;
      if (matched != null) {
        _logoAssetPath = matched.logoAssetPath;
        _customLogoUrl = null;
        _selectedCategory = matched.category;
        _customColor = matched.brandColor;
        _selectedCurrency = matched.currency;
        _billingCycle = matched.billingCycle;
        // User rule: Do NOT auto-fill price. Leave price for the user to enter!
      }
    });
  }

  void _selectSuggestion(SubscriptionPreset preset) {
    HapticFeedback.selectionClick();
    setState(() {
      _nameController.text = preset.name;
      _selectedCategory = preset.category;
      _selectedCurrency = preset.currency;
      _billingCycle = preset.billingCycle;
      _logoAssetPath = preset.logoAssetPath;
      _customLogoUrl = null;
      _customColor = preset.brandColor;
      _autocompleteSuggestions = [];
      // User rule: Do NOT auto-fill price. Keep empty!
    });
    FocusScope.of(context).unfocus();
  }

  void _applyPreset(SubscriptionPreset preset) {
    HapticFeedback.selectionClick();
    setState(() {
      _nameController.text = preset.name;
      _selectedCategory = preset.category;
      _selectedCurrency = preset.currency;
      _billingCycle = preset.billingCycle;
      _logoAssetPath = preset.logoAssetPath;
      _customLogoUrl = null;
      _customColor = preset.brandColor;
      _autocompleteSuggestions = [];
      // User rule: Do NOT auto-fill price.
    });
  }

  Future<void> _pickDate({required bool isNextBilling, required bool isTrialEnd}) async {
    HapticFeedback.selectionClick();
    final initialDate = isTrialEnd ? _trialEndDate : _nextBillingDate;
    final isEn = widget.controller.isEnglish;
    final isDark = widget.controller.isDarkMode;

    final picked = await MeowWheelDatePicker.showWheelDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
      isEnglish: isEn,
      isDarkMode: isDark,
      title: isTrialEnd
          ? (isEn ? 'Select Free Trial End' : 'เลือกวันหมดช่วงทดลองใช้ฟรี')
          : (isEn ? 'Select Next Billing Date' : 'เลือกวันตัดเงินรอบถัดไป'),
    );

    if (picked != null) {
      setState(() {
        if (isTrialEnd) {
          _trialEndDate = picked;
        } else {
          _nextBillingDate = picked;
        }
      });
    }
  }

  void _showCustomIconPickerModal() {
    HapticFeedback.lightImpact();
    final theme = widget.controller.currentTheme;

    final List<IconData> iconOptions = [
      Icons.subscriptions_rounded,
      Icons.movie_rounded,
      Icons.music_note_rounded,
      Icons.smart_toy_rounded,
      Icons.bolt_rounded,
      Icons.auto_awesome_rounded,
      Icons.code_rounded,
      Icons.brush_rounded,
      Icons.sports_esports_rounded,
      Icons.cloud_rounded,
      Icons.wifi_rounded,
      Icons.phone_android_rounded,
      Icons.local_shipping_rounded,
      Icons.shopping_bag_rounded,
      Icons.credit_card_rounded,
      Icons.fitness_center_rounded,
      Icons.school_rounded,
      Icons.language_rounded,
    ];

    final List<Color> colorOptions = [
      const Color(0xFF6366F1),
      const Color(0xFFEC4899),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEF4444),
      const Color(0xFF14B8A6),
      const Color(0xFF000000),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'เลือกไอคอน & สีประจำบริการ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.textColor,
                          ),
                        ),
                        if (_logoAssetPath != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _logoAssetPath = null;
                              });
                              Navigator.pop(ctx);
                            },
                            child: const Text('ใช้ไอคอนแทนโลโก้', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('สีประจำบริการ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      children: colorOptions.map((c) {
                        final isSel = _customColor?.value == c.value;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {});
                            setState(() {
                              _customColor = c;
                            });
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(color: isSel ? Colors.white : Colors.transparent, width: 2),
                              boxShadow: isSel ? [BoxShadow(color: c.withOpacity(0.4), blurRadius: 6)] : null,
                            ),
                            child: isSel ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('ไอคอนหมวดหมู่', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 140,
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                        itemCount: iconOptions.length,
                        itemBuilder: (context, index) {
                          final icon = iconOptions[index];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _logoAssetPath = null;
                                _customLogoUrl = null;
                              });
                              Navigator.pop(ctx);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: (_customColor ?? theme.primaryColor).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icon, color: _customColor ?? theme.primaryColor, size: 22),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาระบุค่าบริการมากกว่า 0')),
      );
      return;
    }

    HapticFeedback.lightImpact();

    final item = SubscriptionItem(
      id: widget.existingItem?.id ?? 'sub_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      category: _selectedCategory,
      price: price,
      currency: _selectedCurrency,
      billingCycle: _billingCycle,
      firstChargeDate: _firstChargeDate,
      nextBillingDate: _nextBillingDate,
      hasTrial: _hasTrial,
      trialEndDate: _hasTrial ? _trialEndDate : null,
      paymentMethod: _selectedAccountName ?? _paymentMethod,
      accountId: _selectedAccountId,
      accountName: _selectedAccountName,
      logoAssetPath: _logoAssetPath,
      logoUrl: _customLogoUrl,
      reminderDaysBefore: _reminderDaysBefore,
      enableReminder: _enableReminder,
      showInOverview: _showInOverview,
      autoRecordExpense: _autoRecordExpense,
      lastAutoRecordedDate: widget.existingItem?.lastAutoRecordedDate,
      endRuleType: _endRuleType,
      endDate: _endRuleType == 'untilDate' ? _endDate : null,
      totalCycles: _endRuleType == 'fixedCycles' ? (int.tryParse(_totalCyclesController.text.trim()) ?? _totalCycles ?? 6) : null,
      completedCycles: _completedCycles,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      isActive: _isActive,
      customColor: _customColor,
    );

    if (widget.existingItem != null) {
      widget.controller.updateSubscription(item);
    } else {
      widget.controller.addSubscription(item);
    }

    Navigator.pop(context, true);
  }

  Future<void> _handleReminderToggle(bool val) async {
    HapticFeedback.selectionClick();
    if (val) {
      if (!mounted) return;
      await MeowPermissionDialog.requestWithExplanation(
        context,
        type: MeowPermissionType.notification,
      );
    }
    setState(() => _enableReminder = val);
  }

  void _showCurrencyPickerModal() {
    HapticFeedback.selectionClick();
    final theme = widget.controller.currentTheme;
    final isDark = widget.controller.isDarkMode;
    final textColor = theme.textColor;
    final subColor = theme.textSecondaryColor;
    final cardBg = theme.cardBackground;

    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          final allList = _allCurrencies;
          final filtered = allList.where((c) {
            if (searchQuery.trim().isEmpty) return true;
            final q = searchQuery.toLowerCase();
            return c.code.toLowerCase().contains(q) ||
                c.nameTh.toLowerCase().contains(q) ||
                c.nameEn.toLowerCase().contains(q);
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'เลือกสกุลเงิน (แปลงเป็นเงินบาทอัตโนมัติ)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    onChanged: (val) => setModalState(() => searchQuery = val),
                    style: TextStyle(fontSize: 14, color: textColor),
                    decoration: InputDecoration(
                      hintText: 'ค้นหา เช่น USD, JPY, EUR, ดอลลาร์, เยน...',
                      hintStyle: TextStyle(fontSize: 13, color: subColor),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final c = filtered[index];
                      final codeUpper = c.code.toUpperCase();
                      final isSelected = _selectedCurrency.toUpperCase() == codeUpper;
                      final rate = CurrencyExchangeService.getRateToThb(c.code);

                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedCurrency = codeUpper);
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? theme.primaryColor.withOpacity(0.08) : Colors.transparent,
                            border: Border(bottom: BorderSide(color: theme.borderColor.withOpacity(0.3), width: 0.5)),
                          ),
                          child: Row(
                            children: [
                              Text(c.flag, style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          codeUpper,
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          c.symbol,
                                          style: TextStyle(fontSize: 13, color: subColor, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      c.nameTh,
                                      style: TextStyle(fontSize: 12, color: subColor),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    codeUpper == 'THB' ? 'สกุลเงินหลัก' : '1 $codeUpper ≈ ฿${rate.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? theme.primaryColor : subColor,
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(Icons.check_circle_rounded, color: theme.primaryColor, size: 18),
                                ],
                              ),
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
      ),
    );
  }

  void _showAccountPickerModal() {
    HapticFeedback.selectionClick();
    final theme = widget.controller.currentTheme;
    final textColor = theme.textColor;
    final subColor = theme.textSecondaryColor;
    final cardBg = theme.cardBackground;
    final accounts = widget.controller.accounts;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'เลือกบัญชีที่จะตัดเงิน',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: [
                  if (accounts.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
                      child: Text(
                        'บัญชีธนาคารของฉัน',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: subColor),
                      ),
                    ),
                    ...accounts.map((acc) {
                      final isSelected = _selectedAccountId == acc.id;
                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedAccountId = acc.id;
                            _selectedAccountName = acc.name;
                            _paymentMethod = acc.name;
                          });
                          Navigator.pop(ctx);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? theme.primaryColor.withOpacity(0.08) : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? theme.primaryColor : theme.borderColor.withOpacity(0.35),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              BankBadge(bankCode: acc.bankCode, size: 34),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      acc.name,
                                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textColor),
                                    ),
                                    Text(
                                      acc.bankDisplayName,
                                      style: TextStyle(fontSize: 11, color: subColor),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '฿${FormatUtils.formatCurrency(acc.balance)}',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.primaryColor),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.check_circle_rounded, size: 16, color: theme.primaryColor),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                  ],

                  // Preset Categories from User Images:
                  ...[
                    {
                      'title': 'บัตรเครดิต/เดบิต',
                      'icon': Icons.credit_card_rounded,
                      'items': ['Visa', 'Mastercard', 'JCB', 'American Express', 'UnionPay'],
                    },
                    {
                      'title': 'กระเป๋าเงิน',
                      'icon': Icons.account_balance_wallet_rounded,
                      'items': ['TrueMoney Wallet', 'Apple Pay', 'Google Pay', 'PayPal', 'LINE Pay', 'ShopeePay'],
                    },
                    {
                      'title': 'บิลมือถือ',
                      'icon': Icons.phone_android_rounded,
                      'items': ['บิล AIS', 'บิล True', 'บิล dtac'],
                    },
                    {
                      'title': 'แอปสโตร์',
                      'icon': Icons.storefront_rounded,
                      'items': ['App Store', 'Google Play'],
                    },
                  ].map((group) {
                    final title = group['title'] as String;
                    final icon = group['icon'] as IconData;
                    final items = group['items'] as List<String>;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 6, top: 8),
                          child: Row(
                            children: [
                              Icon(icon, size: 14, color: subColor),
                              const SizedBox(width: 6),
                              Text(
                                title,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: subColor),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: theme.cardBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: theme.borderColor.withOpacity(0.35)),
                          ),
                          child: Column(
                            children: items.map((methodName) {
                              final isSelected = _selectedAccountId == null && _paymentMethod == methodName;
                              return InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _selectedAccountId = null;
                                    _selectedAccountName = methodName;
                                    _paymentMethod = methodName;
                                  });
                                  Navigator.pop(ctx);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                  decoration: BoxDecoration(
                                    color: isSelected ? theme.primaryColor.withOpacity(0.08) : Colors.transparent,
                                    border: Border(
                                      bottom: items.last == methodName
                                          ? BorderSide.none
                                          : BorderSide(color: theme.borderColor.withOpacity(0.2), width: 0.5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        methodName,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? theme.primaryColor : textColor,
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(Icons.check_circle_rounded, size: 16, color: theme.primaryColor),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoAvatar() {
    final theme = widget.controller.currentTheme;
    final accentColor = _customColor ?? theme.primaryColor;

    return GestureDetector(
      onTap: _showCustomIconPickerModal,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: accentColor.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(7),
            child: _logoAssetPath != null && _logoAssetPath!.isNotEmpty
                ? Image.asset(
                    _logoAssetPath!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(Icons.subscriptions_rounded, size: 28, color: accentColor),
                  )
                : Center(
                    child: Icon(
                      Icons.subscriptions_rounded,
                      size: 28,
                      color: accentColor,
                    ),
                  ),
          ),
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              padding: const EdgeInsets.all(3.5),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 3),
                ],
              ),
              child: const Icon(Icons.edit_rounded, size: 9, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.controller.currentTheme;
    final isEn = widget.controller.isEnglish;
    final isDark = widget.controller.isDarkMode;
    final cardBg = theme.cardBackground;
    final textColor = theme.textColor;
    final subColor = theme.textSecondaryColor;
    final borderColor = theme.borderColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existingItem != null
              ? (isEn ? 'Edit Subscription' : 'แก้ไข Subscription')
              : (isEn ? 'Add Subscription' : 'เพิ่ม Subscription ใหม่'),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (widget.existingItem != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    backgroundColor: cardBg,
                    title: Text(isEn ? 'Delete Subscription?' : 'ลบ Subscription นี้?', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    content: Text(
                      isEn ? 'Are you sure you want to remove this subscription?' : 'คุณแน่ใจหรือไม่ว่าต้องการลบรายการนี้ออกจากระบบ?',
                      style: TextStyle(color: subColor),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isEn ? 'Cancel' : 'ยกเลิก')),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                        onPressed: () {
                          widget.controller.deleteSubscription(widget.existingItem!.id);
                          Navigator.pop(ctx);
                          Navigator.pop(context, true);
                        },
                        child: Text(isEn ? 'Delete' : 'ลบรายการ'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Quick preset bar if adding new
            if (widget.existingItem == null) ...[
              Text(
                isEn ? 'Popular Services' : 'บริการยอดนิยม',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: subColor,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 84,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: SubscriptionPreset.popularPresets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final preset = SubscriptionPreset.popularPresets[index];
                    final isSelected = _nameController.text.toLowerCase() == preset.name.toLowerCase();
                    return InkWell(
                      onTap: () => _applyPreset(preset),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 72,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? theme.primaryColor : borderColor.withOpacity(0.5),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: theme.primaryColor.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              preset.logoAssetPath,
                              width: 34,
                              height: 34,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(Icons.subscriptions, size: 28),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              preset.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Hero Input Card: Logo Avatar + Name Input + Autocomplete Dropdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor.withOpacity(0.6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildLogoAvatar(),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              focusNode: _nameFocusNode,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                              decoration: InputDecoration(
                                hintText: isEn ? 'Service name (e.g. Netflix, Gemini)' : 'ชื่อบริการ (เช่น Netflix, Gemini, Kling)',
                                hintStyle: TextStyle(fontSize: 13, color: subColor.withOpacity(0.5)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'กรุณาระบุชื่อบริการ' : null,
                            ),
                            const SizedBox(height: 4),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCategory,
                                isDense: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                                items: _categories.map((c) {
                                  return DropdownMenuItem(
                                    value: c,
                                    child: Text(c, style: TextStyle(fontSize: 12.5, color: subColor)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedCategory = val);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Google-like Search Autocomplete Dropdown
                  if (_autocompleteSuggestions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor.withOpacity(0.5)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: _autocompleteSuggestions.map((suggestion) {
                          return InkWell(
                            onTap: () => _selectSuggestion(suggestion),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              child: Row(
                                children: [
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.black.withOpacity(0.06)),
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: Image.asset(
                                      suggestion.logoAssetPath,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.subscriptions, size: 14),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      suggestion.name,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      suggestion.category,
                                      style: TextStyle(fontSize: 10, color: subColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Minimalist Billing & Price Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor.withOpacity(0.6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEn ? 'Billing & Price' : 'ค่าบริการ & รอบบิล',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      // Currency Picker Pill
                      GestureDetector(
                        onTap: _showCurrencyPickerModal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                CurrencyExchangeService.supportedCurrencies[_selectedCurrency.toLowerCase()]?.flag ?? '🌐',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _selectedCurrency,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_drop_down_rounded, size: 18, color: theme.primaryColor),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Price Input
                  TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: subColor.withOpacity(0.3)),
                      prefixText: _selectedCurrency == 'THB'
                          ? '฿ '
                          : '${CurrencyExchangeService.supportedCurrencies[_selectedCurrency.toLowerCase()]?.symbol ?? _selectedCurrency} ',
                      prefixStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.primaryColor),
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: borderColor.withOpacity(0.4)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: borderColor.withOpacity(0.4)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: theme.primaryColor, width: 1.8),
                      ),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'กรุณาระบุจำนวนเงิน' : null,
                    onChanged: (_) => setState(() {}),
                  ),

                  // Live Foreign Currency to THB conversion pill
                  Builder(builder: (context) {
                    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
                    if (_selectedCurrency.toUpperCase() == 'THB' || price <= 0) {
                      return const SizedBox.shrink();
                    }
                    final rateToThb = CurrencyExchangeService.getRateToThb(_selectedCurrency);
                    final convertedThb = price * rateToThb;
                    final currInfo = CurrencyExchangeService.supportedCurrencies[_selectedCurrency.toLowerCase()];

                    return Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(currInfo?.flag ?? '🌐', style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text(
                                'แปลงเป็นเงินไทย (1 $_selectedCurrency ≈ ฿${rateToThb.toStringAsFixed(2)})',
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF4F46E5), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          Text(
                            '≈ ฿${FormatUtils.formatCurrency(convertedThb)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4338CA)),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 12),

                  // Segmented Billing Cycle Pills
                  Row(
                    children: [
                      {'id': 'monthly', 'label': 'รายเดือน'},
                      {'id': 'yearly', 'label': 'รายปี'},
                      {'id': 'weekly', 'label': 'รายสัปดาห์'},
                    ].map((c) {
                      final isSelected = _billingCycle == c['id'];
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _billingCycle = c['id']!);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: isSelected ? theme.primaryColor : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? theme.primaryColor : borderColor.withOpacity(0.4),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              c['label']!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : subColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Live Monthly Calculation Pill
                  Builder(builder: (context) {
                    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
                    if (price <= 0) return const SizedBox.shrink();

                    final monthlyAmount = _billingCycle == 'yearly'
                        ? price / 12.0
                        : (_billingCycle == 'weekly' ? price * 4.33 : price);
                    final thbMonthly = _selectedCurrency == 'THB'
                        ? monthlyAmount
                        : CurrencyExchangeService.convertToThb(monthlyAmount, _selectedCurrency);

                    return Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _billingCycle == 'yearly' ? 'เฉลี่ยต่อเดือน' : (_billingCycle == 'weekly' ? 'ประมาณต่อเดือน (~4.3 สัปดาห์)' : 'ยอดต่อเดือน'),
                            style: TextStyle(fontSize: 11.5, color: subColor),
                          ),
                          Text(
                            '≈ ฿${FormatUtils.formatCurrency(thbMonthly)}/ด.',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.primaryColor),
                          ),
                        ],
                      ),
                    );
                  }),

                  const Divider(height: 22),

                  // Next Billing Date Row
                  InkWell(
                    onTap: () => _pickDate(isNextBilling: true, isTrialEnd: false),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 17, color: theme.primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                isEn ? 'Next Billing Date' : 'วันตัดเงินรอบถัดไป',
                                style: TextStyle(fontSize: 13.5, color: textColor),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                FormatUtils.formatDate(_nextBillingDate, isEnglish: isEn),
                                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: theme.primaryColor),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.chevron_right_rounded, size: 18, color: subColor),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 22),

                  // Duration / End Rule Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEn ? 'Subscription Duration' : 'กำหนดระยะเวลาของบริการ',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textColor),
                          ),
                          Text(
                            isEn ? 'Select rule for recurring service' : 'เลือกเงื่อนไขการสิ้นสุดของบริการนี้',
                            style: TextStyle(fontSize: 11, color: subColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 3 Duration Rule Chips
                  Row(
                    children: [
                      {'id': 'never', 'label': isEn ? 'Ongoing' : 'ไม่มีวันสิ้นสุด'},
                      {'id': 'untilDate', 'label': isEn ? 'Until Date' : 'ถึงวันที่'},
                      {'id': 'fixedCycles', 'label': isEn ? 'Fixed Cycles' : 'กำหนดจำนวนครั้ง'},
                    ].map((opt) {
                      final isSelected = _endRuleType == opt['id'];
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _endRuleType = opt['id']!;
                              if (_endRuleType == 'untilDate' && _endDate == null) {
                                _endDate = _calculateEndDateFromCycles(_nextBillingDate, 6, _billingCycle);
                              }
                              if (_endRuleType == 'fixedCycles' && _totalCycles == null) {
                                _totalCycles = int.tryParse(_totalCyclesController.text.trim()) ?? 6;
                              }
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? theme.primaryColor : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? theme.primaryColor : borderColor.withOpacity(0.35),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              opt['label']!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : subColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Detail for untilDate
                  if (_endRuleType == 'untilDate') ...[
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        final picked = await MeowWheelDatePicker.showWheelDatePicker(
                          context: context,
                          initialDate: _endDate ?? _calculateEndDateFromCycles(_nextBillingDate, 6, _billingCycle),
                          firstDate: _nextBillingDate,
                          lastDate: DateTime(2040),
                          isEnglish: isEn,
                          isDarkMode: isDark,
                          title: isEn ? 'Select End Date' : 'เลือกวันสิ้นสุดบริการ',
                        );
                        if (picked != null) {
                          setState(() => _endDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor.withOpacity(0.35)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isEn ? 'End Date' : 'สิ้นสุดในวันที่',
                              style: TextStyle(fontSize: 12.5, color: subColor),
                            ),
                            Row(
                              children: [
                                Text(
                                  FormatUtils.formatDate(_endDate ?? _nextBillingDate, isEnglish: isEn),
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.primaryColor),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.edit_calendar_rounded, size: 15),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Builder(builder: (_) {
                      final cycles = _calculateCyclesBetween(_nextBillingDate, _endDate ?? _nextBillingDate, _billingCycle);
                      return Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Text(
                          'ชำระทั้งหมดประมาณ $cycles รอบ จนถึงวันสิ้นสุด',
                          style: TextStyle(fontSize: 11, color: subColor),
                        ),
                      );
                    }),
                  ],

                  // Detail for fixedCycles
                  if (_endRuleType == 'fixedCycles') ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _totalCyclesController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                            decoration: InputDecoration(
                              labelText: isEn ? 'Total number of payments' : 'จำนวนครั้งที่ต้องการจ่าย',
                              labelStyle: TextStyle(fontSize: 12, color: subColor),
                              suffixText: isEn ? 'times' : 'ครั้ง',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              isDense: true,
                            ),
                            onChanged: (val) {
                              final num = int.tryParse(val.trim());
                              if (num != null) setState(() => _totalCycles = num);
                            },
                          ),
                        ),
                      ],
                    ),
                    Builder(builder: (_) {
                      final count = int.tryParse(_totalCyclesController.text.trim()) ?? _totalCycles ?? 6;
                      final calcEnd = _calculateEndDateFromCycles(_nextBillingDate, count, _billingCycle);
                      return Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Text(
                          isEn
                              ? 'Total $count cycles, ends approx ${FormatUtils.formatDate(calcEnd, isEnglish: isEn)}'
                              : 'ครบ $count ครั้ง สิ้นสุดประมาณ ${FormatUtils.formatDate(calcEnd, isEnglish: isEn)}',
                          style: TextStyle(fontSize: 11, color: subColor),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Free Trial Settings
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _hasTrial ? const Color(0xFFF59E0B).withOpacity(0.8) : borderColor.withOpacity(0.6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.alarm_on_rounded, color: Color(0xFFF59E0B), size: 20),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEn ? 'Free Trial Period' : 'อยู่ในช่วงทดลองใช้ (Free Trial)',
                                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textColor),
                              ),
                              Text(
                                isEn ? 'Alert before auto-renewal charge' : 'เตือนล่วงหน้าก่อนถูกตัดเงินจริง',
                                style: TextStyle(fontSize: 11, color: subColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: _hasTrial,
                        activeColor: const Color(0xFFF59E0B),
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          setState(() => _hasTrial = val);
                        },
                      ),
                    ],
                  ),
                  if (_hasTrial) ...[
                    const Divider(height: 18),
                    InkWell(
                      onTap: () => _pickDate(isNextBilling: false, isTrialEnd: true),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEn ? 'Trial Ends On' : 'หมดช่วงทดลองใช้วันที่',
                            style: TextStyle(fontSize: 13, color: textColor),
                          ),
                          Row(
                            children: [
                              Text(
                                FormatUtils.formatDate(_trialEndDate, isEnglish: isEn),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.edit_calendar_rounded, size: 16, color: Color(0xFFF59E0B)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Payment Source, Auto-Record & Reminders Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor.withOpacity(0.6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Account Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_rounded, size: 18, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Text(
                            isEn ? 'Payment Account' : 'ช่องทางที่ใช้ชำระเงิน',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textColor),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _showAccountPickerModal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.primaryColor.withOpacity(0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedAccountName ?? _paymentMethod,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: theme.primaryColor),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // 2. Auto-Record Expense Switch (Clean wording, no 'ออโต้')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.receipt_long_rounded, size: 18, color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEn ? 'Record When Due' : 'บันทึกลงรายจ่ายเมื่อถึงรอบบิล',
                                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textColor),
                                  ),
                                  Text(
                                    isEn
                                        ? 'Log expense entry on scheduled billing date'
                                        : 'ลงบันทึกในสมุดรายรับ-รายจ่ายเมื่อถึงวันตัดเงิน',
                                    style: TextStyle(fontSize: 11, color: subColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _autoRecordExpense,
                        activeColor: theme.primaryColor,
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          setState(() => _autoRecordExpense = val);
                        },
                      ),
                    ],
                  ),
                  if (_autoRecordExpense) ...[
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor.withOpacity(0.35)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 15, color: subColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isEn
                                  ? 'When due, an expense will be recorded with note:\n"Paid via: ${_selectedAccountName ?? _paymentMethod}"'
                                  : 'เมื่อถึงวันตัดเงิน ระบบจะลงบันทึกเป็นรายจ่ายพร้อมโน้ต:\n"ชำระผ่าน: ${_selectedAccountName ?? _paymentMethod}"',
                              style: TextStyle(fontSize: 11.5, color: subColor, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Divider(height: 20),

                  // 3. Reminder Toggle & Days Before
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.notifications_active_rounded, size: 18, color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEn ? 'Due Date Reminders' : 'เปิดการแจ้งเตือนความจำ',
                                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textColor),
                                  ),
                                  Text(
                                    isEn ? 'Alert on phone before charge' : 'เตือนล่วงหน้าทางมือถือ',
                                    style: TextStyle(fontSize: 11, color: subColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _enableReminder,
                        activeColor: theme.primaryColor,
                        onChanged: _handleReminderToggle,
                      ),
                    ],
                  ),
                  if (_enableReminder) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEn ? 'Remind Before' : 'เตือนล่วงหน้าก่อนตัดเงิน',
                          style: TextStyle(fontSize: 12.5, color: subColor),
                        ),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _reminderDaysBefore,
                            isDense: true,
                            items: const [
                              DropdownMenuItem(value: 0, child: Text('ในวันตัดบิล', style: TextStyle(fontSize: 12.5))),
                              DropdownMenuItem(value: 1, child: Text('1 วันก่อน', style: TextStyle(fontSize: 12.5))),
                              DropdownMenuItem(value: 3, child: Text('3 วันก่อน (แนะนำ)', style: TextStyle(fontSize: 12.5))),
                              DropdownMenuItem(value: 5, child: Text('5 วันก่อน', style: TextStyle(fontSize: 12.5))),
                              DropdownMenuItem(value: 7, child: Text('7 วันก่อน', style: TextStyle(fontSize: 12.5))),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _reminderDaysBefore = val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: 20),

                  // 4. Overview Screen Banner Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.dashboard_customize_rounded, size: 18, color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEn ? 'Show on Overview' : 'แสดงเตือนในหน้าภาพรวม',
                                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textColor),
                                  ),
                                  Text(
                                    isEn
                                        ? 'Show compact banner on main overview when bill is due'
                                        : 'แสดงแถบเตือนบนหน้าภาพรวมเมื่อใกล้ถึงกำหนดชำระ',
                                    style: TextStyle(fontSize: 11, color: subColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _showInOverview,
                        activeColor: theme.primaryColor,
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          setState(() => _showInOverview = val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Notes
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor.withOpacity(0.6)),
              ),
              child: TextField(
                controller: _notesController,
                maxLines: 2,
                style: TextStyle(fontSize: 13, color: textColor),
                decoration: InputDecoration(
                  hintText: isEn ? 'Notes (optional)' : 'บันทึกช่วยจำ (เช่น แชร์กับครอบครัว 4 คน)',
                  hintStyle: TextStyle(fontSize: 12, color: subColor.withOpacity(0.5)),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Save Button
            TactileButton(
              onTap: _save,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      widget.existingItem != null
                          ? (isEn ? 'Update Subscription' : 'บันทึกการแก้ไข')
                          : (isEn ? 'Save Subscription' : 'บันทึก Subscription'),
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
