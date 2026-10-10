import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'services/ad_service.dart';
import 'services/billing_service.dart';
import 'services/team_code_service.dart';
import 'services/storage_service.dart';
import 'state/expense_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D1117),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final storage = StorageService();
  await storage.init();

  final controller = ExpenseController(storage);

  // Initialize Google Mobile Ads
  await AdMobService.instance.initialize();

  // Google Play Billing (Play Store edition): checks active VIP subscriptions.
  // Not awaited, so a slow Play connection never delays the first frame.
  BillingService.instance.init(controller);
  // Team VIP: switch off codes that were cancelled in this update.
  TeamCodeService.recheck(controller);

  runApp(AiExpenseTrackerApp(controller: controller));
}
