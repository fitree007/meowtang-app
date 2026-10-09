import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/thai_bank_detector.dart';
import '../state/expense_controller.dart';
import '../models/account_item.dart';
import '../widgets/bank_badge.dart';
import '../widgets/meow_fx.dart';
import '../utils/format_utils.dart';

/// Parses an amount the user typed, accepting thousands separators ("1,000.50").
/// Empty input means 0; anything else that is not a number returns null.
double? parseMoneyInput(String text) {
  final t = text.replaceAll(',', '').replaceAll('฿', '').replaceAll(' ', '').trim();
  if (t.isEmpty) return 0;
  return double.tryParse(t);
}

String _baht(double v) => '฿${FormatUtils.formatCurrency(v, trimZero: true)}';

/// Wallet / e-money providers (everything else except cash and PromptPay is a bank).
const _walletCodes = {'PAOTANG', 'TRUEMONEY', 'SHOPEEPAY', 'RABBITLINEPAY', 'AIRPAY', 'BLUECONNECT'};

class AccountManagementScreen extends StatefulWidget {
  final ExpenseController controller;

  const AccountManagementScreen({super.key, required this.controller});

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  ExpenseController get _ctl => widget.controller;

  List<ThaiBankInfo> get _bankList => ThaiBankDetector.supportedBanks
      .where((b) => b.code != 'CASH' && b.code != 'PROMPTPAY' && !_walletCodes.contains(b.code))
      .toList();

  List<ThaiBankInfo> get _walletList => ThaiBankDetector.supportedBanks.where((b) => _walletCodes.contains(b.code)).toList();

  static String _last4(String number) {
    final d = number.replaceAll(RegExp(r'\D'), '');
    return d.length >= 4 ? d.substring(d.length - 4) : '';
  }

  String _meta(AccountItem a) {
    if (a.type == AccountType.cash) return 'เงินสดในกระเป๋า';
    final bank = a.bankDisplayName.replaceFirst('ธนาคาร', '').trim();
    final l4 = _last4(a.accountNumber);
    final label = a.type == AccountType.eWallet ? 'e-Wallet' : bank;
    return l4.isEmpty ? label : '$label • เลขท้าย $l4';
  }

