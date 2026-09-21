import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/subscription_item.dart';
import '../state/expense_controller.dart';
import '../services/currency_exchange_service.dart';
import '../utils/format_utils.dart';
import '../widgets/tactile_button.dart';

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
  late TextEditingController _websiteController;

  String _selectedCategory = 'สตรีมมิ่ง & ดูหนัง';
  String _selectedCurrency = 'THB';
  String _billingCycle = 'monthly';
  DateTime _firstChargeDate = DateTime.now();
  DateTime _nextBillingDate = DateTime.now().add(const Duration(days: 30));
  bool _hasTrial = false;
  DateTime _trialEndDate = DateTime.now().add(const Duration(days: 7));
  String _paymentMethod = 'บัตรเครดิต/เดบิต';
  String? _logoAssetPath;
  String? _customLogoUrl;
  Color? _customColor;
  int _reminderDaysBefore = 3;
  bool _isActive = true;

  final List<String> _categories = [
    'สตรีมมิ่ง & ดูหนัง',
    'เพลง & พอดแคสต์',
    'สตรีมมิ่ง & ซีรีส์',
    'AI & ซอฟต์แวร์',
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

  final List<String> _currencies = ['THB', 'USD', 'JPY', 'EUR', 'GBP', 'SGD'];

  final List<Map<String, String>> _billingCycles = [
    {'id': 'monthly', 'label': 'รายเดือน (Monthly)'},
    {'id': 'yearly', 'label': 'รายปี (Yearly)'},
    {'id': 'weekly', 'label': 'รายสัปดาห์ (Weekly)'},
    {'id': 'quarterly', 'label': 'ราย 3 เดือน (Quarterly)'},
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    if (item != null) {
      _nameController = TextEditingController(text: item.name);
      _priceController = TextEditingController(text: item.price.toStringAsFixed(item.price.truncateToDouble() == item.price ? 0 : 2));
      _notesController = TextEditingController(text: item.notes ?? '');
      _websiteController = TextEditingController();
      _selectedCategory = item.category;
      _selectedCurrency = item.currency;
      _billingCycle = item.billingCycle;
      _firstChargeDate = item.firstChargeDate;
      _nextBillingDate = item.nextBillingDate;
      _hasTrial = item.hasTrial;
      _trialEndDate = item.trialEndDate ?? DateTime.now().add(const Duration(days: 7));
      _paymentMethod = item.paymentMethod;
      _logoAssetPath = item.logoAssetPath;
      _customLogoUrl = item.logoUrl;
      _customColor = item.customColor;
      _reminderDaysBefore = item.reminderDaysBefore;
      _isActive = item.isActive;
    } else {
      _nameController = TextEditingController();
      _priceController = TextEditingController();
      _notesController = TextEditingController();
      _websiteController = TextEditingController();
      // Default to first account or credit card
      if (widget.controller.accounts.isNotEmpty) {
        _paymentMethod = widget.controller.accounts.first.name;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _applyPreset(SubscriptionPreset preset) {
    HapticFeedback.selectionClick();
    setState(() {
      _nameController.text = preset.name;
      _selectedCategory = preset.category;
      _priceController.text = preset.defaultPrice.toStringAsFixed(preset.defaultPrice.truncateToDouble() == preset.defaultPrice ? 0 : 2);
      _selectedCurrency = preset.currency;
      _billingCycle = preset.billingCycle;
      _logoAssetPath = preset.logoAssetPath;
      _customLogoUrl = null;
      _customColor = preset.brandColor;
    });
  }

  void _fetchWebsiteLogo() {
    final raw = _websiteController.text.trim();
    if (raw.isEmpty) return;
    HapticFeedback.selectionClick();

    String domain = raw;
    domain = domain.replaceAll(RegExp(r'^https?:\/\/'), '');
    domain = domain.replaceAll(RegExp(r'\/.*$'), '');

    setState(() {
      _customLogoUrl = 'https://www.google.com/s2/favicons?domain=$domain&sz=128';
      _logoAssetPath = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ดึงโลโก้จาก $domain เรียบร้อย! 🌐'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickDate({required bool isNextBilling, required bool isTrialEnd}) async {
    final initialDate = isTrialEnd
        ? _trialEndDate
        : (isNextBilling ? _nextBillingDate : _firstChargeDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        final theme = widget.controller.currentTheme;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: theme.primaryColor,
              onPrimary: Colors.white,
              surface: theme.cardBackground,
              onSurface: theme.textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isTrialEnd) {
          _trialEndDate = picked;
        } else if (isNextBilling) {
          _nextBillingDate = picked;
        } else {
          _firstChargeDate = picked;
        }
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาระบุจำนวนเงินที่ถูกต้อง')),
      );
      return;
    }

    HapticFeedback.mediumImpact();

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
      paymentMethod: _paymentMethod,
      logoAssetPath: _logoAssetPath,
      logoUrl: _customLogoUrl,
      reminderDaysBefore: _reminderDaysBefore,
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

  Widget _buildLogoAvatar() {
    if (_logoAssetPath != null && _logoAssetPath!.isNotEmpty) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Image.asset(
          _logoAssetPath!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.apps_rounded, size: 36, color: Color(0xFF64748B)),
        ),
      );
    } else if (_customLogoUrl != null && _customLogoUrl!.isNotEmpty) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Image.network(
          _customLogoUrl!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.language_rounded, size: 36, color: Color(0xFF64748B)),
        ),
      );
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: (_customColor ?? widget.controller.currentTheme.primaryColor).withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(
          Icons.subscriptions_rounded,
          size: 32,
          color: _customColor ?? widget.controller.currentTheme.primaryColor,
        ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEn ? 'Popular Services (Real Logos)' : 'เลือกบริการยอดนิยม (โลโก้ของแท้ 100%)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: subColor,
                    ),
                  ),
                  const Text('แตะเพื่อกรอกอัตโนมัติ ✨', style: TextStyle(fontSize: 11, color: Color(0xFF10B981))),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: SubscriptionPreset.popularPresets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final preset = SubscriptionPreset.popularPresets[index];
                    final isSelected = _nameController.text.toLowerCase() == preset.name.toLowerCase();
                    return InkWell(
                      onTap: () => _applyPreset(preset),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 76,
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
                              width: 38,
                              height: 38,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(Icons.subscriptions, size: 30),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              preset.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
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
              const SizedBox(height: 20),
            ],

            // Hero Input Card: Logo preview + Service Name & Price
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor.withOpacity(0.6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildLogoAvatar(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                              decoration: InputDecoration(
                                hintText: isEn ? 'Service Name (e.g. Netflix)' : 'ชื่อบริการ (เช่น Netflix, ChatGPT)',
                                hintStyle: TextStyle(fontSize: 14, color: subColor.withOpacity(0.6)),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'กรุณาระบุชื่อบริการ' : null,
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCategory,
                                isDense: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                                items: _categories.map((c) {
                                  return DropdownMenuItem(
                                    value: c,
                                    child: Text(c, style: TextStyle(fontSize: 13, color: subColor)),
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
                  const Divider(height: 28),
                  // Price and Currency
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                          decoration: InputDecoration(
                            labelText: isEn ? 'Price per cycle' : 'ค่าบริการตามรอบบิล',
                            labelStyle: TextStyle(fontSize: 12, color: subColor),
                            prefixText: _selectedCurrency == 'THB' ? '฿ ' : (_selectedCurrency == 'USD' ? '\$ ' : ''),
                            prefixStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.primaryColor),
                            border: InputBorder.none,
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'กรุณาระบุราคา' : null,
                        ),
                      ),
                      // Currency Picker
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCurrency,
                            icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
                            items: _currencies.map((curr) {
                              return DropdownMenuItem(
                                value: curr,
                                child: Text(curr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCurrency = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Currency THB live conversion hint if non-THB
                  if (_selectedCurrency != 'THB') ...[
                    const SizedBox(height: 4),
                    Builder(builder: (context) {
                      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
                      final thb = CurrencyExchangeService.convertToThb(price, _selectedCurrency);
                      return Row(
                        children: [
                          const Icon(Icons.currency_exchange_rounded, size: 14, color: Color(0xFF0284C7)),
                          const SizedBox(width: 4),
                          Text(
                            'ประมาณ ฿${FormatUtils.formatCurrency(thb)} (อัตราแลกเปลี่ยนปัจจุบัน)',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                          ),
                        ],
                      );
                    }),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Billing Cycle Selector
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
                  Text(
                    isEn ? 'Billing Cycle' : 'รอบการเรียกเก็บเงิน',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _billingCycles.map((cycle) {
                      final isSelected = _billingCycle == cycle['id'];
                      return ChoiceChip(
                        label: Text(cycle['label']!),
                        selected: isSelected,
                        selectedColor: theme.primaryColor.withOpacity(0.18),
                        backgroundColor: cardBg,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? theme.primaryColor : subColor,
                        ),
                        side: BorderSide(
                          color: isSelected ? theme.primaryColor : borderColor.withOpacity(0.5),
                        ),
                        onSelected: (selected) {
                          if (selected) setState(() => _billingCycle = cycle['id']!);
                        },
                      );
                    }).toList(),
                  ),
                  const Divider(height: 24),
                  // Next Billing Date
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
                              const Icon(Icons.event_rounded, size: 20, color: Color(0xFF3B82F6)),
                              const SizedBox(width: 10),
                              Text(
                                isEn ? 'Next Billing Date' : 'วันตัดเงินรอบถัดไป',
                                style: TextStyle(fontSize: 14, color: textColor),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                DateFormat('d MMM yyyy').format(_nextBillingDate),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

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
                          const Icon(Icons.card_giftcard_rounded, color: Color(0xFFF59E0B), size: 22),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEn ? 'Free Trial Active' : 'อยู่ในช่วงทดลองใช้ฟรี (Free Trial)',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                              ),
                              Text(
                                isEn ? 'Alert before auto-renewal charge' : 'แจ้งเตือนยกเลิกก่อนถูกตัดเงินจริง',
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
                    const Divider(height: 20),
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
                                DateFormat('d MMM yyyy').format(_trialEndDate),
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
            const SizedBox(height: 16),

            // Payment Account & Reminders
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
                  // Payment Method
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.credit_card_rounded, size: 20, color: Color(0xFF10B981)),
                          const SizedBox(width: 10),
                          Text(
                            isEn ? 'Payment Source' : 'ตัดเงินจากบัญชี/บัตร',
                            style: TextStyle(fontSize: 14, color: textColor),
                          ),
                        ],
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _paymentMethod,
                          items: [
                            const DropdownMenuItem(value: 'บัตรเครดิต/เดบิต', child: Text('บัตรเครดิต/เดบิต')),
                            const DropdownMenuItem(value: 'พร้อมเพย์ / สแกน QR', child: Text('พร้อมเพย์ / สแกน QR')),
                            ...widget.controller.accounts.map((a) {
                              return DropdownMenuItem(value: a.name, child: Text(a.name));
                            }),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _paymentMethod = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  // Reminder Days
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_active_rounded, size: 20, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 10),
                          Text(
                            isEn ? 'Remind Me Before' : 'เตือนล่วงหน้า',
                            style: TextStyle(fontSize: 14, color: textColor),
                          ),
                        ],
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _reminderDaysBefore,
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('1 วันก่อน')),
                            DropdownMenuItem(value: 3, child: Text('3 วันก่อน (แนะนำ)')),
                            DropdownMenuItem(value: 5, child: Text('5 วันก่อน')),
                            DropdownMenuItem(value: 7, child: Text('7 วันก่อน (1 สัปดาห์)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _reminderDaysBefore = val);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Custom Website Favicon Fetcher (if custom service)
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
                    children: [
                      const Icon(Icons.auto_fix_high_rounded, size: 18, color: Color(0xFF8B5CF6)),
                      const SizedBox(width: 8),
                      Text(
                        isEn ? 'Custom Service Logo Fetcher' : 'ดึงโลโก้จริงจากเว็บ (ถ้าบริการอื่น)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEn
                        ? 'Enter website URL (e.g. figma.com) to automatically download and display their real brand logo.'
                        : 'พิมพ์ชื่อเว็บ เช่น figma.com, zoom.us เพื่อดึงโลโก้ของแท้จากผู้ให้บริการมาแสดงผลทันที',
                    style: TextStyle(fontSize: 11, color: subColor),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _websiteController,
                          decoration: InputDecoration(
                            hintText: 'เช่น figma.com หรือ adobe.com',
                            hintStyle: TextStyle(fontSize: 12, color: subColor.withOpacity(0.6)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            filled: true,
                            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _fetchWebsiteLogo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        child: const Text('ดึงโลโก้', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            Container(
              padding: const EdgeInsets.all(16),
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
                  hintText: isEn ? 'Notes (e.g. Shared with 4 family members)' : 'บันทึกช่วยจำ (เช่น แชร์กับเพื่อน 4 คน, อีเมลที่สมัคร)',
                  hintStyle: TextStyle(fontSize: 12, color: subColor.withOpacity(0.6)),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            TactileButton(
              onTap: _save,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
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
                        fontSize: 16,
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
