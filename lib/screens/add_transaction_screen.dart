import 'package:flutter/material.dart';
import '../state/expense_controller.dart';
import '../models/transaction_item.dart';
import 'meow_entry_screen.dart';

class AddTransactionScreen extends StatelessWidget {
  final ExpenseController controller;
  final TransactionType initialType;
  final double? initialAmount;
  final String? initialNote;

  const AddTransactionScreen({
    super.key,
    required this.controller,
    this.initialType = TransactionType.expense,
    this.initialAmount,
    this.initialNote,
  });

  @override
  Widget build(BuildContext context) {
    return MeowEntryScreen(
      controller: controller,
      initialType: initialType,
      initialAmount: initialAmount,
      initialNote: initialNote,
    );
  }
}