  // ---------------------------------------------------------------- edit sheet
  void _openEdit(AccountItem account) {
    final c = _C.of(_ctl);
    final nameCtrl = TextEditingController(text: account.name);
    final numberCtrl = TextEditingController(
      text: account.accountNumber == 'xxx-x-xxxxx-x' || account.accountNumber == 'CASH-WALLET' ? '' : account.accountNumber,
    );
    final balanceCtrl = TextEditingController(text: FormatUtils.formatCurrency(account.balance, trimZero: true));
    var auto = account.allowAutoDeduction;
    var primary = account.isDefault;
    final isCash = account.type == AccountType.cash;
    final kind = isCash ? 'เงินสด (ไม่มีสลิป)' : (account.type == AccountType.eWallet ? 'กระเป๋าเงินดิจิทัล' : 'บัญชีธนาคาร');

    _showCalmSheet<void>(context, c, title: 'แก้ไขบัญชี', subtitle: kind, builder: (ctx, setSheet) {
      final nameErr = nameCtrl.text.trim().isEmpty;
      final newBal = parseMoneyInput(balanceCtrl.text);
      String diffText;
      if (newBal == null) {
        diffText = 'ยอดเดิม ${_baht(account.balance)}';
      } else {
        final diff = newBal - account.balance;
        diffText = diff.abs() < 0.005
            ? 'ยอดเดิม ${_baht(account.balance)}'
            : '${diff > 0 ? 'เพิ่มขึ้น' : 'ลดลง'} ${_baht(diff.abs())} จากยอดเดิม';
      }
      final canDelete = _ctl.accounts.length > 1;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _fieldLabel(c, 'ชื่อเรียกบัญชี'),
          TextField(
            controller: nameCtrl,
            onChanged: (_) => setSheet(() {}),
            style: TextStyle(color: c.text, fontSize: 15),
            decoration: _inputDeco(c, error: nameErr),
          ),
          if (nameErr)
            Padding(padding: const EdgeInsets.only(top: 4), child: Text('กรุณาใส่ชื่อบัญชี', style: TextStyle(fontSize: 12.5, color: c.danger))),
          if (!isCash) ...[
            const SizedBox(height: 14),
            _fieldLabel(c, account.type == AccountType.eWallet ? 'เบอร์ / เลขกระเป๋า' : 'เลขที่บัญชี', hint: '(ไม่บังคับ)'),
            TextField(
              controller: numberCtrl,
              style: TextStyle(color: c.text, fontSize: 15),
              decoration: _inputDeco(c, hint: 'ใส่ 4 ตัวท้ายก็พอ'),
            ),
          ],
          const SizedBox(height: 14),
          _fieldLabel(c, 'ยอดเงินคงเหลือตอนนี้'),
          TextField(
            controller: balanceCtrl,
            onChanged: (_) => setSheet(() {}),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: c.text, fontSize: 19, fontWeight: FontWeight.w700),
            decoration: _inputDeco(c, prefix: '฿  ', error: newBal == null),
          ),
          const SizedBox(height: 6),
          Text(
            newBal == null ? 'กรุณาใส่ยอดเงินเป็นตัวเลข เช่น 1,500 หรือ 1500.50' : 'พิมพ์ได้ทั้ง 98400 หรือ 98,400 • $diffText',
            style: TextStyle(fontSize: 12.5, color: newBal == null ? c.danger : c.sub),
          ),
          const SizedBox(height: 14),
          _calmCard(
            c,
            child: Column(
              children: [
                Opacity(
                  opacity: isCash ? 0.5 : 1,
                  child: InkWell(
                    onTap: isCash ? null : () => setSheet(() => auto = !auto),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('บันทึกสลิปเข้าบัญชีนี้อัตโนมัติ', style: c.title.copyWith(fontSize: 14.5)),
                                const SizedBox(height: 2),
                                Text(
                                  isCash
                                      ? 'เงินสดไม่มีสลิป จึงเปิดไม่ได้'
                                      : auto
                                          ? 'สลิปที่นำเข้าจะปรับยอดบัญชีนี้ให้เอง'
                                          : 'ปิดอยู่ สลิปจะไม่ปรับยอดบัญชีนี้',
                                  style: c.subtitle,
                                ),
                              ],
                            ),
                          ),
                          _calmSwitch(c, auto && !isCash, isCash ? null : (v) => setSheet(() => auto = v)),
                        ],
                      ),
                    ),
                  ),
                ),
                Divider(height: 1, thickness: 1, color: c.border, indent: 16),
                InkWell(
                  onTap: primary ? null : () => setSheet(() => primary = true),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 60),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      child: Row(
                        children: [
                          Icon(Icons.star_border_rounded, size: 22, color: c.icon),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  primary ? 'บัญชีนี้เป็นบัญชีหลัก' : 'ตั้งเป็นบัญชีหลัก',
                                  style: c.title.copyWith(fontSize: 14.5, color: primary ? c.text : c.link),
                                ),
                                const SizedBox(height: 2),
                                Text('บัญชีหลักจะถูกเลือกให้ก่อนเวลาจดรายการ', style: c.subtitle),
                              ],
                            ),
                          ),
                          if (primary) Icon(Icons.check_rounded, size: 22, color: c.accent),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _primaryButton(c, 'บันทึกการแก้ไข', nameErr || newBal == null
              ? null
              : () async {
                  final name = nameCtrl.text.trim();
                  final num = numberCtrl.text.trim();
                  await _ctl.updateAccount(account.copyWith(
                    name: name,
                    accountNumber: isCash ? account.accountNumber : (num.isEmpty ? 'xxx-x-xxxxx-x' : num),
                    balance: newBal,
                    allowAutoDeduction: isCash ? account.allowAutoDeduction : auto,
                  ));
                  if (primary && !account.isDefault) await _ctl.setDefaultAccount(account.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) _calmToast(context, 'บันทึกการแก้ไข “$name” แล้ว');
                }),
          if (canDelete) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 48,
              child: TextButton.icon(
                onPressed: () async {
                  final others = _ctl.accounts.where((a) => a.id != account.id).toList();
                  final ok = await _confirmDialog(
                    ctx,
                    c,
                    title: 'ลบบัญชี “${account.name}” ?',
                    body: 'ยอด ${_baht(account.balance)} จะหายไปจากยอดรวม รายการที่เคยบันทึกยังอยู่ครบ แต่จะไม่ผูกกับบัญชีนี้แล้ว',
                    note: account.isDefault && others.isNotEmpty ? 'นี่คือบัญชีหลัก ระบบจะตั้ง “${others.first.name}” เป็นบัญชีหลักแทน' : null,
                    confirmLabel: 'ลบบัญชี',
                  );
                  if (!ok) return;
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _deleteWithUndo(account);
                },
                icon: Icon(Icons.delete_outline_rounded, size: 20, color: c.danger),
                label: Text('ลบบัญชีนี้', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: c.danger)),
              ),
            ),
          ],
        ],
      );
    });
  }

  Future<void> _deleteWithUndo(AccountItem account) async {
    final wasDefault = account.isDefault;
    await _ctl.deleteAccount(account.id);
    if (wasDefault && _ctl.accounts.isNotEmpty) await _ctl.setDefaultAccount(_ctl.accounts.first.id);
    if (!mounted) return;
    _calmToast(context, 'ลบบัญชี “${account.name}” แล้ว', actionLabel: 'เลิกทำ', onAction: () async {
      await _ctl.addAccount(account.copyWith(isDefault: false));
      if (wasDefault) await _ctl.setDefaultAccount(account.id);
      if (mounted) _calmToast(context, 'กู้คืนบัญชีแล้ว');
    });
  }

  // ----------------------------------------------------------------- add sheet
  void _openAdd() {
    final c = _C.of(_ctl);
    final nameCtrl = TextEditingController();
    final numberCtrl = TextEditingController();
    final balanceCtrl = TextEditingController();
    var type = AccountType.bank;
    var bank = _bankList.firstWhere((b) => b.code == 'IBANK', orElse: () => _bankList.first);
    var showErr = false;
    nameCtrl.text = bank.nameTh;

    _showCalmSheet<void>(context, c, title: 'เพิ่มบัญชีใหม่', builder: (ctx, setSheet) {
      void pickType(AccountType t) {
        if (t == type) return;
        setSheet(() {
          type = t;
          showErr = false;
          if (t == AccountType.bank) {
            bank = _bankList.firstWhere((b) => b.code == 'IBANK', orElse: () => _bankList.first);
          } else if (t == AccountType.eWallet) {
            bank = _walletList.firstWhere((b) => b.code == 'PAOTANG', orElse: () => _walletList.first);
          } else {
            bank = ThaiBankDetector.getBankByCode('CASH');
          }
          nameCtrl.text = t == AccountType.cash ? 'เงินสด' : bank.nameTh;
        });
      }

      Future<void> pickProvider() async {
        final list = type == AccountType.bank ? _bankList : _walletList;
        final picked = await showModalBottomSheet<ThaiBankInfo>(
          context: ctx,
          backgroundColor: c.card,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (pctx) => SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(pctx).size.height * 0.75),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(children: [
                      Expanded(
                        child: Text(type == AccountType.bank ? 'เลือกธนาคาร' : 'เลือกผู้ให้บริการ',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.text)),
                      ),
                    ]),
                  ),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: list.length,
                      separatorBuilder: (_, _) => Divider(height: 1, color: c.border, indent: 66),
                      itemBuilder: (_, i) {
                        final b = list[i];
                        return ListTile(
                          minTileHeight: 56,
                          leading: BankBadge(bankCode: b.code, size: 32),
                          title: Text(b.nameTh, style: c.title.copyWith(fontSize: 14.5)),
                          trailing: b.code == bank.code ? Icon(Icons.check_rounded, color: c.accent) : null,
                          onTap: () => Navigator.pop(pctx, b),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        if (picked != null) {
          setSheet(() {
            final oldName = bank.nameTh;
            bank = picked;
            if (nameCtrl.text.trim().isEmpty || nameCtrl.text.trim() == oldName) nameCtrl.text = picked.nameTh;
          });
        }
      }

      final hasName = nameCtrl.text.trim().isNotEmpty;
      final bal = parseMoneyInput(balanceCtrl.text);

      Widget seg(String label, AccountType t) {
        final sel = t == type;
        return Expanded(
          child: Material(
            color: sel ? c.card : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () => pickType(t),
              child: SizedBox(
                height: 44,
                child: Center(
                  child: Text(label,
                      style: TextStyle(fontSize: 14, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? c.link : c.sub)),
                ),
              ),
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: c.seg, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [seg('ธนาคาร', AccountType.bank), seg('e-Wallet', AccountType.eWallet), seg('เงินสด', AccountType.cash)]),
          ),
          if (type != AccountType.cash) ...[
            const SizedBox(height: 12),
            _calmCard(
              c,
              child: InkWell(
                onTap: pickProvider,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
                  child: Row(
                    children: [
                      Icon(type == AccountType.bank ? Icons.account_balance_outlined : Icons.phone_iphone_rounded, size: 22, color: c.icon),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(bank.nameTh, maxLines: 1, overflow: TextOverflow.ellipsis, style: c.title.copyWith(fontSize: 14.5)),
                            Text(
                              type == AccountType.bank ? 'แตะเพื่อเลือกจาก ${_bankList.length} ธนาคาร' : 'TrueMoney, ShopeePay, Rabbit LINE Pay ฯลฯ',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: c.subtitle,
                            ),
                          ],
                        ),
                      ),
                      Text('เปลี่ยน', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.link)),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          _fieldLabel(c, 'ชื่อเรียกบัญชี'),
          TextField(
            controller: nameCtrl,
            onChanged: (_) => setSheet(() => showErr = false),
            style: TextStyle(color: c.text, fontSize: 15),
            decoration: _inputDeco(c,
                hint: type == AccountType.cash ? 'เช่น เงินสดติดบ้าน' : (type == AccountType.bank ? 'เช่น บัญชีออมเงิน' : 'เช่น ShopeePay'),
                error: showErr),
          ),
          if (showErr)
            Padding(padding: const EdgeInsets.only(top: 4), child: Text('กรุณาใส่ชื่อบัญชีก่อนบันทึก', style: TextStyle(fontSize: 12.5, color: c.danger))),
          if (type != AccountType.cash) ...[
            const SizedBox(height: 14),
            _fieldLabel(c, type == AccountType.bank ? 'เลขที่บัญชี' : 'เบอร์ / เลขกระเป๋า', hint: '(ไม่บังคับ)'),
            TextField(controller: numberCtrl, style: TextStyle(color: c.text, fontSize: 15), decoration: _inputDeco(c, hint: 'ใส่ 4 ตัวท้ายก็พอ')),
          ],
          const SizedBox(height: 14),
          _fieldLabel(c, 'ยอดเงินคงเหลือเริ่มต้น'),
          TextField(
            controller: balanceCtrl,
            onChanged: (_) => setSheet(() {}),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: c.text, fontSize: 19, fontWeight: FontWeight.w700),
            decoration: _inputDeco(c, prefix: '฿  ', hint: '0', error: bal == null),
          ),
          if (bal == null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('กรุณาใส่ยอดเงินเป็นตัวเลข เช่น 1,500 หรือ 1500.50', style: TextStyle(fontSize: 12.5, color: c.danger)),
            ),
          const SizedBox(height: 18),
          _primaryButton(c, 'บันทึกและเปิดใช้งานบัญชี', !hasName || bal == null
              ? () => setSheet(() => showErr = !hasName)
              : () {
                  final name = nameCtrl.text.trim();
                  final code = type == AccountType.cash ? 'CASH' : bank.code;
                  final meta = ThaiBankDetector.getBankByCode(code);
                  final newAcc = AccountItem(
                    id: 'acc_${code.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    bankCode: code,
                    accountNumber: numberCtrl.text.trim().isNotEmpty
                        ? numberCtrl.text.trim()
                        : (type == AccountType.cash ? 'CASH-WALLET' : 'xxx-x-xxxxx-x'),
                    balance: bal,
                    colorValue: meta.brandColor.toARGB32(),
                    type: type,
                    allowAutoDeduction: true,
                  );
                  _ctl.addAccount(newAcc);
                  Navigator.pop(ctx);
                  _calmToast(context, 'เพิ่มบัญชี “$name” แล้ว');
                }, color: !hasName || bal == null ? c.disabled : null),
        ],
      );
    });
  }

  // --------------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctl,
      builder: (context, _) {
        final c = _C.of(_ctl);
        final accounts = _ctl.accounts;
        final groups = [
          (AccountType.bank, 'บัญชีธนาคาร', 'ธนาคาร', Icons.account_balance_outlined),
          (AccountType.eWallet, 'กระเป๋าเงินดิจิทัล & e-Wallet', 'e-Wallet', Icons.phone_iphone_rounded),
          (AccountType.cash, 'เงินสด', 'เงินสด', Icons.payments_outlined),
        ];

        return Scaffold(
          backgroundColor: c.page,
          appBar: _calmAppBar(context, c, 'บัญชี & กระเป๋าเงิน', subtitle: 'แตะบัญชีเพื่อแก้ชื่อ เลขบัญชี หรือยอดเงิน'),
          bottomNavigationBar: _calmBottomBar(c, _primaryButton(c, 'เพิ่มบัญชีใหม่', _openAdd, icon: Icons.add_rounded)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              FxFadeUp(child: _summary(c, accounts)),
              const SizedBox(height: 20),
              for (var gi = 0; gi < groups.length; gi++) ...[
                FxFadeUp(index: gi + 1, child: _group(c, accounts, groups[gi])),
                const SizedBox(height: 18),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _summary(_C c, List<AccountItem> accounts) {
    final total = _ctl.totalNetWorth;
    double sumOf(AccountType t) => accounts.where((a) => a.type == t).fold(0.0, (s, a) => s + a.balance);
    final parts = [
      ('ธนาคาร', c.accent, sumOf(AccountType.bank)),
      ('e-Wallet', const Color(0xFF94A3B8), sumOf(AccountType.eWallet)),
      ('เงินสด', c.dark ? const Color(0xFF475569) : const Color(0xFFCBD5E1), sumOf(AccountType.cash)),
    ];
    final positive = parts.fold(0.0, (s, p) => s + (p.$3 > 0 ? p.$3 : 0));

    return _calmCard(
      c,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('ยอดเงินรวมทุกบัญชี', style: TextStyle(fontSize: 13, color: c.sub))),
              Text('${accounts.length} บัญชีที่เปิดใช้', style: TextStyle(fontSize: 12.5, color: c.sub)),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(_baht(total),
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: c.text, fontFeatures: const [FontFeature.tabularFigures()])),
          ),
          const SizedBox(height: 14),
          // Split bar grows from the left (draft fx-grow-x).
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: FxProgress(
                value: 1,
                builder: (_, v) => Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: v.clamp(0.0, 1.0),
                    child: positive <= 0
                        ? Container(color: c.border)
                        : Row(
                            children: [
                              for (var i = 0; i < parts.length; i++)
                                if (parts[i].$3 > 0)
                                  Expanded(
                                    flex: (parts[i].$3 / positive * 1000).round().clamp(1, 1000),
                                    child: Container(
                                      margin: EdgeInsets.only(right: i < parts.length - 1 ? 2 : 0),
                                      color: parts[i].$2,
                                    ),
                                  ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final p in parts)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: p.$2, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text('${p.$1} ${positive > 0 ? (p.$3 / positive * 100).round() : 0}%',
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: c.sub)),
                        ),
                      ]),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(_baht(p.$3), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: c.border),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.receipt_long_outlined, size: 20, color: c.sub),
              const SizedBox(width: 10),
              Expanded(
                child: Text('สลิปที่นำเข้าจะปรับยอดบัญชีธนาคารที่ตรงกันให้อัตโนมัติ เฉพาะบัญชีที่เปิด “บันทึกสลิปเข้าบัญชีนี้”',
                    style: TextStyle(fontSize: 12.5, height: 1.45, color: c.sub)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _group(_C c, List<AccountItem> all, (AccountType, String, String, IconData) g) {
    final list = all.where((a) => a.type == g.$1).toList();
    final total = list.fold(0.0, (s, a) => s + a.balance);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel(c, '${g.$2} (${list.length})', trailing: _baht(total)),
        _calmCard(
          c,
          child: list.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('ยังไม่มี${g.$3} — กด “เพิ่มบัญชีใหม่” ด้านล่าง', style: c.subtitle),
                )
              : Column(
                  children: [
                    for (var i = 0; i < list.length; i++) _accountRow(c, list[i], g.$4, first: i == 0),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _accountRow(_C c, AccountItem a, IconData icon, {required bool first}) {
    final isCash = a.type == AccountType.cash;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        _openEdit(a);
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 10),
        child: Row(
          children: [
            Icon(icon, size: 22, color: c.icon),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 68),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(border: first ? null : Border(top: BorderSide(color: c.border))),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(child: Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: c.title)),
                              if (a.isDefault) ...[const SizedBox(width: 8), Flexible(child: _pill(c, 'บัญชีหลัก'))],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(_meta(a), maxLines: 1, overflow: TextOverflow.ellipsis, style: c.subtitle),
                          if (!isCash && a.allowAutoDeduction) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(Icons.check_rounded, size: 15, color: c.sub),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text('บันทึกสลิปเข้าบัญชีนี้อัตโนมัติ',
                                      maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: c.sub)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_baht(a.balance),
                        style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: c.text, fontFeatures: const [FontFeature.tabularFigures()])),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right_rounded, size: 22, color: c.faint),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Calm monochrome menu-page kit (same look as the menu home). Private copy so
// this screen stays self-contained.
// ---------------------------------------------------------------------------

class _C {
 final Color page, text, sub, icon, faint, card, line, border, seg, accent, link, ok, okText, danger, dangerText, vip, vipLine, disabled;
 final bool dark;

 const _C({
  required this.page,
  required this.text,
  required this.sub,
  required this.icon,
  required this.faint,
  required this.card,
  required this.line,
  required this.border,
  required this.seg,
  required this.accent,
  required this.link,
  required this.ok,
  required this.okText,
  required this.danger,
  required this.dangerText,
  required this.vip,
  required this.vipLine,
  required this.disabled,
  required this.dark,
 });

 factory _C.of(ExpenseController ctl) {
  final t = ctl.currentTheme;
  final dark = ctl.isDarkMode;
  return _C(
   page: t.scaffoldBackground,
   text: t.textColor,
   sub: t.textSecondaryColor,
   icon: dark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
   faint: dark ? Colors.white24 : const Color(0xFFB6BECB),
   card: t.cardBackground,
   line: t.borderColor,
   border: dark ? Colors.white10 : const Color(0xFFEEF0F4),
   seg: dark ? const Color(0xFF0F172A) : const Color(0xFFF1F3F8),
   accent: t.primaryColor,
   link: dark ? const Color(0xFF93C5FD) : t.primaryColor,
   ok: dark ? const Color(0xFF34D399) : const Color(0xFF059669),
   okText: dark ? const Color(0xFF34D399) : const Color(0xFF047857),
   danger: dark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
   dangerText: dark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
   vip: dark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
   vipLine: dark ? const Color(0xFF6B5A1E) : const Color(0xFFE9C98B),
   disabled: dark ? Colors.white12 : const Color(0xFFA5B4CF),
   dark: dark,
  );
 }

 TextStyle get title => TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: text);
 TextStyle get subtitle => TextStyle(fontSize: 12.5, height: 1.35, color: sub);
}

/// White app bar: 44px back chevron, 18/700 title, optional 12px subtitle, optional [bottom] (e.g. a segmented control), 1px bottom line.
PreferredSizeWidget _calmAppBar(BuildContext context, _C c, String title,
  {String? subtitle, List<Widget> actions = const [], Widget? bottom, double bottomHeight = 0}) {
 return PreferredSize(
  preferredSize: Size.fromHeight(61 + bottomHeight),
  child: Material(
   color: c.card,
   child: SafeArea(
    bottom: false,
    child: Container(
     decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
     child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
       SizedBox(
        height: 60,
        child: Padding(
         padding: const EdgeInsets.only(left: 6, right: 8),
         child: Row(
          children: [
           SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
             tooltip: 'ย้อนกลับ',
             padding: EdgeInsets.zero,
             icon: Icon(Icons.chevron_left_rounded, size: 28, color: c.text),
             onPressed: () => Navigator.maybePop(context),
            ),
           ),
           const SizedBox(width: 6),
           Expanded(
            child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.text)),
              if (subtitle != null)
               Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: c.sub)),
             ],
            ),
           ),
           ...actions,
          ],
         ),
        ),
       ),
       if (bottom != null) SizedBox(height: bottomHeight, child: bottom),
      ],
     ),
    ),
   ),
  ),
 );
}

