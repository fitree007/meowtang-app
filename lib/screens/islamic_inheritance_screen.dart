import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/expense_controller.dart';
import '../theme/meow_theme.dart';
import '../utils/format_utils.dart';

enum DeceasedGender { male, female }

class HeirCalculationResult {
  final String title;
  final String titleEn;
  final int count;
  final String shareFraction;
  final double percentage;
  final double totalAmount;
  final double perPersonAmount;
  final String explanationTh;
  final String explanationEn;

  HeirCalculationResult({
    required this.title,
    required this.titleEn,
    required this.count,
    required this.shareFraction,
    required this.percentage,
    required this.totalAmount,
    required this.perPersonAmount,
    required this.explanationTh,
    required this.explanationEn,
  });
}

class IslamicInheritanceScreen extends StatefulWidget {
  final ExpenseController controller;

  const IslamicInheritanceScreen({super.key, required this.controller});

  @override
  State<IslamicInheritanceScreen> createState() => _IslamicInheritanceScreenState();
}

class _IslamicInheritanceScreenState extends State<IslamicInheritanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _mainTabController;

  // 1. Estate Assets
  final TextEditingController _grossEstateCtrl = TextEditingController(text: '1000000');
  bool _showDetailedAssetBreakdown = false;
  final TextEditingController _landAssetCtrl = TextEditingController();
  final TextEditingController _depositAssetCtrl = TextEditingController();
  final TextEditingController _carAssetCtrl = TextEditingController();
  final TextEditingController _houseAssetCtrl = TextEditingController();
  final TextEditingController _valuableAssetCtrl = TextEditingController();
  final TextEditingController _otherAssetCtrl = TextEditingController();

  // 2. Estate Obligations (สิทธิผูกพันก่อนแบ่งมรดก)
  final TextEditingController _funeralCostCtrl = TextEditingController();
  final TextEditingController _debtsCtrl = TextEditingController();
  final TextEditingController _wasiyyahCtrl = TextEditingController();

  // 3. Deceased Profile & Heirs
  DeceasedGender _gender = DeceasedGender.male;
  int _wifeCount = 1; // 0..4 (if deceased is male)
  bool _hasHusband = true; // (if deceased is female)
  bool _hasFather = true;
  bool _hasMother = true;
  bool _hasGrandfather = false;
  bool _hasGrandmother = false;
  int _sonCount = 1;
  int _daughterCount = 1;
  int _grandsonCount = 0;
  int _granddaughterFromSonCount = 0;
  int _brotherFullCount = 0;
  int _sisterFullCount = 0;
  int _brotherPaternalCount = 0;
  int _sisterPaternalCount = 0;
  int _maternalSiblingsCount = 0;
  int _uncleCount = 0;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _grossEstateCtrl.dispose();
    _landAssetCtrl.dispose();
    _depositAssetCtrl.dispose();
    _carAssetCtrl.dispose();
    _houseAssetCtrl.dispose();
    _valuableAssetCtrl.dispose();
    _otherAssetCtrl.dispose();
    _funeralCostCtrl.dispose();
    _debtsCtrl.dispose();
    _wasiyyahCtrl.dispose();
    super.dispose();
  }

  double _parse(TextEditingController c) {
    final text = c.text.replaceAll(',', '').trim();
    return double.tryParse(text) ?? 0.0;
  }

  double get _grossEstate {
    if (_showDetailedAssetBreakdown) {
      return _parse(_landAssetCtrl) +
          _parse(_depositAssetCtrl) +
          _parse(_carAssetCtrl) +
          _parse(_houseAssetCtrl) +
          _parse(_valuableAssetCtrl) +
          _parse(_otherAssetCtrl);
    }
    return _parse(_grossEstateCtrl);
  }

  double get _funeralCost => _parse(_funeralCostCtrl);
  double get _debts => _parse(_debtsCtrl);
  double get _wasiyyahInput => _parse(_wasiyyahCtrl);

  double get _netBeforeWasiyyah => (_grossEstate - _funeralCost - _debts).clamp(0.0, double.infinity);
  double get _maxWasiyyahAllowed => _netBeforeWasiyyah / 3.0;
  bool get _isWasiyyahOverLimit => _wasiyyahInput > _maxWasiyyahAllowed && _maxWasiyyahAllowed > 0;
  double get _actualWasiyyah => _wasiyyahInput > _maxWasiyyahAllowed ? _maxWasiyyahAllowed : _wasiyyahInput;
  double get _netEstate => (_netBeforeWasiyyah - _actualWasiyyah).clamp(0.0, double.infinity);

  void _importAppBalance() {
    HapticFeedback.mediumImpact();
    final netWorth = widget.controller.totalNetWorth;
    setState(() {
      _grossEstateCtrl.text = netWorth > 0 ? netWorth.toStringAsFixed(0) : '0';
      _depositAssetCtrl.text = netWorth > 0 ? netWorth.toStringAsFixed(0) : '0';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ดึงยอดเงินคงเหลือจากแอพ ฿${FormatUtils.formatCurrency(netWorth)} เรียบร้อย!'),
        backgroundColor: MeowTheme.incomeGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _resetForm() {
    HapticFeedback.lightImpact();
    setState(() {
      _grossEstateCtrl.text = '1000000';
      _landAssetCtrl.clear();
      _depositAssetCtrl.clear();
      _carAssetCtrl.clear();
      _houseAssetCtrl.clear();
      _valuableAssetCtrl.clear();
      _otherAssetCtrl.clear();
      _funeralCostCtrl.clear();
      _debtsCtrl.clear();
      _wasiyyahCtrl.clear();
      _gender = DeceasedGender.male;
      _wifeCount = 1;
      _hasHusband = true;
      _hasFather = true;
      _hasMother = true;
      _hasGrandfather = false;
      _hasGrandmother = false;
      _sonCount = 1;
      _daughterCount = 1;
      _grandsonCount = 0;
      _granddaughterFromSonCount = 0;
      _brotherFullCount = 0;
      _sisterFullCount = 0;
      _brotherPaternalCount = 0;
      _sisterPaternalCount = 0;
      _maternalSiblingsCount = 0;
      _uncleCount = 0;
    });
  }

  void _loadPresetCase(int caseIndex) {
    _resetForm();
    _grossEstateCtrl.text = '1200000'; // 1.2M THB
    _showDetailedAssetBreakdown = false;

    setState(() {
      switch (caseIndex) {
        case 1: // Munasikhat (มรดกซ้อน)
          _gender = DeceasedGender.male;
          _wifeCount = 1;
          _sonCount = 2;
          _daughterCount = 1;
          _hasFather = false;
          _hasMother = false;
          break;
        case 2: // Al-Gharawayn (คดีท่านอุมัร: สามี/ภรรยา + แม่ + พ่อ)
          _gender = DeceasedGender.male;
          _wifeCount = 1;
          _hasMother = true;
          _hasFather = true;
          _sonCount = 0;
          _daughterCount = 0;
          break;
        case 3: // Al-Mushtarakah (คดีหินทิ้งทะเล: สามี + แม่ + พี่น้องแม่ + พี่น้องแท้)
          _gender = DeceasedGender.female;
          _hasHusband = true;
          _hasMother = true;
          _maternalSiblingsCount = 2;
          _brotherFullCount = 2;
          _sonCount = 0;
          _daughterCount = 0;
          _hasFather = false;
          break;
        case 4: // Al-Akdariyyah (ปู่ + พี่สาวแท้)
          _gender = DeceasedGender.female;
          _hasHusband = true;
          _hasMother = true;
          _hasGrandfather = true;
          _sisterFullCount = 1;
          _sonCount = 0;
          _daughterCount = 0;
          _hasFather = false;
          break;
        case 5: // Al-Hamal (ทารกในครรภ์)
          _gender = DeceasedGender.male;
          _wifeCount = 1;
          _hasFather = true;
          _hasMother = true;
          _sonCount = 0;
          _daughterCount = 0;
          break;
        case 6: // อุบัติเหตุเสียชีวิตพร้อมกัน
          _gender = DeceasedGender.male;
          _wifeCount = 0;
          _hasFather = true;
          _hasMother = true;
          _sonCount = 1;
          _daughterCount = 0;
          break;
        case 7: // คนหายสาบสูญ
          _gender = DeceasedGender.male;
          _wifeCount = 1;
          _sonCount = 2;
          _daughterCount = 1;
          break;
      }
    });

    _mainTabController.animateTo(0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('จำลองสถานการณ์และกรอกข้อมูลเข้าเครื่องคำนวณเรียบร้อย!'),
        backgroundColor: MeowTheme.incomeGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Faraid Calculation Engine (Sunni Consensus - Shafi'i, Hanafi, Maliki, Hanbali)
  List<HeirCalculationResult> _calculateFaraid() {
    final results = <HeirCalculationResult>[];
    final estate = _netEstate;
    if (estate <= 0) return results;

    final hasChildren = (_sonCount + _daughterCount + _grandsonCount + _granddaughterFromSonCount) > 0;
    final totalSiblings = _brotherFullCount + _sisterFullCount + _brotherPaternalCount + _sisterPaternalCount + _maternalSiblingsCount;

    // 1. Spouses Share
    double spouseShareFraction = 0.0;
    String spouseFractionStr = '0';
    String spouseExplainTh = '';

    if (_gender == DeceasedGender.male && _wifeCount > 0) {
      if (hasChildren) {
        spouseShareFraction = 1.0 / 8.0;
        spouseFractionStr = '1/8';
        spouseExplainTh = 'ภรรยาได้ 1/8 เนื่องจากผู้ตายมีบุตร/หลาน (แบ่งเท่ากัน $_wifeCount คน)';
      } else {
        spouseShareFraction = 1.0 / 4.0;
        spouseFractionStr = '1/4';
        spouseExplainTh = 'ภรรยาได้ 1/4 เนื่องจากผู้ตายไม่มีบุตร/หลาน (แบ่งเท่ากัน $_wifeCount คน)';
      }
      final totalAmount = estate * spouseShareFraction;
      results.add(HeirCalculationResult(
        title: 'ภรรยา',
        titleEn: 'Wife / Wives',
        count: _wifeCount,
        shareFraction: spouseFractionStr,
        percentage: spouseShareFraction * 100,
        totalAmount: totalAmount,
        perPersonAmount: totalAmount / _wifeCount,
        explanationTh: spouseExplainTh,
        explanationEn: 'Wife/wives fixed share',
      ));
    } else if (_gender == DeceasedGender.female && _hasHusband) {
      if (hasChildren) {
        spouseShareFraction = 1.0 / 4.0;
        spouseFractionStr = '1/4';
        spouseExplainTh = 'สามีได้ 1/4 เนื่องจากผู้ตายมีบุตร/หลาน';
      } else {
        spouseShareFraction = 1.0 / 2.0;
        spouseFractionStr = '1/2';
        spouseExplainTh = 'สามีได้ 1/2 เนื่องจากผู้ตายไม่มีบุตร/หลาน';
      }
      final totalAmount = estate * spouseShareFraction;
      results.add(HeirCalculationResult(
        title: 'สามี',
        titleEn: 'Husband',
        count: 1,
        shareFraction: spouseFractionStr,
        percentage: spouseShareFraction * 100,
        totalAmount: totalAmount,
        perPersonAmount: totalAmount,
        explanationTh: spouseExplainTh,
        explanationEn: 'Husband fixed share',
      ));
    }

    // 2. Mother Share (Check Al-Gharawayn case: Spouse + Mother + Father only)
    double motherShareFraction = 0.0;
    if (_hasMother) {
      final isGharawayn = !hasChildren && totalSiblings < 2 && _hasFather && ((_gender == DeceasedGender.male && _wifeCount > 0) || (_gender == DeceasedGender.female && _hasHusband));

      if (isGharawayn) {
        final remainingAfterSpouse = 1.0 - spouseShareFraction;
        motherShareFraction = remainingAfterSpouse * (1.0 / 3.0);
        final totalAmount = estate * motherShareFraction;
        results.add(HeirCalculationResult(
          title: 'มารดา (แม่)',
          titleEn: 'Mother',
          count: 1,
          shareFraction: '1/3 ของส่วนเหลือ',
          percentage: motherShareFraction * 100,
          totalAmount: totalAmount,
          perPersonAmount: totalAmount,
          explanationTh: 'มารดาได้ 1/3 ของส่วนที่เหลือหลังหักคู่สมรส (คดีอัลเฆาะรอวียะฮ์ เพื่อรักษาอัตรา 2:1 กับบิดา)',
          explanationEn: 'Mother gets 1/3 of remainder',
        ));
      } else if (hasChildren || totalSiblings >= 2) {
        motherShareFraction = 1.0 / 6.0;
        results.add(HeirCalculationResult(
          title: 'มารดา (แม่)',
          titleEn: 'Mother',
          count: 1,
          shareFraction: '1/6',
          percentage: (1.0 / 6.0) * 100,
          totalAmount: estate * (1.0 / 6.0),
          perPersonAmount: estate * (1.0 / 6.0),
          explanationTh: 'มารดาได้ 1/6 เนื่องจากมีบุตร/หลาน หรือมีพี่น้องตั้งแต่ 2 คนขึ้นไป',
          explanationEn: 'Mother receives 1/6',
        ));
      } else {
        motherShareFraction = 1.0 / 3.0;
        results.add(HeirCalculationResult(
          title: 'มารดา (แม่)',
          titleEn: 'Mother',
          count: 1,
          shareFraction: '1/3',
          percentage: (1.0 / 3.0) * 100,
          totalAmount: estate * (1.0 / 3.0),
          perPersonAmount: estate * (1.0 / 3.0),
          explanationTh: 'มารดาได้ 1/3 เนื่องจากไม่มีบุตรและไม่มีพี่น้องหลายคน',
          explanationEn: 'Mother receives 1/3',
        ));
      }
    }

    // 3. Father Share
    double fatherShareFraction = 0.0;
    if (_hasFather) {
      if (_sonCount > 0 || _grandsonCount > 0) {
        fatherShareFraction = 1.0 / 6.0;
        results.add(HeirCalculationResult(
          title: 'บิดา (พ่อ)',
          titleEn: 'Father',
          count: 1,
          shareFraction: '1/6 (ฟุรูฎ)',
          percentage: (1.0 / 6.0) * 100,
          totalAmount: estate * (1.0 / 6.0),
          perPersonAmount: estate * (1.0 / 6.0),
          explanationTh: 'บิดาได้ 1/6 ตายตัวเนื่องจากผู้ตายมีบุตรชายหรือหลานชายสายตรง',
          explanationEn: 'Father receives 1/6',
        ));
      } else if (_daughterCount > 0 || _granddaughterFromSonCount > 0) {
        fatherShareFraction = 1.0 / 6.0;
      }
    }

    // 4. Daughters Share (if no sons)
    double daughtersShareFraction = 0.0;
    if (_sonCount == 0 && _daughterCount > 0) {
      if (_daughterCount == 1) {
        daughtersShareFraction = 1.0 / 2.0;
        results.add(HeirCalculationResult(
          title: 'บุตรสาว (ลูกสาว)',
          titleEn: 'Daughter (1 person)',
          count: 1,
          shareFraction: '1/2 (ครึ่งหนึ่ง)',
          percentage: 50.0,
          totalAmount: estate * 0.5,
          perPersonAmount: estate * 0.5,
          explanationTh: 'บุตรสาวคนเดียว (ไม่มีบุตรชาย) ได้ 1/2 ของกองมรดก',
          explanationEn: 'Single daughter gets 1/2',
        ));
      } else {
        daughtersShareFraction = 2.0 / 3.0;
        final totalDaughterAmount = estate * (2.0 / 3.0);
        results.add(HeirCalculationResult(
          title: 'บุตรสาว (ลูกสาว)',
          titleEn: 'Daughters (${_daughterCount} persons)',
          count: _daughterCount,
          shareFraction: '2/3',
          percentage: (2.0 / 3.0) * 100,
          totalAmount: totalDaughterAmount,
          perPersonAmount: totalDaughterAmount / _daughterCount,
          explanationTh: 'บุตรสาวตั้งแต่ 2 คนขึ้นไป ได้ส่วนแบ่ง 2/3 หารเท่ากันทุกคน',
          explanationEn: 'Daughters share 2/3 equally',
        ));
      }
    }

    // 5. Maternal Siblings (Only in Kalalah)
    double maternalShareFraction = 0.0;
    if (_maternalSiblingsCount > 0 && !hasChildren && !_hasFather && !_hasGrandfather) {
      maternalShareFraction = _maternalSiblingsCount == 1 ? (1.0 / 6.0) : (1.0 / 3.0);
      final totalMaternalAmount = estate * maternalShareFraction;
      results.add(HeirCalculationResult(
        title: 'พี่น้องร่วมมารดา (ต่างพ่อ)',
        titleEn: 'Maternal Siblings',
        count: _maternalSiblingsCount,
        shareFraction: _maternalSiblingsCount == 1 ? '1/6' : '1/3',
        percentage: maternalShareFraction * 100,
        totalAmount: totalMaternalAmount,
        perPersonAmount: totalMaternalAmount / _maternalSiblingsCount,
        explanationTh: 'พี่น้องร่วมมารดา (กะลาละฮ์) แบ่งส่วนเท่ากันระหว่างชายและหญิง',
        explanationEn: 'Maternal siblings share equally',
      ));
    }

    // 6. Calculate Remainder (Asabah - อัศเศาะบะฮ์)
    final allocatedShares = spouseShareFraction + motherShareFraction + fatherShareFraction + daughtersShareFraction + maternalShareFraction;
    final remainingFraction = (1.0 - allocatedShares).clamp(0.0, 1.0);
    final remainingAmount = estate * remainingFraction;

    if (remainingAmount > 0) {
      if (_sonCount > 0) {
        final totalChildShares = (_sonCount * 2) + _daughterCount;
        final oneShareAmount = remainingAmount / totalChildShares;

        final totalSonAmount = oneShareAmount * 2 * _sonCount;
        final perSonAmount = oneShareAmount * 2;
        results.add(HeirCalculationResult(
          title: 'บุตรชาย (ลูกชาย)',
          titleEn: 'Sons (${_sonCount} persons)',
          count: _sonCount,
          shareFraction: 'อาศอบะฮ์ (2 ส่วน)',
          percentage: (totalSonAmount / estate) * 100,
          totalAmount: totalSonAmount,
          perPersonAmount: perSonAmount,
          explanationTh: 'บุตรชายรับส่วนที่เหลือ (อาศอบะฮ์) ในอัตรา ชาย 2 ส่วน : หญิง 1 ส่วน',
          explanationEn: 'Sons take residuary 2:1',
        ));

        if (_daughterCount > 0) {
          final totalDaughterAmount = oneShareAmount * _daughterCount;
          final perDaughterAmount = oneShareAmount;
          results.add(HeirCalculationResult(
            title: 'บุตรสาว (ลูกสาว)',
            titleEn: 'Daughters (${_daughterCount} persons)',
            count: _daughterCount,
            shareFraction: 'อาศอบะฮ์ (1 ส่วน)',
            percentage: (totalDaughterAmount / estate) * 100,
            totalAmount: totalDaughterAmount,
            perPersonAmount: perDaughterAmount,
            explanationTh: 'บุตรสาวรับส่วนที่เหลือร่วมกับบุตรชายในอัตรา 1 ส่วน',
            explanationEn: 'Daughters take residuary 1 part',
          ));
        }
      } else if (_hasFather) {
        final totalFatherAmount = (estate * fatherShareFraction) + remainingAmount;
        results.add(HeirCalculationResult(
          title: 'บิดา (พ่อ)',
          titleEn: 'Father',
          count: 1,
          shareFraction: fatherShareFraction > 0 ? '1/6 + ส่วนเหลือ' : 'อาศอบะฮ์ (ส่วนเหลือทั้งหมด)',
          percentage: (totalFatherAmount / estate) * 100,
          totalAmount: totalFatherAmount,
          perPersonAmount: totalFatherAmount,
          explanationTh: 'บิดารับส่วนเหลือทั้งหมดในฐานะทายาทชายสายตรง',
          explanationEn: 'Father receives all remainder',
        ));
      } else if (_hasGrandfather) {
        results.add(HeirCalculationResult(
          title: 'ปู่ (สายพ่อ)',
          titleEn: 'Grandfather',
          count: 1,
          shareFraction: 'อาศอบะฮ์ (ส่วนเหลือ)',
          percentage: remainingFraction * 100,
          totalAmount: remainingAmount,
          perPersonAmount: remainingAmount,
          explanationTh: 'ปู่รับส่วนเหลือแทนบิดาเมื่อไม่มีบิดา',
          explanationEn: 'Grandfather takes remainder',
        ));
      } else if (_brotherFullCount > 0) {
        final totalSibShares = (_brotherFullCount * 2) + _sisterFullCount;
        final oneShare = remainingAmount / totalSibShares;
        final totalBroAmount = oneShare * 2 * _brotherFullCount;

        results.add(HeirCalculationResult(
          title: 'พี่น้องชายแท้ (พ่อแม่เดียวกัน)',
          titleEn: 'Full Brothers',
          count: _brotherFullCount,
          shareFraction: 'อาศอบะฮ์ (2 ส่วน)',
          percentage: (totalBroAmount / estate) * 100,
          totalAmount: totalBroAmount,
          perPersonAmount: totalBroAmount / _brotherFullCount,
          explanationTh: 'พี่น้องชายแท้รับส่วนเหลือในอัตรา ชาย 2 ส่วน : หญิง 1 ส่วน',
          explanationEn: 'Full brothers take residuary 2:1',
        ));

        if (_sisterFullCount > 0) {
          final totalSisAmount = oneShare * _sisterFullCount;
          results.add(HeirCalculationResult(
            title: 'พี่น้องหญิงแท้ (พ่อแม่เดียวกัน)',
            titleEn: 'Full Sisters',
            count: _sisterFullCount,
            shareFraction: 'อาศอบะฮ์ (1 ส่วน)',
            percentage: (totalSisAmount / estate) * 100,
            totalAmount: totalSisAmount,
            perPersonAmount: totalSisAmount / _sisterFullCount,
            explanationTh: 'พี่น้องหญิงแท้รับส่วนเหลือร่วมกับพี่น้องชายแท้ (1 ส่วน)',
            explanationEn: 'Full sisters take residuary jointly',
          ));
        }
      } else if (_uncleCount > 0) {
        results.add(HeirCalculationResult(
          title: 'ลุง / อา (สายพ่อ)',
          titleEn: 'Paternal Uncle',
          count: _uncleCount,
          shareFraction: 'อาศอบะฮ์ (ส่วนเหลือ)',
          percentage: remainingFraction * 100,
          totalAmount: remainingAmount,
          perPersonAmount: remainingAmount / _uncleCount,
          explanationTh: 'ลุง/อารับส่วนเหลือในฐานะญาติผู้ชายสายบิดา',
          explanationEn: 'Uncles take residuary',
        ));
      }
    }

    return results;
  }

  List<String> _getBlockedHeirsList() {
    final blocked = <String>[];
    if (_sonCount > 0) {
      blocked.add('พี่น้องทุกประเภท (ถูกบุตรชายกันสิทธิ์ - Hajb)');
      blocked.add('หลานทุกประเภท (ถูกบุตรชายกันสิทธิ์)');
      blocked.add('ลุง/อา (ถูกบุตรชายกันสิทธิ์)');
    }
    if (_hasFather) {
      blocked.add('ปู่ (ถูกบิดากันสิทธิ์)');
      blocked.add('พี่น้องร่วมมารดา (ถูกบิดากันสิทธิ์)');
    }
    if (_hasMother) {
      blocked.add('ย่า / ยาย (ถูกมารดากันสิทธิ์)');
    }
    if (_brotherFullCount > 0 && (_brotherPaternalCount > 0 || _sisterPaternalCount > 0)) {
      blocked.add('พี่น้องร่วมบิดา (ถูกพี่น้องแท้กันสิทธิ์)');
    }
    return blocked;
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = widget.controller.currentTheme;
    final isDark = widget.controller.isDarkMode;
    final isEn = widget.controller.isEnglish;

    return Scaffold(
      backgroundColor: currentTheme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: currentTheme.textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEn ? 'Islamic Inheritance (Faraid)' : 'แบ่งมรดกอิสลาม (ฟะรออิฎ)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: currentTheme.textColor),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _mainTabController,
          indicatorColor: MeowTheme.mustardYellow,
          indicatorWeight: 3,
          labelColor: MeowTheme.mustardYellow,
          unselectedLabelColor: currentTheme.textSecondaryColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.calculate_rounded, size: 18), text: 'เครื่องคำนวณ'),
            Tab(icon: Icon(Icons.auto_stories_rounded, size: 18), text: '7 กรณีศึกษา'),
            Tab(icon: Icon(Icons.menu_book_rounded, size: 18), text: 'ความรู้เบื้องต้น'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [
          // Tab 1: Faraid Calculator
          _buildCalculatorTab(currentTheme, isDark, isEn),
          // Tab 2: 7 Visual Case Studies
          _buildComplexCasesTab(currentTheme, isDark, isEn),
          // Tab 3: Faraid Knowledge & Engine Guide
          _buildKnowledgeGuideTab(currentTheme, isDark, isEn),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: FARAID CALCULATOR (Clean & Intuitive)
  // ==========================================
  Widget _buildCalculatorTab(dynamic currentTheme, bool isDark, bool isEn) {
    final results = _calculateFaraid();
    final blockedList = _getBlockedHeirsList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step 1: Estate & Rights Card
          _buildEstateCard(currentTheme, isDark, isEn),
          const SizedBox(height: 14),

          // Step 2: Family Heirs Card
          _buildHeirsCard(currentTheme, isDark, isEn),
          const SizedBox(height: 16),

          // Step 3: Faraid Result Summary Card
          _buildReportSummaryCard(results, blockedList, currentTheme, isDark, isEn),
        ],
      ),
    );
  }

  Widget _buildEstateCard(dynamic currentTheme, bool isDark, bool isEn) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: currentTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: currentTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded, color: currentTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '1. ทรัพย์สินและภาระผูกพัน',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                ),
              ),
              GestureDetector(
                onTap: _importAppBalance,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: currentTheme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download_rounded, size: 14, color: currentTheme.primaryColor),
                      const SizedBox(width: 4),
                      Text('ดึงยอดในแอพ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: currentTheme.primaryColor)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (!_showDetailedAssetBreakdown) ...[
            _buildSimpleInput(
              _grossEstateCtrl,
              'มูลค่าทรัพย์สินทั้งหมดของผู้เสียชีวิต (บาท)',
              '1,000,000',
              currentTheme,
            ),
          ] else ...[
            Row(
              children: [
                Expanded(child: _buildSimpleInput(_landAssetCtrl, '🏞️ ที่ดิน (บาท)', '0', currentTheme)),
                const SizedBox(width: 10),
                Expanded(child: _buildSimpleInput(_depositAssetCtrl, '🏦 เงินฝาก (บาท)', '0', currentTheme)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildSimpleInput(_houseAssetCtrl, '🏠 บ้าน (บาท)', '0', currentTheme)),
                const SizedBox(width: 10),
                Expanded(child: _buildSimpleInput(_carAssetCtrl, '🚗 รถยนต์ (บาท)', '0', currentTheme)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildSimpleInput(_valuableAssetCtrl, '💎 ทองคำ (บาท)', '0', currentTheme)),
                const SizedBox(width: 10),
                Expanded(child: _buildSimpleInput(_otherAssetCtrl, '📦 อื่นๆ (บาท)', '0', currentTheme)),
              ],
            ),
          ],

          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() => _showDetailedAssetBreakdown = !_showDetailedAssetBreakdown),
              icon: Icon(_showDetailedAssetBreakdown ? Icons.keyboard_arrow_up_rounded : Icons.tune_rounded, size: 16),
              label: Text(
                _showDetailedAssetBreakdown ? 'กรอกยอดรวมอย่างเดียว' : 'แยกกรอกตามประเภททรัพย์สิน (ที่ดิน, บ้าน, ทอง)',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Divider(height: 14),

          Text(
            'หักค่าใช้จ่ายก่อนแบ่งมรดก (ตามลำดับศาสนา):',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: currentTheme.textSecondaryColor),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(child: _buildSimpleInput(_funeralCostCtrl, '⚰️ ค่าทำศพ (บาท)', '0', currentTheme)),
              const SizedBox(width: 10),
              Expanded(child: _buildSimpleInput(_debtsCtrl, '💳 หนี้สิน (บาท)', '0', currentTheme)),
            ],
          ),
          const SizedBox(height: 8),

          _buildSimpleInput(
            _wasiyyahCtrl,
            '📜 พินัยกรรม (ไม่เกิน 1/3 ของยอดสุทธิหลังหักหนี้)',
            '0',
            currentTheme,
          ),

          if (_isWasiyyahOverLimit)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF87171)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFDC2626)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'พินัยกรรมเกิน 1/3 ศาสนาอนุญาตให้จ่ายได้สูงสุด ฿${FormatUtils.formatCurrency(_maxWasiyyahAllowed)}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFFB91C1C), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: currentTheme.surfaceBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: currentTheme.borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text('ยอดมรดกสุทธิที่จะนำมาแบ่ง (ตะริกะฮฺ):', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
                ),
                Text('฿${FormatUtils.formatCurrency(_netEstate)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeirsCard(dynamic currentTheme, bool isDark, bool isEn) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: currentTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: currentTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.family_restroom_rounded, color: currentTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '2. ทายาทที่มีชีวิตอยู่ (Family Heirs)',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                tooltip: 'รีเซ็ตทายาท',
                onPressed: _resetForm,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Deceased Gender Segment
          Row(
            children: [
              Text('เพศผู้เสียชีวิต:', style: TextStyle(fontSize: 12.5, color: currentTheme.textSecondaryColor)),
              const SizedBox(width: 10),
              ChoiceChip(
                label: const Text('👨 ผู้ชาย', style: TextStyle(fontSize: 12)),
                selected: _gender == DeceasedGender.male,
                onSelected: (v) => setState(() => _gender = DeceasedGender.male),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: const Text('👩 ผู้หญิง', style: TextStyle(fontSize: 12)),
                selected: _gender == DeceasedGender.female,
                onSelected: (v) => setState(() => _gender = DeceasedGender.female),
              ),
            ],
          ),
          const Divider(height: 18),

          // Spouse
          if (_gender == DeceasedGender.male)
            _buildCounterRow('ภรรยาที่มีชีวิตอยู่', _wifeCount, 0, 4, (v) => setState(() => _wifeCount = v), currentTheme)
          else
            Row(
              children: [
                Expanded(
                  child: Text('สามียังมีชีวิตอยู่', style: TextStyle(fontSize: 13, color: currentTheme.textColor)),
                ),
                Switch(
                  value: _hasHusband,
                  activeColor: currentTheme.primaryColor,
                  onChanged: (v) => setState(() => _hasHusband = v),
                ),
              ],
            ),
          const Divider(height: 14),

          // Parents
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('บิดา (พ่อ)', style: TextStyle(fontSize: 13, color: currentTheme.textColor)),
                  value: _hasFather,
                  activeColor: currentTheme.primaryColor,
                  onChanged: (v) => setState(() => _hasFather = v ?? false),
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('มารดา (แม่)', style: TextStyle(fontSize: 13, color: currentTheme.textColor)),
                  value: _hasMother,
                  activeColor: currentTheme.primaryColor,
                  onChanged: (v) => setState(() => _hasMother = v ?? false),
                ),
              ),
            ],
          ),
          const Divider(height: 14),

          // Children
          _buildCounterRow('บุตรชาย (ลูกชาย)', _sonCount, 0, 15, (v) => setState(() => _sonCount = v), currentTheme),
          _buildCounterRow('บุตรสาว (ลูกสาว)', _daughterCount, 0, 15, (v) => setState(() => _daughterCount = v), currentTheme),
          const Divider(height: 14),

          // Additional Extended Relatives
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              '➕ เพิ่มญาติลำดับถัดไป (ปู่, พี่น้อง, ลุง/อา)',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: currentTheme.primaryColor),
            ),
            children: [
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('ปู่ (สายบิดา)', style: TextStyle(fontSize: 12.5, color: currentTheme.textColor)),
                value: _hasGrandfather,
                activeColor: currentTheme.primaryColor,
                onChanged: (v) => setState(() => _hasGrandfather = v ?? false),
              ),
              _buildCounterRow('พี่น้องชายแท้ (พ่อแม่เดียวกัน)', _brotherFullCount, 0, 10, (v) => setState(() => _brotherFullCount = v), currentTheme),
              _buildCounterRow('พี่น้องหญิงแท้ (พ่อแม่เดียวกัน)', _sisterFullCount, 0, 10, (v) => setState(() => _sisterFullCount = v), currentTheme),
              _buildCounterRow('พี่น้องร่วมมารดา (ต่างพ่อ)', _maternalSiblingsCount, 0, 10, (v) => setState(() => _maternalSiblingsCount = v), currentTheme),
              _buildCounterRow('ลุง / อา (สายพ่อ)', _uncleCount, 0, 10, (v) => setState(() => _uncleCount = v), currentTheme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportSummaryCard(List<HeirCalculationResult> results, List<String> blockedList, dynamic currentTheme, bool isDark, bool isEn) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: currentTheme.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: currentTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
              Icon(Icons.receipt_long_rounded, color: currentTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '3. สรุปผลการแบ่งมรดก (Faraid Report)',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                ),
              ),
            ],
          ),
          const Divider(height: 18),

          if (results.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('ระบุยอดสินทรัพย์และทายาทเพื่อแสดงผลการคำนวณ', style: TextStyle(fontSize: 12.5, color: currentTheme.textSecondaryColor)),
              ),
            )
          else ...[
            ...results.map((r) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: currentTheme.surfaceBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: currentTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${r.title} (${r.count} คน)',
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                            ),
                          ),
                          Text(
                            '฿${FormatUtils.formatCurrency(r.totalAmount)}',
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: currentTheme.primaryColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text('สิทธิ์: ${r.shareFraction} (${r.percentage.toStringAsFixed(1)}%)', style: TextStyle(fontSize: 11.5, color: currentTheme.textSecondaryColor)),
                          ),
                          if (r.count > 1)
                            Text('คนละ ฿${FormatUtils.formatCurrency(r.perPersonAmount)}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(r.explanationTh, style: TextStyle(fontSize: 11, height: 1.35, color: currentTheme.textSecondaryColor)),
                    ],
                  ),
                )),
          ],

          if (blockedList.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.block_rounded, size: 14, color: currentTheme.textSecondaryColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('ญาติที่ไม่ได้รับสิทธิ์ในรอบนี้ (Hajb):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...blockedList.map((b) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1.5),
                        child: Text('• $b', style: TextStyle(fontSize: 11.5, color: currentTheme.textSecondaryColor)),
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: 7 VISUAL CASE STUDIES (เข้าใจง่ายสุดๆ)
  // ==========================================
  Widget _buildComplexCasesTab(dynamic currentTheme, bool isDark, bool isEn) {
    final cases = [
      {
        'id': 1,
        'title': '1. มรดกซ้อนมรดก (มูนากอฮอต)',
        'situation': 'พ่อเสียชีวิต แต่ครอบครัวยังไม่ได้แบ่งมรดก จนต่อมาลูกชายเสียชีวิตตามไป และลูกชายก็มีภรรยากับลูกของตัวเอง',
        'solution': 'ต้องตั้งโจทย์มรดก 2 ชั้น และโอนหุ้นมรดกจากพ่อไปสู่ครอบครัวของลูกชาย เพื่อไม่ให้ทายาทรุ่นหลานเสียสิทธิ์',
        'icon': Icons.layers_rounded,
        'color': const Color(0xFF3B82F6),
      },
      {
        'id': 2,
        'title': '2. คดีพ่อ-แม่-คู่สมรส (คดีท่านอุมัร)',
        'situation': 'ผู้ตายไม่มีลูก เหลือเพียง ภรรยา + แม่ + พ่อ หากคิดตามปกติแม่จะได้มากกว่าพ่อ ซึ่งขัดกับหลักความยุติธรรม',
        'solution': 'ท่านอุมัรจึงตัดสินให้หักส่วนของภรรยาออกก่อน แล้วให้แม่ได้ 1/3 ของส่วนที่เหลือ และพ่อได้ส่วนที่เหลือทั้งหมด เพื่อรักษาอัตรา 2:1',
        'icon': Icons.gavel_rounded,
        'color': const Color(0xFFF59E0B),
      },
      {
        'id': 3,
        'title': '3. คดีหินทิ้งทะเล (พี่น้องแท้ร่วมกับพี่น้องต่างพ่อ)',
        'situation': 'ผู้ตายเหลือ สามี + แม่ + พี่น้องร่วมแม่ 2 คน + พี่น้องแท้ (พ่อแม่เดียวกัน) ปรากฏว่าเงินหมดกองพอดี ทำให้พี่น้องแท้ไม่ได้อะไรเลย',
        'solution': 'พี่น้องแท้ร้องเรียนว่าแม้พ่อต่างกันแต่แม่เดียวกัน ท่านอุมัรจึงตัดสินให้พี่น้องแท้เข้าไปร่วมแบ่งในส่วน 1/3 ของพี่น้องร่วมแม่ด้วยกัน',
        'icon': Icons.waves_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'id': 4,
        'title': '4. คดีปู่ร่วมกับพี่สาวแท้ (อัล-อักดารียะฮ์)',
        'situation': 'ผู้ตายเหลือ สามี + แม่ + ปู่ + พี่สาวแท้ 1 คน',
        'solution': 'ให้พี่สาวได้ 1/2 ปู่ได้ 1/6 แล้วนำส่วนของทั้งสองมารวมกันแบ่งใหม่ในอัตรา ชาย 2 ส่วน : หญิง 1 ส่วน',
        'icon': Icons.elderly_rounded,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'id': 5,
        'title': '5. กรณีทายาทเป็นทารกในครรภ์',
        'situation': 'เจ้ามรดกเสียชีวิตขณะที่ภรรยากำลังตั้งครรภ์ ยังไม่ทราบเพศหรือภาวะฝาแฝด',
        'solution': 'ระบบจะกันเงินส่วนแบ่งสำรองก้อนที่มากที่สุด (สมมุติเป็นลูกชายฝาแฝด) ไว้ในบัญชีจนกว่าเด็กจะคลอดออกมาอย่างปลอดภัย',
        'icon': Icons.pregnant_woman_rounded,
        'color': const Color(0xFFEC4899),
      },
      {
        'id': 6,
        'title': '6. เสียชีวิตพร้อมกันในอุบัติเหตุ',
        'situation': 'คนในครอบครัวประสบอุบัติเหตุทางรถยนต์หรือเครื่องบินตกเสียชีวิตพร้อมกันโดยไม่รู้ว่าใครสิ้นลมหายใจก่อน',
        'solution': 'จะไม่มีการรับมรดกข้ามกันระหว่างผู้ตาย ทรัพย์สินของแต่ละคนจะถูกแยกและแบ่งให้เฉพาะทายาทที่ยังมีชีวิตอยู่ของแต่ละฝ่ายเท่านั้น',
        'icon': Icons.car_crash_rounded,
        'color': const Color(0xFFEF4444),
      },
      {
        'id': 7,
        'title': '7. กรณีทายาทสูญหาย',
        'situation': 'ทายาทคนหนึ่งหายสาบสูญในสงครามหรือภัยพิบัติโดยไม่พบร่าง',
        'solution': 'ต้องกันส่วนแบ่งของคนหายไว้จนกว่าศาลจะสั่งตัดสินว่าเสียชีวิต จึงนำส่วนที่กันไว้นั้นมาเฉลี่ยคืนให้ทายาทคนอื่นๆ',
        'icon': Icons.person_search_rounded,
        'color': const Color(0xFF06B6D4),
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
      itemCount: cases.length,
      itemBuilder: (context, index) {
        final c = cases[index];
        final color = c['color'] as Color;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: currentTheme.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: currentTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(c['icon'] as IconData, color: color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      c['title'] as String,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Situation
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: currentTheme.surfaceBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.help_outline_rounded, size: 14, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 4),
                        Text('สถานการณ์จำลอง:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      c['situation'] as String,
                      style: TextStyle(fontSize: 11.5, height: 1.4, color: currentTheme.textSecondaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Solution
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 14, color: color),
                        const SizedBox(width: 4),
                        Text('วิธีตัดสินตามหลักศาสนา:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      c['solution'] as String,
                      style: TextStyle(fontSize: 11.5, height: 1.4, color: currentTheme.textColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _loadPresetCase(c['id'] as int),
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('👉 ทดลองจำลองเคสนี้ในเครื่องคำนวณ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 3: KNOWLEDGE & ENGINE GUIDE (มินิมอล ใช้ง่าย สบายตา)
  // ==========================================
  Widget _buildKnowledgeGuideTab(dynamic currentTheme, bool isDark, bool isEn) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ลำดับ 4 สิทธิที่ผูกพันกับกองมรดก
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: currentTheme.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: currentTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.format_list_numbered_rounded, color: Color(0xFF10B981), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '1. ลำดับสิทธิ 4 ประการก่อนแบ่งมรดก',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildGuidePointItem('1. ค่าจัดการศพ (Tajhiz)', 'จัดการศพอย่างสมเกียรติและพอประมาณ ไม่ฟุ่มเฟือย', currentTheme),
                _buildGuidePointItem('2. ชำระหนี้สิน (Dayn)', 'ชำระหนี้สินของผู้เสียชีวิตทั้งหมด ทั้งหนี้มนุษย์และหนี้พระเจ้า', currentTheme),
                _buildGuidePointItem('3. พินัยกรรม (Wasiyyah)', 'จ่ายตามพินัยกรรมได้ไม่เกิน 1 ใน 3 และห้ามทำพินัยกรรมให้ทายาทที่มีสิทธิ์', currentTheme),
                _buildGuidePointItem('4. แบ่งมรดกสุทธิ (Tarikah)', 'นำทรัพย์สินสุทธิที่เหลือมาจัดสรรตามหลักฟะรออิฎให้ทายาท', currentTheme),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. กลุ่มทายาทหลักในอิสลาม
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: currentTheme.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: currentTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_alt_rounded, color: Color(0xFF3B82F6), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '2. ประเภทของทายาทในอิสลาม',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildGuidePointItem('• อัศฮาบุลฟุรูฎ (ผู้มีส่วนแบ่งตายตัว)', 'ทายาทที่มีสัดส่วนกำหนดไว้ชัดเจนในอัลกุรอาน เช่น คู่สมรส, บิดา, มารดา, บุตรสาว', currentTheme),
                _buildGuidePointItem('• อะเศาะบะฮ์ (ผู้รับส่วนที่เหลือ)', 'ทายาทสายตรงที่รับทรัพย์สินส่วนที่เหลือหลังหักฟุรูฎ เช่น บุตรชาย, พี่น้องชายแท้', currentTheme),
                _buildGuidePointItem('• ซะวิลอัรฮาม (ญาติฝ่ายหญิง/สายอื่น)', 'ญาติที่ไม่มีส่วนแบ่งตายตัวและไม่ใช่เศาะบะฮ์ จะได้รับสิทธิ์เมื่อไม่มี 2 กลุ่มแรก', currentTheme),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. สัดส่วนฟุรูฎ 6 ประเภท
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: currentTheme.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: currentTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.pie_chart_rounded, color: Color(0xFFF59E0B), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '3. สัดส่วนฟุรูฎ 6 สัดส่วนตามอัลกุรอาน',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildFurudBadge('1/2 (ครึ่งหนึ่ง)', 'สามี (เมื่อไม่มีลูก), บุตรสาวคนเดียว, หลานสาวคนเดียว, พี่สาวแท้คนเดียว', currentTheme),
                _buildFurudBadge('1/4 (หนึ่งในสี่)', 'สามี (เมื่อมีลูก), ภรรยา (เมื่อไม่มีลูก)', currentTheme),
                _buildFurudBadge('1/8 (หนึ่งในแปด)', 'ภรรยา (เมื่อผู้ตายมีลูกหรือหลาน)', currentTheme),
                _buildFurudBadge('2/3 (สองในสาม)', 'บุตรสาวตั้งแต่ 2 คนขึ้นไป, พี่สาวแท้ 2 คนขึ้นไป (เมื่อไม่มีพี่น้องชาย)', currentTheme),
                _buildFurudBadge('1/3 (หนึ่งในสาม)', 'มารดา (ไม่มีลูกและไม่มีพี่น้องหลายคน), พี่น้องร่วมมารดา 2 คนขึ้นไป', currentTheme),
                _buildFurudBadge('1/6 (หนึ่งในหก)', 'บิดา, มารดา, ปู่, ย่า/ยาย, พี่น้องร่วมมารดาคนเดียว', currentTheme),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. ขั้นตอน Engine การคำนวณ
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: currentTheme.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: currentTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.settings_suggest_rounded, color: currentTheme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '4. ขั้นตอนการคำนวณของระบบ (Engine Rules)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildEngineStepCard('1. Furud (ส่วนแบ่งตายตัว)', 'คำนวณสัดส่วน 1/2, 1/4, 1/8, 2/3, 1/3, 1/6 ให้ทายาทผู้มีสิทธิ์ตามอัลกุรอาน', currentTheme),
                _buildEngineStepCard('2. Aul (การย่อส่วนเมื่อเกิน 100%)', 'หากผลรวมส่วนแบ่งฟุรูฎเกิน 1 จะปรับฐานส่วนและย่อส่วนทุกคนตามสัดส่วนอย่างเป็นธรรม', currentTheme),
                _buildEngineStepCard('3. Asabah (จัดสรรส่วนที่เหลือ)', 'แจกส่วนที่เหลือให้ทายาทสายตรง: ชายได้ 2 ส่วน : หญิงได้ 1 ส่วน', currentTheme),
                _buildEngineStepCard('4. Radd (การเฉลี่ยคืนส่วนเกิน)', 'หากไม่มีอะเศาะบะฮ์และยังมีเงินเหลือ จะเฉลี่ยคืนให้ทายาทฟุรูฎทุกคน ยกเว้นคู่สมรส', currentTheme),
                _buildEngineStepCard('5. Baitul Mal (กองทุนสาธารณะ)', 'หากผู้เสียชีวิตไม่มีทายาทสืบสายเลือดเลย มรดกจะเข้าสู่กองทุนเพื่อประโยชน์ส่วนรวม', currentTheme),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 5. แหล่งอ้างอิงหลักทางวิชาการ
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: currentTheme.surfaceBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: currentTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bookmark_added_rounded, size: 16, color: currentTheme.primaryColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'แหล่งอ้างอิงทางวิชาการอิสลาม (Islamic References):',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: currentTheme.textColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '• อัลกุรอาน: ซูเราะฮ์ อันนิซาอ์ (4:11-12, 176)\n'
                  '• หะดีษซอฮีฮ์: ศอฮีฮ์ อัลบุคอรีย์ และศอฮีฮ์ มุสลิม\n'
                  '• มัซฮับฟิกฮ์ 4 อิมาม: ชาฟิอีย์, ฮานาฟีย์, มาลิกีย์, ฮัมบาลีย์\n'
                  '• มติเห็นพ้อง (อิจญ์มาอ์) ของสภาอุลามะอ์และสำนักจุฬาราชมนตรี',
                  style: TextStyle(fontSize: 11.5, height: 1.45, color: currentTheme.textSecondaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidePointItem(String title, String desc, dynamic currentTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
          const SizedBox(height: 2),
          Text(desc, style: TextStyle(fontSize: 11.5, height: 1.35, color: currentTheme.textSecondaryColor)),
        ],
      ),
    );
  }

  Widget _buildEngineStepCard(String title, String desc, dynamic currentTheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: currentTheme.surfaceBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
          const SizedBox(height: 2),
          Text(desc, style: TextStyle(fontSize: 11, height: 1.35, color: currentTheme.textSecondaryColor)),
        ],
      ),
    );
  }

  Widget _buildFurudBadge(String fraction, String details, dynamic currentTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
            decoration: BoxDecoration(
              color: MeowTheme.mustardYellow.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(fraction, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(details, style: TextStyle(fontSize: 11.5, color: currentTheme.textSecondaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleInput(TextEditingController ctrl, String label, String hint, dynamic currentTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: currentTheme.textSecondaryColor)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: currentTheme.textColor),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: currentTheme.surfaceBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: currentTheme.borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: currentTheme.borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: currentTheme.primaryColor, width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildCounterRow(String label, int value, int min, int max, ValueChanged<int> onChanged, dynamic currentTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 13, color: currentTheme.textColor)),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                onPressed: value > min ? () => onChanged(value - 1) : null,
              ),
              Text('$value', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: currentTheme.textColor)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                onPressed: value < max ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
