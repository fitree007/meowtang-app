import 'package:flutter/material.dart';

enum AccountType {
  bank,
  eWallet,
  cash,
  investment,
}

class AccountItem {
  final String id;
  final String name;
  final String bankCode; // KBANK, SCB, KTB, BBL, TTB, GSB, TRUEMONEY, SHOPEEPAY, CASH, CRYPTO
  final String accountNumber;
  final double balance;
  final int colorValue;
  final AccountType type;
  final bool isDefault;
  final bool allowAutoDeduction; // true = อนุญาตให้อ่านสลิป/ดึงเงินอัตโนมัติ, false = ไม่ดึงเงินจากบัญชีนี้

  AccountItem({
    required this.id,
    required this.name,
    required this.bankCode,
    required this.accountNumber,
    this.balance = 0.0,
    required this.colorValue,
    this.type = AccountType.bank,
    this.isDefault = false,
    this.allowAutoDeduction = true,
  });

  Color get color => Color(colorValue);

  String get bankDisplayName {
    switch (bankCode.toUpperCase()) {
      case 'KBANK':
        return 'กสิกรไทย (KBank)';
      case 'SCB':
        return 'ไทยพาณิชย์ (SCB)';
      case 'KTB':
        return 'กรุงไทย (Krungthai NEXT)';
      case 'BBL':
        return 'กรุงเทพ (Bualuang)';
      case 'TTB':
        return 'ทีเอ็มบีธนชาต (ttb)';
      case 'GSB':
        return 'ออมสิน (GSB)';
      case 'TRUEMONEY':
        return 'TrueMoney Wallet';
      case 'SHOPEEPAY':
        return 'ShopeePay';
      case 'CASH':
        return 'เงินสด (Cash)';
      case 'CRYPTO':
        return 'พอร์ตลงทุน / หุ้น';
      default:
        return name;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bankCode': bankCode,
      'accountNumber': accountNumber,
      'balance': balance,
      'colorValue': colorValue,
      'type': type.name,
      'isDefault': isDefault,
      'allowAutoDeduction': allowAutoDeduction,
    };
  }

  factory AccountItem.fromJson(Map<String, dynamic> json) {
    return AccountItem(
      id: json['id'] as String,
      name: json['name'] as String,
      bankCode: json['bankCode'] as String,
      accountNumber: json['accountNumber'] as String,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      colorValue: json['colorValue'] as int? ?? 0xFF10B981,
      type: json['type'] != null
          ? AccountType.values.byName(json['type'] as String)
          : AccountType.bank,
      isDefault: json['isDefault'] as bool? ?? false,
      allowAutoDeduction: json['allowAutoDeduction'] as bool? ?? true,
    );
  }

  AccountItem copyWith({
    String? id,
    String? name,
    String? bankCode,
    String? accountNumber,
    double? balance,
    int? colorValue,
    AccountType? type,
    bool? isDefault,
    bool? allowAutoDeduction,
  }) {
    return AccountItem(
      id: id ?? this.id,
      name: name ?? this.name,
      bankCode: bankCode ?? this.bankCode,
      accountNumber: accountNumber ?? this.accountNumber,
      balance: balance ?? this.balance,
      colorValue: colorValue ?? this.colorValue,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      allowAutoDeduction: allowAutoDeduction ?? this.allowAutoDeduction,
    );
  }
}
