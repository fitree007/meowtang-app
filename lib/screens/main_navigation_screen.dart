import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import 'meow_dashboard_screen.dart';
import 'meow_analytics_screen.dart';
import 'meow_premium_screen.dart';
import 'meow_human_screen.dart';
import 'meow_entry_screen.dart';
import '../services/native_bridge_service.dart';
import '../widgets/tactile_button.dart';
import 'slip_auto_record_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final ExpenseController controller;

  const MainNavigationScreen({super.key, required this.controller});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowSalaryNotice();
    });
    _checkInitialNotificationSlip();
    NativeBridgeService.setOpenSlipFromNotificationListener((slipData) {
      final path = slipData['path'] as String? ?? '';
      if (path.isNotEmpty && mounted) {
        _openSlipEditScreen(path);
      }
    });
    NativeBridgeService.setDataReloadListener(() {
      if (mounted) {
        widget.controller.reloadFromStorage();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Instantly reload transactions, accounts and balances when app is resumed
      widget.controller.reloadFromStorage();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _checkAndShowSalaryNotice();
      });
    }
  }

  void _checkAndShowSalaryNotice() {
    final notice = widget.controller.lastAutoSalaryRecordedNotice;
    if (notice != null && notice.isNotEmpty && mounted) {
      widget.controller.clearAutoSalaryNotice();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          backgroundColor: const Color(0xFF10B981),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              const Icon(Icons.paid_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  notice,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _checkInitialNotificationSlip() async {
    final path = await NativeBridgeService.getInitialSlipPath();
    if (path != null && path.isNotEmpty && mounted) {
      _openSlipEditScreen(path);
    }
  }

  void _openSlipEditScreen(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SlipAutoRecordScreen(
          controller: widget.controller,
          initialImagePath: path,
        ),
      ),
    );
  }

  void _openAddTransactionScreen() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MeowEntryScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final currentTheme = widget.controller.currentTheme;

        final screens = [
          MeowDashboardScreen(controller: widget.controller),
          MeowAnalyticsScreen(controller: widget.controller),
          MeowPremiumScreen(controller: widget.controller),
          MeowHumanScreen(controller: widget.controller),
        ];

        final navBg = currentTheme.cardBackground;
        final borderCol = currentTheme.borderColor;
        final unselectedCol = currentTheme.textSecondaryColor;
        final selectedCol = currentTheme.primaryDark;

        return Scaffold(
          backgroundColor: currentTheme.scaffoldBackground,
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: navBg,
              border: Border(top: BorderSide(color: borderCol, width: 1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                height: 64,
                child: Row(
                  children: [
                    // Tab 0: 1. ภาพรวม (Overview / Dashboard)
                    Expanded(
                      child: TactileButton(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          if (_currentIndex == 0) {
                            MeowDashboardScreen.onScrollToTopRequested?.call();
                          } else {
                            setState(() => _currentIndex = 0);
                          }
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined,
                              color: _currentIndex == 0 ? selectedCol : unselectedCol,
                              size: 24,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.controller.tr('nav_overview'),
                              style: TextStyle(
                                color: _currentIndex == 0 ? selectedCol : unselectedCol,
                                fontSize: 11,
                                fontWeight: _currentIndex == 0 ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Tab 1: 2. สถิติ (Analytics / Trends)
                    Expanded(
                      child: TactileButton(
                        onTap: () => setState(() => _currentIndex = 1),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _currentIndex == 1 ? Icons.pie_chart_rounded : Icons.pie_chart_outline_rounded,
                              color: _currentIndex == 1 ? selectedCol : unselectedCol,
                              size: 24,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.controller.tr('nav_stats'),
                              style: TextStyle(
                                color: _currentIndex == 1 ? selectedCol : unselectedCol,
                                fontSize: 11,
                                fontWeight: _currentIndex == 1 ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Center (+): 3. ปุ่ม+ (Add Entry with Calculator)
                    Expanded(
                      child: GestureDetector(
                        onTap: _openAddTransactionScreen,
                        child: Center(
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: currentTheme.primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: currentTheme.primaryColor.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Tab 2: 4. พรีเมี่ยม (Premium Hub)
                    Expanded(
                      child: TactileButton(
                        onTap: () => setState(() => _currentIndex = 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _currentIndex == 2 ? Icons.workspace_premium_rounded : Icons.workspace_premium_outlined,
                              color: _currentIndex == 2 ? selectedCol : unselectedCol,
                              size: 24,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.controller.tr('nav_premium'),
                              style: TextStyle(
                                color: _currentIndex == 2 ? selectedCol : unselectedCol,
                                fontSize: 11,
                                fontWeight: _currentIndex == 2 ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Tab 3: 5. เมนู (Menu / Settings)
                    Expanded(
                      child: TactileButton(
                        onTap: () => setState(() => _currentIndex = 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _currentIndex == 3 ? Icons.grid_view_rounded : Icons.grid_view_outlined,
                              color: _currentIndex == 3 ? selectedCol : unselectedCol,
                              size: 24,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.controller.tr('nav_menu'),
                              style: TextStyle(
                                color: _currentIndex == 3 ? selectedCol : unselectedCol,
                                fontSize: 11,
                                fontWeight: _currentIndex == 3 ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