/// Sticky bottom action bar (white, top border).
Widget _calmBottomBar(_C c, Widget child) => Container(
      decoration: BoxDecoration(color: c.card, border: Border(top: BorderSide(color: c.line))),
      child: SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 12), child: child)),
     );

/// Full-width 52px accent button; null [onTap] shows the disabled look.
Widget _primaryButton(_C c, String label, VoidCallback? onTap, {IconData? icon, Color? color, bool busy = false}) {
 final bg = onTap == null ? c.disabled : (color ?? c.accent);
 return SizedBox(
  width: double.infinity,
  height: 52,
  child: ElevatedButton(
   onPressed: busy ? null : onTap,
   style: ElevatedButton.styleFrom(
    backgroundColor: bg,
    disabledBackgroundColor: busy ? bg : c.disabled,
    foregroundColor: Colors.white,
    disabledForegroundColor: Colors.white.withValues(alpha: 0.9),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
   ),
   child: busy
       ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
       : Row(
           mainAxisSize: MainAxisSize.min,
           children: [
            if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
            Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
           ],
          ),
  ),
 );
}

/// Outlined secondary button (44px+).
Widget _outlineButton(_C c, String label, VoidCallback? onTap, {IconData? icon, Color? color, double height = 48}) {
 final fg = color ?? c.text;
 return SizedBox(
  height: height,
  child: OutlinedButton(
   onPressed: onTap,
   style: OutlinedButton.styleFrom(
    foregroundColor: fg,
    side: BorderSide(color: c.line),
    backgroundColor: c.card,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
   ),
   child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
     if (icon != null) ...[Icon(icon, size: 19, color: fg), const SizedBox(width: 8)],
     Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg))),
    ],
   ),
  ),
 );
}

