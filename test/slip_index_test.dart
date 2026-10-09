import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/models/transaction_item.dart';
import 'package:ai_expense_tracker/services/duplicate_slip_checker.dart';

TransactionItem _tx(
  String id, {
  double amount = 100,
  DateTime? date,
  String? slip,
  String? ref,
  String? bank,
  String? note,
}) =>
    TransactionItem(
      id: id,
      title: 't',
      amount: amount,
      type: TransactionType.expense,
      date: date ?? DateTime(2026, 9, 1, 10, 0),
      accountId: 'acc',
      categoryId: 'cat',
      categoryName: 'c',
      slipImageUrl: slip,
      slipRefId: ref,
      bankName: bank,
      note: note,
    );

void main() {
  // Saved transactions in the shapes the app stores them.
  final saved = [
    _tx('a', slip: '/storage/emulated/0/Pictures/KPlus/kp_001.jpg', ref: 'KB123', bank: 'KBANK'),
    _tx('b', amount: 250, slip: '/data/user/0/app/saved_slips/slip_99_scb_77.jpg', ref: 'SLIP-1_1', bank: 'SCB'),
    _tx('c', amount: 0, date: DateTime(2026, 9, 2, 8), slip: '/x/paotang_1.jpg', ref: 'NO-QR-1', bank: 'เป๋าตัง (PaoTang)'),
    _tx('d', amount: 75, date: DateTime(2026, 9, 3, 12, 0, 30), bank: 'KTB'),
    _tx('e', amount: 40, note: 'นำเข้าจาก old_receipt.png'),
  ];
  final index = SlipIndex.from(saved);

  // Probes covering each matching rule plus near misses.
  final probes = <String, Map<String, Object?>>{
    'same path': {'path': '/storage/emulated/0/Pictures/KPlus/kp_001.jpg'},
    'same file name elsewhere': {'path': '/sdcard/Download/kp_001.jpg', 'name': 'kp_001.jpg'},
    'saved copy suffix': {'path': '/storage/emulated/0/Pictures/SCB EASY/scb_77.jpg', 'name': 'scb_77.jpg'},
    'same bank ref': {'path': '/a/new.jpg', 'ref': 'KB123'},
    'different ref, same name': {'path': '/a/kp_001.jpg', 'name': 'kp_001.jpg', 'ref': 'KB999'},
    'zero amount same day same bank': {'path': '/a/z.jpg', 'amount': 0.0, 'date': DateTime(2026, 9, 2, 20), 'bank': 'PaoTang'},
    'same second same amount same bank': {'path': '/a/q.jpg', 'amount': 75.0, 'date': DateTime(2026, 9, 3, 12, 0, 31), 'bank': 'KTB'},
    'same amount, other bank': {'path': '/a/q2.jpg', 'amount': 75.0, 'date': DateTime(2026, 9, 3, 12, 0, 31), 'bank': 'SCB'},
    'file named in a note': {'path': '/a/old_receipt.png', 'name': 'old_receipt.png'},
    'brand new slip': {'path': '/storage/emulated/0/Pictures/KPlus/kp_002.jpg', 'ref': 'KB124', 'amount': 120.0},
    'generic name': {'path': '/a/image.jpg', 'name': 'image.jpg'},
  };

  for (final entry in probes.entries) {
    test('index gives the same answer as the full scan: ${entry.key}', () {
      bool check(SlipIndex? i) => DuplicateSlipChecker.isDuplicate(
            existingTransactions: saved,
            index: i,
            filePath: entry.value['path'] as String?,
            fileName: entry.value['name'] as String?,
            refId: entry.value['ref'] as String?,
            amount: entry.value['amount'] as double?,
            date: entry.value['date'] as DateTime?,
            bankName: entry.value['bank'] as String?,
          );
      expect(check(index), check(null));
    });
  }

  test('expected outcomes', () {
    bool dup(String path, {String? name, String? ref}) => DuplicateSlipChecker.isDuplicate(
          existingTransactions: const [],
          index: index,
          filePath: path,
          fileName: name,
          refId: ref,
        );
    expect(dup('/sdcard/Download/kp_001.jpg', name: 'kp_001.jpg'), isTrue);
    expect(dup('/x/scb_77.jpg', name: 'scb_77.jpg'), isTrue);
    expect(dup('/x/kp_002.jpg', name: 'kp_002.jpg'), isFalse);
  });

  test('items added later are found', () {
    final i = SlipIndex.from(const []);
    i.add(_tx('n', slip: '/p/new_slip.jpg'));
    expect(
      DuplicateSlipChecker.isDuplicate(existingTransactions: const [], index: i, filePath: '/q/new_slip.jpg', fileName: 'new_slip.jpg'),
      isTrue,
    );
  });
}
