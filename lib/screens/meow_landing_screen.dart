import 'package:flutter/material.dart';
import '../theme/meow_theme.dart';
import '../widgets/meow_mascot_widget.dart';

class MeowLandingScreen extends StatelessWidget {
  final VoidCallback onStart;

  const MeowLandingScreen({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MeowTheme.navyBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Top Brand Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const MeowMascotWidget(size: 36, isHeadOnly: true),
                  const SizedBox(width: 10),
                  const Text(
                    'เหมียวตังค์',
                    style: TextStyle(
                      color: MeowTheme.textLightPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Center Card with Mascot
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: MeowTheme.navySurface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: MeowTheme.borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const MeowMascotWidget(size: 110, withPen: true),
                      const SizedBox(height: 20),
                      const Text(
                        'จดรายรับ-รายจ่ายง่ายๆ\nรู้ทันทุกการใช้จ่าย',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: MeowTheme.mustardYellow,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'แอพบันทึกการเงินดีไซน์มินิมอล ใช้งานง่าย พร้อมระบบอ่านสลิปโอนเงินจากคลังภาพในมือถือ และวิเคราะห์กราฟสรุปรายเดือน',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: MeowTheme.textLightSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 3 Feature Pills
                      _buildFeatureRow(Icons.photo_library_outlined, 'อ่านสลิปโอนเงินจากคลังภาพมือถือ'),
                      const SizedBox(height: 10),
                      _buildFeatureRow(Icons.pie_chart_outline, 'กราฟโดนัทสรุปยอดแยกหมวดหมู่อัตโนมัติ'),
                      const SizedBox(height: 10),
                      _buildFeatureRow(Icons.calendar_month_outlined, 'เลือกดูและจัดการตาม วัน / เดือน / ปี ได้อิสระ'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Contact Email
              const Text(
                'Contact Email fitree.work24725@gmail.com',
                style: TextStyle(
                  color: MeowTheme.textLightMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              // Start Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: MeowTheme.blueButtonGradient,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: MeowTheme.actionBlue.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: onStart,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'เริ่มต้นใช้งาน',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: MeowTheme.navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MeowTheme.borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: MeowTheme.mustardYellow, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: MeowTheme.textLightPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