/// 1px-bordered card, radius 16.
Widget _calmCard(_C c, {required Widget child, EdgeInsetsGeometry? padding}) => Container(
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.line)),
      clipBehavior: Clip.antiAlias,
      child: Material(color: Colors.transparent, child: padding == null ? child : Padding(padding: padding, child: child)),
     );

/// 13px/600 grey label above a card group, with an optional right-hand value.
Widget _sectionLabel(_C c, String title, {String? trailing, Widget? trailingWidget}) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
       children: [
        Expanded(child: Text(title, style: TextStyle(color: c.sub, fontSize: 13, fontWeight: FontWeight.w600))),
        if (trailing != null) Text(trailing, style: TextStyle(color: c.sub, fontSize: 13, fontFeatures: const [FontFeature.tabularFigures()])),
        ?trailingWidget,
       ],
      ),
     );

/// Small outlined pill used for neutral status ("บัญชีหลัก", "VIP", "เปิดอยู่").
Widget _pill(_C c, String text, {Color? color, Color? border}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: border ?? c.line)),
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color ?? c.sub)),
     );

/// Toggle switch in the accent colour.
Widget _calmSwitch(_C c, bool value, ValueChanged<bool>? onChanged) => Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: c.accent,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: c.dark ? Colors.white24 : const Color(0xFFCBD5E1),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
     );

