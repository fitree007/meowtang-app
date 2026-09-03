import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../models/category_item.dart';
import '../theme/meow_theme.dart';

class CategoryManagementScreen extends StatefulWidget {
  final ExpenseController controller;

  const CategoryManagementScreen({super.key, required this.controller});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<int> _colorPalette = [
    0xFFF59E0B, // Amber Mustard
    0xFF10B981, // Emerald Green
    0xFF3B82F6, // Bright Blue
    0xFFEF4444, // Vibrant Red
    0xFF8B5CF6, // Purple Lavender
    0xFFEC4899, // Pink Rose
    0xFF06B6D4, // Cyan Sky
    0xFF14B8A6, // Teal Mint
    0xFFEA580C, // Orange Coral
    0xFF6366F1, // Indigo
    0xFF84CC16, // Lime Leaf
    0xFFE11D48, // Crimson
    0xFF0D9488, // Dark Teal
    0xFF0284C7, // Ocean Blue
    0xFF7C3AED, // Deep Violet
    0xFFDB2777, // Magenta
    0xFFD97706, // Honey Gold
    0xFF65A30D, // Olive Green
    0xFF475569, // Slate Dark
    0xFF059669, // Forest Green
    0xFF2563EB, // Royal Blue
    0xFF9333EA, // Neon Purple
    0xFFC026D3, // Fuchsia
    0xFFCA8A04, // Deep Mustard
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddOrEditCategoryDialog({CategoryItem? existingCat, required CategoryType defaultType}) {
    final isEditing = existingCat != null;
    final isDark = widget.controller.isDarkMode;
    final isEn = widget.controller.isEnglish;

    final nameCtrl = TextEditingController(text: existingCat?.name ?? '');
    String selectedIconKey = existingCat?.iconKey ?? (defaultType == CategoryType.income ? 'payments' : 'restaurant');
    int selectedColor = existingCat?.colorValue ?? (defaultType == CategoryType.income ? 0xFF10B981 : 0xFFF59E0B);
    final categoryType = existingCat?.type ?? defaultType;
    int selectedGroupIndex = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? MeowTheme.navySurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
            final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
            final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Header Drag Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Title Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(selectedColor).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  CategoryCatalog.availableIcons
                                      .firstWhere(
                                        (i) => i.key == selectedIconKey,
                                        orElse: () => CategoryCatalog.availableIcons.first,
                                      )
                                      .icon,
                                  color: Color(selectedColor),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                isEditing
                                    ? (isEn ? 'Edit Category' : 'แก้ไขหมวดหมู่')
                                    : (isEn ? 'Add New Category' : 'เพิ่มหมวดหมู่ใหม่'),
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: Icon(Icons.close, color: subTextColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Name Field
                      Text(
                        isEn ? 'Category Name' : 'ชื่อหมวดหมู่',
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameCtrl,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: isEn ? 'e.g. Coffee, Taxi, Rent' : 'เช่น อาหาร, ค่าน้ำมัน, ช้อปปิ้ง',
                          hintStyle: TextStyle(color: subTextColor.withOpacity(0.6)),
                          filled: true,
                          fillColor: inputBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Color Palette Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEn ? 'Color' : 'เลือกสีหมวดหมู่',
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              _showCustomColorPicker(
                                initialColor: Color(selectedColor),
                                onColorSelected: (newColor) {
                                  setModalState(() {
                                    selectedColor = newColor.value;
                                  });
                                },
                              );
                            },
                            child: Row(
                              children: [
                                Icon(Icons.colorize_rounded, size: 14, color: Color(selectedColor)),
                                const SizedBox(width: 4),
                                Text(
                                  isEn ? 'Custom Color' : 'เลือกสีอิสระ',
                                  style: TextStyle(
                                    color: Color(selectedColor),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 44,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _colorPalette.length,
                          itemBuilder: (context, idx) {
                            final colorVal = _colorPalette[idx];
                            final isSelected = selectedColor == colorVal;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setModalState(() {
                                  selectedColor = colorVal;
                                });
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Color(colorVal),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? Colors.white : Colors.transparent,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(colorVal).withOpacity(0.4),
                                      blurRadius: isSelected ? 8 : 2,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Icon Grid Header & Group Filter
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEn ? 'Select Icon' : 'เลือกไอคอนหมวดหมู่',
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${CategoryCatalog.availableIcons.length} ${isEn ? 'icons' : 'ไอคอน'}',
                            style: TextStyle(
                              color: subTextColor.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Group filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(isEn ? 'All' : '✨ ทั้งหมด', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: selectedGroupIndex == 0 ? Colors.white : subTextColor)),
                                selected: selectedGroupIndex == 0,
                                selectedColor: Color(selectedColor),
                                backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                onSelected: (sel) => setModalState(() => selectedGroupIndex = 0),
                              ),
                            ),
                            ...List.generate(CategoryCatalog.iconGroups.length, (gIdx) {
                              final group = CategoryCatalog.iconGroups[gIdx];
                              final isSel = selectedGroupIndex == gIdx + 1;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text('${group.emoji} ${isEn ? group.titleEn : group.title}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSel ? Colors.white : subTextColor)),
                                  selected: isSel,
                                  selectedColor: Color(selectedColor),
                                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                  onSelected: (sel) => setModalState(() => selectedGroupIndex = gIdx + 1),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Filtered Icons Grid
                      Builder(
                        builder: (context) {
                          final iconsToDisplay = selectedGroupIndex == 0
                              ? CategoryCatalog.availableIcons
                              : CategoryCatalog.iconGroups[selectedGroupIndex - 1].icons;

                          return SizedBox(
                            height: 190,
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: iconsToDisplay.length,
                              itemBuilder: (context, idx) {
                                final item = iconsToDisplay[idx];
                                final isSelected = selectedIconKey == item.key;
                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setModalState(() {
                                      selectedIconKey = item.key;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isSelected ? Color(selectedColor) : (isDark ? const Color(0xFF1E293B) : Colors.white),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? Color(selectedColor) : (isDark ? Colors.white12 : Colors.grey.shade200),
                                        width: isSelected ? 2 : 1,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: Color(selectedColor).withValues(alpha: 0.35),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Icon(
                                      item.icon,
                                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                      size: 22,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty) return;

                            if (isEditing) {
                              final updated = existingCat.copyWith(
                                name: name,
                                iconKey: selectedIconKey,
                                colorValue: selectedColor,
                              );
                              widget.controller.updateCategory(updated);
                            } else {
                              final newCat = CategoryItem(
                                id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
                                name: name,
                                iconKey: selectedIconKey,
                                colorValue: selectedColor,
                                type: categoryType,
                                isDefault: false,
                              );
                              widget.controller.addCategory(newCat);
                            }
                            HapticFeedback.mediumImpact();
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(selectedColor),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Text(
                            isEditing
                                ? (isEn ? 'Save Changes' : 'บันทึกการแก้ไข')
                                : (isEn ? 'Create Category' : 'สร้างหมวดหมู่ใหม่'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showCustomColorPicker({
    required Color initialColor,
    required ValueChanged<Color> onColorSelected,
  }) {
    final isDark = widget.controller.isDarkMode;
    final isEn = widget.controller.isEnglish;
    double r = initialColor.red.toDouble();
    double g = initialColor.green.toDouble();
    double b = initialColor.blue.toDouble();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setPickerState) {
            final currentColor = Color.fromARGB(255, r.toInt(), g.toInt(), b.toInt());
            return AlertDialog(
              backgroundColor: isDark ? MeowTheme.navySurface : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(color: currentColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEn ? 'Custom Color' : 'เลือกสีอิสระ',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: currentColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: currentColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '#${currentColor.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Red Slider
                    Row(
                      children: [
                        const Text('R', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Slider(
                            value: r,
                            min: 0,
                            max: 255,
                            activeColor: Colors.red,
                            onChanged: (v) => setPickerState(() => r = v),
                          ),
                        ),
                        SizedBox(width: 32, child: Text('${r.toInt()}', style: const TextStyle(fontSize: 12))),
                      ],
                    ),
                    // Green Slider
                    Row(
                      children: [
                        const Text('G', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Slider(
                            value: g,
                            min: 0,
                            max: 255,
                            activeColor: Colors.green,
                            onChanged: (v) => setPickerState(() => g = v),
                          ),
                        ),
                        SizedBox(width: 32, child: Text('${g.toInt()}', style: const TextStyle(fontSize: 12))),
                      ],
                    ),
                    // Blue Slider
                    Row(
                      children: [
                        const Text('B', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Slider(
                            value: b,
                            min: 0,
                            max: 255,
                            activeColor: Colors.blue,
                            onChanged: (v) => setPickerState(() => b = v),
                          ),
                        ),
                        SizedBox(width: 32, child: Text('${b.toInt()}', style: const TextStyle(fontSize: 12))),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(isEn ? 'Cancel' : 'ยกเลิก'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    onColorSelected(currentColor);
                    Navigator.pop(ctx);
                  },
                  child: Text(isEn ? 'Apply' : 'ใช้สีนี้'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteCategory(CategoryItem cat) {
    final isEn = widget.controller.isEnglish;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.controller.isDarkMode ? MeowTheme.navySurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: MeowTheme.expenseRed),
            const SizedBox(width: 8),
            Text(isEn ? 'Delete Category?' : 'ลบหมวดหมู่นี้?'),
          ],
        ),
        content: Text(
          isEn
              ? 'Are you sure you want to delete "${cat.name}"?'
              : 'คุณต้องการลบหมวดหมู่ "${cat.name}" ใช่หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isEn ? 'Cancel' : 'ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.controller.deleteCategory(cat.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MeowTheme.expenseRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(isEn ? 'Delete' : 'ลบ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.controller.isDarkMode;
    final isEn = widget.controller.isEnglish;
    final bg = isDark ? MeowTheme.navyBackground : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final expenseCats = widget.controller.expenseCategories;
        final incomeCats = widget.controller.incomeCategories;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: isDark ? MeowTheme.navySurface : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              isEn ? 'Manage & Order Categories' : 'จัดลำดับ & จัดการหมวดหมู่',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: textColor),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: MeowTheme.mustardYellow,
              indicatorWeight: 3,
              labelColor: MeowTheme.mustardYellow,
              unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: [
                Tab(text: isEn ? 'Expense (${expenseCats.length})' : 'หมวดรายจ่าย (${expenseCats.length})'),
                Tab(text: isEn ? 'Income (${incomeCats.length})' : 'หมวดรายรับ (${incomeCats.length})'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildReorderableCategoryList(expenseCats, CategoryType.expense),
              _buildReorderableCategoryList(incomeCats, CategoryType.income),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              final type = _tabController.index == 0 ? CategoryType.expense : CategoryType.income;
              _showAddOrEditCategoryDialog(defaultType: type);
            },
            backgroundColor: MeowTheme.mustardYellow,
            foregroundColor: MeowTheme.textDarkPrimary,
            elevation: 4,
            icon: const Icon(Icons.add_rounded, size: 22),
            label: Text(
              isEn ? 'Add Category' : 'เพิ่มหมวดหมู่',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReorderableCategoryList(List<CategoryItem> list, CategoryType type) {
    final isDark = widget.controller.isDarkMode;
    final isEn = widget.controller.isEnglish;
    final cardBg = isDark ? MeowTheme.navySurface : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? Colors.white10 : const Color(0xFFE2E8F0);

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.category_outlined, size: 48, color: MeowTheme.textLightMuted),
            const SizedBox(height: 12),
            Text(
              isEn ? 'No categories yet' : 'ยังไม่มีหมวดหมู่',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Reorder Tip Banner
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: MeowTheme.mustardYellow.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: MeowTheme.mustardYellow.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.swap_vert_rounded, size: 18, color: Color(0xFFB45309)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isEn
                      ? 'Drag handles or tap arrows to reorder freely'
                      : 'แตะค้างแล้วลาก หรือแตะลูกศรขึ้น/ลง เพื่อจัดเรียงลำดับได้อิสระ',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Reorderable ListView
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 85),
            itemCount: list.length,
            onReorder: (oldIndex, newIndex) {
              HapticFeedback.mediumImpact();
              widget.controller.reorderCategories(type, oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final cat = list[index];
              return Container(
                key: ValueKey(cat.id),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      // Drag Handle Indicator
                      ReorderableDragStartListener(
                        index: index,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          color: Colors.transparent,
                          child: Icon(
                            Icons.drag_indicator_rounded,
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Category Icon Box
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cat.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(cat.icon, color: cat.color, size: 22),
                      ),
                      const SizedBox(width: 12),

                      // Category Name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.name,
                              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ลำดับที่ ${index + 1} • ${cat.isDefault ? (isEn ? "Default" : "เริ่มต้น") : (isEn ? "Custom" : "กำหนดเอง")}',
                              style: TextStyle(color: subTextColor, fontSize: 11),
                            ),
                          ],
                        ),
                      ),

                      // Move Up / Move Down Quick Actions
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (index > 0)
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                widget.controller.reorderCategories(type, index, index - 1);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.arrow_upward_rounded, size: 16, color: subTextColor),
                              ),
                            ),
                          if (index < list.length - 1)
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                widget.controller.reorderCategories(type, index, index + 2);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.arrow_downward_rounded, size: 16, color: subTextColor),
                              ),
                            ),

                          // Edit Action
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 18, color: MeowTheme.mustardYellow),
                            tooltip: isEn ? 'Edit' : 'แก้ไข',
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: const EdgeInsets.all(4),
                            onPressed: () => _showAddOrEditCategoryDialog(existingCat: cat, defaultType: type),
                          ),

                          // Delete Action (all categories can be deleted)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: MeowTheme.expenseRed),
                            tooltip: isEn ? 'Delete' : 'ลบ',
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: const EdgeInsets.all(4),
                            onPressed: () => _confirmDeleteCategory(cat),
                          ),
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
    );
  }
}
