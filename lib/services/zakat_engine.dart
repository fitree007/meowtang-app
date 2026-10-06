// Zakat rules (Shafi'i school) that are more than a single percentage.

enum LivestockKind { camel, cattle, goat }

class LivestockZakat {
  final bool due;
  final String summary;
  final String detail;

  const LivestockZakat({required this.due, required this.summary, required this.detail});
}

class ZakatEngine {
  static const double goldNisabGrams = 85.0; // 20 mithqal
  static const double silverNisabGrams = 595.0; // 200 dirham
  static const double gramsPerBahtGold = 15.244;
  static const double cropNisabKg = 653.0; // 5 wasq
  static const double wealthRate = 0.025; // ربع العشر

  /// Splits [units] (a multiple of 10) into a*small + b*large, preferring more of [large].
  static (int, int)? _combo(int units, int small, int large) {
    for (var b = units ~/ large; b >= 0; b--) {
      final rest = units - b * large;
      if (rest % small == 0) return (rest ~/ small, b);
    }
    return null;
  }

  static LivestockZakat livestock(LivestockKind kind, int count) {
    switch (kind) {
      case LivestockKind.camel:
        return _camel(count);
      case LivestockKind.cattle:
        return _cattle(count);
      case LivestockKind.goat:
        return _goat(count);
    }
  }

  static LivestockZakat _camel(int n) {
    const minimum = 'นิศอบอูฐเริ่มที่ 5 ตัว';
    if (n < 5) return LivestockZakat(due: false, summary: 'ยังไม่ถึงนิศอบ', detail: '$minimum (มี $n ตัว)');
    if (n <= 24) {
      final sheep = n ~/ 5;
      return LivestockZakat(
        due: true,
        summary: 'แพะหรือแกะ $sheep ตัว',
        detail: 'อูฐ 5–24 ตัว จ่ายแพะ/แกะ (شاة) 1 ตัวต่ออูฐทุก 5 ตัว',
      );
    }
    if (n <= 35) {
      return const LivestockZakat(
          due: true, summary: 'อูฐเพศเมียอายุ 1 ปีขึ้นไป 1 ตัว', detail: 'อูฐ 25–35 ตัว จ่าย บินตุมะคอฎ (بنت مخاض)');
    }
    if (n <= 45) {
      return const LivestockZakat(
          due: true, summary: 'อูฐเพศเมียอายุ 2 ปีขึ้นไป 1 ตัว', detail: 'อูฐ 36–45 ตัว จ่าย บินตุละบูน (بنت لبون)');
    }
    if (n <= 60) {
      return const LivestockZakat(
          due: true, summary: 'อูฐเพศเมียอายุ 3 ปีขึ้นไป 1 ตัว', detail: 'อูฐ 46–60 ตัว จ่าย หิกเกาะฮ์ (حقة)');
    }
    if (n <= 75) {
      return const LivestockZakat(
          due: true, summary: 'อูฐเพศเมียอายุ 4 ปีขึ้นไป 1 ตัว', detail: 'อูฐ 61–75 ตัว จ่าย ญะซะอะฮ์ (جذعة)');
    }
    if (n <= 90) {
      return const LivestockZakat(
          due: true, summary: 'อูฐเพศเมียอายุ 2 ปีขึ้นไป 2 ตัว', detail: 'อูฐ 76–90 ตัว จ่าย บินตุละบูน (بنت لبون) 2 ตัว');
    }
    if (n <= 120) {
      return const LivestockZakat(
          due: true, summary: 'อูฐเพศเมียอายุ 3 ปีขึ้นไป 2 ตัว', detail: 'อูฐ 91–120 ตัว จ่าย หิกเกาะฮ์ (حقة) 2 ตัว');
    }
    final units = (n ~/ 10) * 10;
    final c = _combo(units, 40, 50) ?? (units ~/ 40, 0);
    final parts = [
      if (c.$2 > 0) 'อูฐอายุ 3 ปี (حقة) ${c.$2} ตัว',
      if (c.$1 > 0) 'อูฐอายุ 2 ปี (بنت لبون) ${c.$1} ตัว',
    ];
    return LivestockZakat(
      due: true,
      summary: parts.join(' + '),
      detail: 'อูฐตั้งแต่ 121 ตัว: ทุก 40 ตัวจ่าย บินตุละบูน 1 ตัว และทุก 50 ตัวจ่าย หิกเกาะฮ์ 1 ตัว',
    );
  }

  static LivestockZakat _cattle(int n) {
    if (n < 30) {
      return LivestockZakat(due: false, summary: 'ยังไม่ถึงนิศอบ', detail: 'นิศอบวัว/ควายเริ่มที่ 30 ตัว (มี $n ตัว)');
    }
    if (n < 40) {
      return const LivestockZakat(
          due: true, summary: 'วัวอายุ 1 ปีขึ้นไป 1 ตัว', detail: 'วัว 30–39 ตัว จ่าย ตะบีอ์ (تبيع) 1 ตัว');
    }
    if (n < 60) {
      return const LivestockZakat(
          due: true, summary: 'วัวเพศเมียอายุ 2 ปีขึ้นไป 1 ตัว', detail: 'วัว 40–59 ตัว จ่าย มุสินนะฮ์ (مسنة) 1 ตัว');
    }
    final units = (n ~/ 10) * 10;
    final c = _combo(units, 30, 40) ?? (units ~/ 30, 0);
    final parts = [
      if (c.$2 > 0) 'วัวอายุ 2 ปี (مسنة) ${c.$2} ตัว',
      if (c.$1 > 0) 'วัวอายุ 1 ปี (تبيع) ${c.$1} ตัว',
    ];
    return LivestockZakat(
      due: true,
      summary: parts.join(' + '),
      detail: 'วัวตั้งแต่ 60 ตัว: ทุก 30 ตัวจ่าย ตะบีอ์ 1 ตัว และทุก 40 ตัวจ่าย มุสินนะฮ์ 1 ตัว (หะดีษมุอาซ บิน ญะบัล)',
    );
  }

  static LivestockZakat _goat(int n) {
    if (n < 40) {
      return LivestockZakat(due: false, summary: 'ยังไม่ถึงนิศอบ', detail: 'นิศอบแพะ/แกะเริ่มที่ 40 ตัว (มี $n ตัว)');
    }
    final int count;
    final String rule;
    if (n <= 120) {
      count = 1;
      rule = 'แพะ/แกะ 40–120 ตัว จ่าย 1 ตัว';
    } else if (n <= 200) {
      count = 2;
      rule = 'แพะ/แกะ 121–200 ตัว จ่าย 2 ตัว';
    } else if (n <= 399) {
      count = 3;
      rule = 'แพะ/แกะ 201–399 ตัว จ่าย 3 ตัว';
    } else {
      count = n ~/ 100;
      rule = 'ตั้งแต่ 400 ตัว จ่าย 1 ตัวต่อทุก 100 ตัว';
    }
    return LivestockZakat(due: true, summary: 'แพะหรือแกะ $count ตัว', detail: rule);
  }
}