/// Label above an input: 13/600, optional grey suffix like "(ไม่บังคับ)".
Widget _fieldLabel(_C c, String label, {String? hint}) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(TextSpan(children: [
       TextSpan(text: label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text)),
       if (hint != null) TextSpan(text: ' $hint', style: TextStyle(fontSize: 13, color: c.sub)),
      ])),
     );

InputDecoration _inputDeco(_C c, {String? hint, String? prefix, bool error = false, Widget? prefixIcon, Widget? suffixIcon}) {
 OutlineInputBorder b(Color col, [double w = 1]) => OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: col, width: w));
 return InputDecoration(
  isDense: true,
  hintText: hint,
  hintStyle: TextStyle(color: c.sub.withValues(alpha: 0.8), fontSize: 14.5, fontWeight: FontWeight.w400),
  // Shown as an icon so the prefix (e.g. ฿) stays visible while the field is empty.
  prefixIcon: prefixIcon ??
    (prefix == null
      ? null
      : Padding(
        padding: const EdgeInsets.only(left: 14, right: 8),
        child: Text(prefix.trim(), style: TextStyle(color: c.sub, fontSize: 16, fontWeight: FontWeight.w600)),
       )),
  prefixIconConstraints: prefix != null && prefixIcon == null ? const BoxConstraints(minWidth: 0, minHeight: 0) : null,
  suffixIcon: suffixIcon,
  filled: true,
  fillColor: c.card,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  enabledBorder: b(error ? c.danger : c.line),
  focusedBorder: b(error ? c.danger : c.accent, 1.5),
  border: b(c.line),
 );
}

