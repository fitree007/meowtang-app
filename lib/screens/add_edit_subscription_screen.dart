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
  final FocusNode _nameFocusNode = FocusNode();

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

  final List<String> _currencies = ['THB', 'USD', 'JPY', 'EUR', 'GBP', 'SGD'];

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    if (item != null) {
      _nameController = TextEditingController(text: item.name);
      _priceController = TextEditingController(
        text: item.price > 0 ? item.price.toStringAsFixed(item.price.truncateToDouble() == item.price ? 0 : 2) : '',
      );
      _notesController = TextEditingController(text: item.notes ?? '');
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
      if (widget.controller.accounts.isNotEmpty) {
        _paymentMethod = widget.controller.accounts.first.name;
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
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.controller.currentTheme.primaryColor,
              onPrimary: Colors.white,
              surface: widget.controller.currentTheme.cardBackground,
              onSurface: widget.controller.currentTheme.textColor,
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCurrency,
                            isDense: true,
                            icon: const Icon(Icons.arrow_drop_down_rounded, size: 18),
                            items: _currencies.map((curr) => DropdownMenuItem(
                              value: curr,
                              child: Text(curr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            )).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCurrency = val);
                            },
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
                      prefixText: _selectedCurrency == 'THB' ? '฿ ' : (_selectedCurrency == 'USD' ? '\$ ' : ''),
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
                                DateFormat('d MMM yyyy').format(_nextBillingDate),
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
            const SizedBox(height: 14),

            // Payment Source & Reminders
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
                      Row(
                        children: [
                          const Icon(Icons.credit_card_rounded, size: 18, color: Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          Text(
                            isEn ? 'Payment Source' : 'ตัดเงินจากบัญชี/บัตร',
                            style: TextStyle(fontSize: 13.5, color: textColor),
                          ),
                        ],
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _paymentMethod,
                          isDense: true,
                          items: [
                            const DropdownMenuItem(value: 'บัตรเครดิต/เดบิต', child: Text('บัตรเครดิต/เดบิต', style: TextStyle(fontSize: 13))),
                            const DropdownMenuItem(value: 'พร้อมเพย์ / สแกน QR', child: Text('พร้อมเพย์ / สแกน QR', style: TextStyle(fontSize: 13))),
                            ...widget.controller.accounts.map((a) {
                              return DropdownMenuItem(value: a.name, child: Text(a.name, style: const TextStyle(fontSize: 13)));
                            }),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _paymentMethod = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_active_rounded, size: 18, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 8),
                          Text(
                            isEn ? 'Remind Me' : 'เตือนล่วงหน้า',
                            style: TextStyle(fontSize: 13.5, color: textColor),
                          ),
                        ],
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _reminderDaysBefore,
                          isDense: true,
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('1 วันก่อน', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 3, child: Text('3 วันก่อน (แนะนำ)', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 5, child: Text('5 วันก่อน', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 7, child: Text('7 วันก่อน', style: TextStyle(fontSize: 13))),
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