/// Bottom sheet frame: grab handle, 18/700 title, optional subtitle, close button.
Future<T?> _showCalmSheet<T>(BuildContext context, _C c, {required String title, String? subtitle, required Widget Function(BuildContext ctx, StateSetter setSheet) builder}) {
 return showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  backgroundColor: c.card,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
  builder: (ctx) => StatefulBuilder(
   builder: (ctx, setSheet) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
    child: SafeArea(
     top: false,
     child: ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.9),
      child: SingleChildScrollView(
       padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
       child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
         Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: c.line, borderRadius: BorderRadius.circular(2)))),
         const SizedBox(height: 10),
         Row(
          children: [
           Expanded(
            child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.text)),
              if (subtitle != null) Text(subtitle, style: TextStyle(fontSize: 12.5, color: c.sub)),
             ],
            ),
           ),
           SizedBox(
            width: 44,
            height: 44,
            child: IconButton(tooltip: 'ปิด', icon: Icon(Icons.close_rounded, size: 22, color: c.sub), onPressed: () => Navigator.pop(ctx)),
           ),
          ],
         ),
         const SizedBox(height: 12),
         builder(ctx, setSheet),
        ],
       ),
      ),
     ),
    ),
   ),
  ),
 );
}

/// Centred confirm dialog: red line icon, title, body, optional quoted note, cancel + action.
Future<bool> _confirmDialog(BuildContext context, _C c,
  {required String title, required String body, String? note, required String confirmLabel, IconData icon = Icons.delete_outline_rounded, bool danger = true}) async {
 final r = await showDialog<bool>(
  context: context,
  builder: (ctx) => Dialog(
   backgroundColor: c.card,
   insetPadding: const EdgeInsets.symmetric(horizontal: 24),
   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
   child: Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
    child: Column(
     mainAxisSize: MainAxisSize.min,
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
      Icon(icon, size: 26, color: danger ? c.danger : c.icon),
      const SizedBox(height: 10),
      Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.text)),
      const SizedBox(height: 6),
      Text(body, style: TextStyle(fontSize: 13.5, height: 1.5, color: c.sub)),
      if (note != null && note.isNotEmpty) ...[
       const SizedBox(height: 10),
       Container(
        padding: const EdgeInsets.only(left: 10),
        decoration: BoxDecoration(border: Border(left: BorderSide(color: c.line, width: 3))),
        child: Text(note, style: TextStyle(fontSize: 13, height: 1.45, color: c.sub)),
       ),
      ],
      const SizedBox(height: 18),
      Row(
       children: [
        Expanded(child: _outlineButton(c, 'ยกเลิก', () => Navigator.pop(ctx, false))),
        const SizedBox(width: 10),
        Expanded(
         child: SizedBox(
          height: 48,
          child: ElevatedButton(
           onPressed: () => Navigator.pop(ctx, true),
           style: ElevatedButton.styleFrom(
            backgroundColor: danger ? c.danger : c.accent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
           ),
           child: Text(confirmLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
         ),
        ),
       ],
      ),
     ],
    ),
   ),
  ),
 );
 return r ?? false;
}

/// Dark floating toast with an optional action (e.g. เลิกทำ).
void _calmToast(BuildContext context, String msg, {bool error = false, String? actionLabel, VoidCallback? onAction}) {
 final m = ScaffoldMessenger.of(context);
 m.hideCurrentSnackBar();
 m.showSnackBar(SnackBar(
  content: Text(msg, style: const TextStyle(fontSize: 13.5, color: Colors.white)),
  behavior: SnackBarBehavior.floating,
  backgroundColor: error ? const Color(0xFFB91C1C) : const Color(0xFF0F172A),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  duration: Duration(seconds: actionLabel != null ? 5 : 3),
  action: actionLabel == null ? null : SnackBarAction(label: actionLabel, textColor: const Color(0xFF93C5FD), onPressed: onAction ?? () {}),
 ));
}
