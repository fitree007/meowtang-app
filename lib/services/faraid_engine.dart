// Faraid (Islamic inheritance) engine.
//
// Follows the Shafi'i school (the school followed by most Muslims in Thailand):
//  - Al-Umariyyatayn, Al-Mushtarakah (tashrik) and Al-Akdariyyah are applied.
//  - Grandfather with siblings follows Zayd ibn Thabit (muqasamah / 1/3 / 1/6, with 'addah).
//  - Radd goes to every fixed-share heir except the spouse.
// All shares are exact fractions (BigInt based) so they also work on the web build.

class Frac implements Comparable<Frac> {
  final BigInt num;
  final BigInt den;

  const Frac._(this.num, this.den);

  factory Frac(int n, [int d = 1]) => Frac.fromBig(BigInt.from(n), BigInt.from(d));

  factory Frac.fromBig(BigInt n, BigInt d) {
    if (d == BigInt.zero) throw ArgumentError('zero denominator');
    if (d.isNegative) {
      n = -n;
      d = -d;
    }
    final g = n.gcd(d);
    if (g == BigInt.zero) return Frac._(BigInt.zero, BigInt.one);
    return Frac._(n ~/ g, d ~/ g);
  }

  static final Frac zero = Frac(0);
  static final Frac one = Frac(1);

  Frac operator +(Frac o) => Frac.fromBig(num * o.den + o.num * den, den * o.den);
  Frac operator -(Frac o) => Frac.fromBig(num * o.den - o.num * den, den * o.den);
  Frac operator *(Frac o) => Frac.fromBig(num * o.num, den * o.den);
  Frac operator /(Frac o) => Frac.fromBig(num * o.den, den * o.num);
  bool operator >(Frac o) => compareTo(o) > 0;
  bool operator <(Frac o) => compareTo(o) < 0;
  bool operator >=(Frac o) => compareTo(o) >= 0;
  bool operator <=(Frac o) => compareTo(o) <= 0;

  Frac times(int k) => this * Frac(k);
  Frac over(int k) => this / Frac(k);

  bool get isZero => num == BigInt.zero;
  bool get isPositive => num > BigInt.zero;
  double toDouble() => num / den;

  @override
  int compareTo(Frac o) => (num * o.den).compareTo(o.num * den);

  @override
  bool operator ==(Object other) => other is Frac && other.num == num && other.den == den;

  @override
  int get hashCode => Object.hash(num, den);

  @override
  String toString() => den == BigInt.one ? '$num' : '$num/$den';
}

BigInt _lcm(BigInt a, BigInt b) => a ~/ a.gcd(b) * b;

enum HeirGroup { spouse, descendant, ascendant, sibling, distant }

enum HeirType {
  husband('สามี', 'زوج', 'Zawj', true, 1, HeirGroup.spouse),
  wife('ภรรยา', 'زوجة', 'Zawjah', false, 4, HeirGroup.spouse),
  son('ลูกชาย', 'ابن', 'Ibn', true, 20, HeirGroup.descendant),
  daughter('ลูกสาว', 'بنت', 'Bint', false, 20, HeirGroup.descendant),
  sonsSon('หลานชาย (ลูกของลูกชาย)', 'ابن الابن', 'Ibn al-Ibn', true, 30, HeirGroup.descendant),
  sonsDaughter('หลานสาว (ลูกของลูกชาย)', 'بنت الابن', 'Bint al-Ibn', false, 30, HeirGroup.descendant),
  father('พ่อ', 'أب', 'Ab', true, 1, HeirGroup.ascendant),
  mother('แม่', 'أم', 'Umm', false, 1, HeirGroup.ascendant),
  grandfather('ปู่ (พ่อของพ่อ)', 'جد', 'Jadd', true, 1, HeirGroup.ascendant),
  grandmotherPaternal('ย่า (แม่ของพ่อ)', 'جدة لأب', 'Jaddah li-Ab', false, 1, HeirGroup.ascendant),
  grandmotherMaternal('ยาย (แม่ของแม่)', 'جدة لأم', 'Jaddah li-Umm', false, 1, HeirGroup.ascendant),
  fullBrother('พี่/น้องชาย ร่วมพ่อแม่', 'أخ شقيق', 'Akh Shaqiq', true, 20, HeirGroup.sibling),
  fullSister('พี่/น้องสาว ร่วมพ่อแม่', 'أخت شقيقة', 'Ukht Shaqiqah', false, 20, HeirGroup.sibling),
  paternalBrother('พี่/น้องชาย ร่วมพ่อ (ต่างแม่)', 'أخ لأب', 'Akh li-Ab', true, 20, HeirGroup.sibling),
  paternalSister('พี่/น้องสาว ร่วมพ่อ (ต่างแม่)', 'أخت لأب', 'Ukht li-Ab', false, 20, HeirGroup.sibling),
  maternalBrother('พี่/น้องชาย ร่วมแม่ (ต่างพ่อ)', 'أخ لأم', 'Akh li-Umm', true, 20, HeirGroup.sibling),
  maternalSister('พี่/น้องสาว ร่วมแม่ (ต่างพ่อ)', 'أخت لأم', 'Ukht li-Umm', false, 20, HeirGroup.sibling),
  fullNephew('หลานชาย (ลูกชายของพี่น้องชายร่วมพ่อแม่)', 'ابن الأخ الشقيق', 'Ibn al-Akh ash-Shaqiq', true, 30, HeirGroup.distant),
  paternalNephew('หลานชาย (ลูกชายของพี่น้องชายร่วมพ่อ)', 'ابن الأخ لأب', 'Ibn al-Akh li-Ab', true, 30, HeirGroup.distant),
  fullUncle('ลุง/อา (พี่น้องชายร่วมพ่อแม่ของพ่อ)', 'عم شقيق', "'Amm Shaqiq", true, 20, HeirGroup.distant),
  paternalUncle('ลุง/อา (พี่น้องชายร่วมปู่ของพ่อ)', 'عم لأب', "'Amm li-Ab", true, 20, HeirGroup.distant),
  fullCousin('ลูกชายของลุง/อา (ร่วมพ่อแม่)', 'ابن العم الشقيق', "Ibn al-'Amm ash-Shaqiq", true, 30, HeirGroup.distant),
  paternalCousin('ลูกชายของลุง/อา (ร่วมปู่)', 'ابن العم لأب', "Ibn al-'Amm li-Ab", true, 30, HeirGroup.distant);

  const HeirType(this.th, this.ar, this.arLatin, this.isMale, this.maxCount, this.group);

  final String th;
  final String ar;
  final String arLatin;
  final bool isMale;
  final int maxCount;
  final HeirGroup group;
}

enum ShareBasis {
  fard('ฟัรฎ์', 'فرض', 'ส่วนแบ่งตายตัวตามอัลกุรอาน'),
  asabah('อะศอบะฮ์', 'عصبة', 'รับส่วนที่เหลือ'),
  fardAndAsabah('ฟัรฎ์ + อะศอบะฮ์', 'فرض وتعصيب', 'ได้ส่วนตายตัวและรับส่วนที่เหลือด้วย'),
  radd('ฟัรฎ์ + ร็อด', 'فرض ورد', 'ได้ส่วนตายตัวและได้ส่วนเกินเฉลี่ยคืน'),
  muqasamah('มุกอซะมะฮ์', 'مقاسمة', 'แบ่งร่วมกับพี่น้อง'),
  special('กรณีพิเศษ', 'مسألة خاصة', 'ตัดสินตามกรณีศึกษาของเศาะหาบะฮ์');

  const ShareBasis(this.th, this.ar, this.desc);
  final String th;
  final String ar;
  final String desc;
}

class FaraidInput {
  final bool deceasedMale;
  final Map<HeirType, int> heirs;

  const FaraidInput({required this.deceasedMale, required this.heirs});

  /// Heir counts after applying gender and max-count rules.
  Map<HeirType, int> normalized() {
    final out = <HeirType, int>{};
    for (final t in HeirType.values) {
      var v = (heirs[t] ?? 0).clamp(0, t.maxCount);
      if (t == HeirType.husband && deceasedMale) v = 0;
      if (t == HeirType.wife && !deceasedMale) v = 0;
      if (v > 0) out[t] = v;
    }
    return out;
  }
}

class HeirShare {
  final HeirType type;
  final int count;
  final Frac share; // whole group, as a fraction of the estate
  final String fractionLabel; // e.g. "1/8", "อะศอบะฮ์ (2:1)"
  final ShareBasis basis;
  final String reason;

  const HeirShare({
    required this.type,
    required this.count,
    required this.share,
    required this.fractionLabel,
    required this.basis,
    required this.reason,
  });

  Frac get perPerson => share.over(count);
}

class BlockedHeir {
  final HeirType type;
  final int count;
  final String reason;

  const BlockedHeir(this.type, this.count, this.reason);
}

class FaraidStep {
  final String title;
  final String ar;
  final String detail;

  const FaraidStep(this.title, this.ar, this.detail);
}

class FaraidResult {
  final List<HeirShare> shares;
  final List<BlockedHeir> blocked;
  final List<FaraidStep> steps;
  final int asl; // أصل المسألة
  final int? awlTo; // العول
  final bool isRadd; // الرد
  final int tashih; // final common denominator (per person)
  final Frac unallocated; // to bayt al-mal / dhawu al-arham
  final String? specialCase;

  const FaraidResult({
    required this.shares,
    required this.blocked,
    required this.steps,
    required this.asl,
    required this.awlTo,
    required this.isRadd,
    required this.tashih,
    required this.unallocated,
    required this.specialCase,
  });

  HeirShare? shareOf(HeirType t) {
    for (final s in shares) {
      if (s.type == t) return s;
    }
    return null;
  }

  Frac get totalAllocated => shares.fold(Frac.zero, (a, s) => a + s.share);
}

String _pct(Frac f) => '${(f.toDouble() * 100).toStringAsFixed(2)}%';

class FaraidEngine {
  static const _distantChain = [
    HeirType.fullNephew,
    HeirType.paternalNephew,
    HeirType.fullUncle,
    HeirType.paternalUncle,
    HeirType.fullCousin,
    HeirType.paternalCousin,
  ];

  static FaraidResult calculate(FaraidInput input) {
    final n = input.normalized();
    int c(HeirType t) => n[t] ?? 0;
    bool has(HeirType t) => c(t) > 0;

    final blocked = <BlockedHeir>[];
    void block(HeirType t, String reason) {
      if (!has(t)) return;
      blocked.add(BlockedHeir(t, c(t), reason));
      n.remove(t);
    }

    final presentAtStart = Map<HeirType, int>.from(n);
    final maleDesc = has(HeirType.son) || has(HeirType.sonsSon);
    final femaleDesc = has(HeirType.daughter) || has(HeirType.sonsDaughter);
    final anyDesc = maleDesc || femaleDesc;
    final siblingCount = c(HeirType.fullBrother) +
        c(HeirType.fullSister) +
        c(HeirType.paternalBrother) +
        c(HeirType.paternalSister) +
        c(HeirType.maternalBrother) +
        c(HeirType.maternalSister);

    // ---------- 1. Al-Hajb (exclusion) ----------
    if (has(HeirType.son)) {
      block(HeirType.sonsSon, 'ถูกลูกชายกันสิทธิ์ เพราะลูกชายใกล้ชิดผู้ตายมากกว่า');
      block(HeirType.sonsDaughter, 'ถูกลูกชายกันสิทธิ์ เพราะลูกชายใกล้ชิดผู้ตายมากกว่า');
    } else if (c(HeirType.daughter) >= 2 && !has(HeirType.sonsSon)) {
      block(HeirType.sonsDaughter,
          'ลูกสาว 2 คนขึ้นไปได้ 2/3 ซึ่งเป็นส่วนเต็มของทายาทหญิงสายลูกแล้ว และไม่มีหลานชายมาพาเป็นอะศอบะฮ์');
    }

    if (has(HeirType.father)) {
      block(HeirType.grandfather, 'ถูกพ่อกันสิทธิ์ (พ่อใกล้ชิดกว่า)');
      block(HeirType.grandmotherPaternal, 'ถูกพ่อกันสิทธิ์ (ย่าเชื่อมกับผู้ตายผ่านพ่อ)');
    }
    if (has(HeirType.mother)) {
      block(HeirType.grandmotherPaternal, 'ถูกแม่กันสิทธิ์ (แม่ใกล้ชิดกว่า)');
      block(HeirType.grandmotherMaternal, 'ถูกแม่กันสิทธิ์ (แม่ใกล้ชิดกว่า)');
    }
    final gfActive = has(HeirType.grandfather);

    if (anyDesc || has(HeirType.father) || gfActive) {
      final why = anyDesc
          ? 'ผู้ตายมีลูก/หลาน'
          : (has(HeirType.father) ? 'ผู้ตายมีพ่อ' : 'ผู้ตายมีปู่');
      final msg = 'พี่น้องร่วมแม่ได้มรดกเฉพาะกรณี "กะลาละฮ์" (كلالة) คือไม่มีลูกหลานและไม่มีพ่อ/ปู่ — กรณีนี้$why';
      block(HeirType.maternalBrother, msg);
      block(HeirType.maternalSister, msg);
    }

    if (maleDesc || has(HeirType.father)) {
      final msg = maleDesc ? 'ถูกลูกชาย/หลานชายกันสิทธิ์' : 'ถูกพ่อกันสิทธิ์';
      block(HeirType.fullBrother, msg);
      block(HeirType.fullSister, msg);
      block(HeirType.paternalBrother, msg);
      block(HeirType.paternalSister, msg);
    }

    final gfWithSiblings = gfActive &&
        (has(HeirType.fullBrother) ||
            has(HeirType.fullSister) ||
            has(HeirType.paternalBrother) ||
            has(HeirType.paternalSister));
    final fullSisterWithDaughters =
        !gfWithSiblings && has(HeirType.fullSister) && !has(HeirType.fullBrother) && femaleDesc;

    if (!gfWithSiblings) {
      if (has(HeirType.fullBrother)) {
        const msg = 'ถูกพี่น้องชายร่วมพ่อแม่กันสิทธิ์ (สายสัมพันธ์แน่นแฟ้นกว่า)';
        block(HeirType.paternalBrother, msg);
        block(HeirType.paternalSister, msg);
      } else if (fullSisterWithDaughters) {
        const msg = 'พี่น้องสาวร่วมพ่อแม่เป็นอะศอบะฮ์ร่วมกับลูกสาว (عصبة مع الغير) จึงมีฐานะเหมือนพี่น้องชาย และกันสิทธิ์พี่น้องร่วมพ่อ';
        block(HeirType.paternalBrother, msg);
        block(HeirType.paternalSister, msg);
      } else if (c(HeirType.fullSister) >= 2 && !has(HeirType.paternalBrother)) {
        block(HeirType.paternalSister,
            'พี่น้องสาวร่วมพ่อแม่ 2 คนขึ้นไปได้ 2/3 เต็มแล้ว และไม่มีพี่น้องชายร่วมพ่อมาพาเป็นอะศอบะฮ์');
      }
    }

    // ---------- Al-Akdariyyah ----------
    final sisterTotal = c(HeirType.fullSister) + c(HeirType.paternalSister);
    final isAkdariyyah = gfWithSiblings &&
        has(HeirType.husband) &&
        has(HeirType.mother) &&
        !anyDesc &&
        sisterTotal == 1 &&
        !has(HeirType.fullBrother) &&
        !has(HeirType.paternalBrother) &&
        n.keys.every((t) =>
            t == HeirType.husband ||
            t == HeirType.mother ||
            t == HeirType.grandfather ||
            t == HeirType.fullSister ||
            t == HeirType.paternalSister ||
            t.group == HeirGroup.distant);
    if (isAkdariyyah) {
      for (final t in _distantChain) {
        block(t, 'ถูกปู่กันสิทธิ์');
      }
      return _akdariyyah(n, blocked, presentAtStart);
    }

    // ---------- 2. Al-Furud (fixed shares) ----------
    final fard = <HeirType, Frac>{};
    final label = <HeirType, String>{};
    final why = <HeirType, String>{};
    final steps = <FaraidStep>[];
    String? special;

    void setFard(HeirType t, Frac f, String lbl, String reason) {
      fard[t] = f;
      label[t] = lbl;
      why[t] = reason;
    }

    Frac spouseShare = Frac.zero;
    if (has(HeirType.husband)) {
      spouseShare = anyDesc ? Frac(1, 4) : Frac(1, 2);
      setFard(
        HeirType.husband,
        spouseShare,
        '$spouseShare',
        anyDesc
            ? 'สามีได้ 1/4 เพราะภรรยาผู้ตายมีลูกหรือหลาน (อัน-นิสาอ์ 4:12)'
            : 'สามีได้ 1/2 เพราะภรรยาผู้ตายไม่มีลูกหรือหลาน (อัน-นิสาอ์ 4:12)',
      );
    }
    if (has(HeirType.wife)) {
      spouseShare = anyDesc ? Frac(1, 8) : Frac(1, 4);
      final many = c(HeirType.wife) > 1 ? ' แบ่งเท่ากัน ${c(HeirType.wife)} คน' : '';
      setFard(
        HeirType.wife,
        spouseShare,
        '$spouseShare',
        anyDesc
            ? 'ภรรยาได้ 1/8 เพราะสามีผู้ตายมีลูกหรือหลาน (อัน-นิสาอ์ 4:12)$many'
            : 'ภรรยาได้ 1/4 เพราะสามีผู้ตายไม่มีลูกหรือหลาน (อัน-นิสาอ์ 4:12)$many',
      );
    }

    if (has(HeirType.mother)) {
      if (anyDesc) {
        setFard(HeirType.mother, Frac(1, 6), '1/6', 'แม่ได้ 1/6 เพราะผู้ตายมีลูกหรือหลาน (อัน-นิสาอ์ 4:11)');
      } else if (siblingCount >= 2) {
        setFard(HeirType.mother, Frac(1, 6), '1/6',
            'แม่ได้ 1/6 เพราะผู้ตายมีพี่น้องตั้งแต่ 2 คน (แม้พี่น้องจะถูกกันสิทธิ์ก็ยังลดส่วนของแม่ได้) (อัน-นิสาอ์ 4:11)');
      } else if (has(HeirType.father) && (has(HeirType.husband) || has(HeirType.wife))) {
        final f = (Frac.one - spouseShare).over(3);
        special = 'อัล-อุมะรียะตาน (العمريتان)';
        setFard(HeirType.mother, f, '1/3 ของที่เหลือ',
            'กรณีอุมะรียะตาน: หักส่วนคู่สมรสก่อน แม่ได้ 1/3 ของส่วนที่เหลือ (= $f ของทั้งหมด) เพื่อให้พ่อได้เป็น 2 เท่าของแม่ ตามคำตัดสินของท่านอุมัร (ร.ฎ.)');
      } else {
        setFard(HeirType.mother, Frac(1, 3), '1/3',
            'แม่ได้ 1/3 เพราะผู้ตายไม่มีลูกหลาน และมีพี่น้องไม่ถึง 2 คน (อัน-นิสาอ์ 4:11)');
      }
    }

    final grandmothers = [HeirType.grandmotherPaternal, HeirType.grandmotherMaternal].where(has).toList();
    for (final g in grandmothers) {
      final f = Frac(1, 6).over(grandmothers.length);
      setFard(g, f, grandmothers.length > 1 ? '1/6 (แบ่งครึ่งกับย่า/ยาย)' : '1/6',
          'ย่า/ยายได้ 1/6 เมื่อไม่มีแม่ (ตามหะดีษที่ท่านนบีให้ย่า/ยาย 1/6)${grandmothers.length > 1 ? ' — มีทั้งย่าและยายจึงแบ่ง 1/6 กันคนละครึ่ง' : ''}');
    }

    HeirType? fatherLike;
    if (has(HeirType.father)) {
      fatherLike = HeirType.father;
    } else if (gfActive && !gfWithSiblings) {
      fatherLike = HeirType.grandfather;
    }
    var fatherLikeAsabah = false;
    if (fatherLike != null) {
      final who = fatherLike == HeirType.father ? 'พ่อ' : 'ปู่ (แทนพ่อ)';
      if (maleDesc) {
        setFard(fatherLike, Frac(1, 6), '1/6', '$whoได้ 1/6 เพราะผู้ตายมีลูกชายหรือหลานชาย (อัน-นิสาอ์ 4:11)');
      } else if (femaleDesc) {
        setFard(fatherLike, Frac(1, 6), '1/6 + ที่เหลือ',
            '$whoได้ 1/6 เพราะผู้ตายมีลูกสาว/หลานสาว และยังรับส่วนที่เหลือในฐานะอะศอบะฮ์ด้วย');
        fatherLikeAsabah = true;
      } else {
        fatherLikeAsabah = true;
      }
    }

    if (has(HeirType.daughter) && !has(HeirType.son)) {
      final one = c(HeirType.daughter) == 1;
      setFard(HeirType.daughter, one ? Frac(1, 2) : Frac(2, 3), one ? '1/2' : '2/3',
          one
              ? 'ลูกสาวคนเดียวที่ไม่มีลูกชายร่วมด้วย ได้ 1/2 (อัน-นิสาอ์ 4:11)'
              : 'ลูกสาวตั้งแต่ 2 คนที่ไม่มีลูกชายร่วมด้วย ได้ 2/3 แบ่งเท่ากัน (อัน-นิสาอ์ 4:11)');
    }

    if (has(HeirType.sonsDaughter) && !has(HeirType.sonsSon)) {
      if (!has(HeirType.daughter)) {
        final one = c(HeirType.sonsDaughter) == 1;
        setFard(HeirType.sonsDaughter, one ? Frac(1, 2) : Frac(2, 3), one ? '1/2' : '2/3',
            'หลานสาว (ลูกของลูกชาย) มีฐานะแทนลูกสาวเมื่อไม่มีลูก จึงได้ ${one ? '1/2' : '2/3'}');
      } else if (c(HeirType.daughter) == 1) {
        setFard(HeirType.sonsDaughter, Frac(1, 6), '1/6 (ตักมิละฮ์)',
            'ลูกสาวคนเดียวได้ 1/2 หลานสาวได้ 1/6 เพื่อเติมให้ครบ 2/3 (تكملة للثلثين) ตามหะดีษของอิบนุมัสอูด');
      }
    }

    final mCount = c(HeirType.maternalBrother) + c(HeirType.maternalSister);
    if (mCount > 0) {
      final total = mCount == 1 ? Frac(1, 6) : Frac(1, 3);
      for (final t in [HeirType.maternalBrother, HeirType.maternalSister].where(has)) {
        setFard(t, total * Frac(c(t), mCount), mCount == 1 ? '1/6' : '1/3 (หารรายหัว)',
            'พี่น้องร่วมแม่ (กะลาละฮ์) ${mCount == 1 ? 'คนเดียวได้ 1/6' : 'ตั้งแต่ 2 คนได้ 1/3'} ชายหญิงได้เท่ากัน (อัน-นิสาอ์ 4:12)');
      }
    }

    if (!gfWithSiblings) {
      if (has(HeirType.fullSister) && !has(HeirType.fullBrother) && !fullSisterWithDaughters) {
        final one = c(HeirType.fullSister) == 1;
        setFard(HeirType.fullSister, one ? Frac(1, 2) : Frac(2, 3), one ? '1/2' : '2/3',
            'พี่น้องสาวร่วมพ่อแม่ ${one ? 'คนเดียวได้ 1/2' : 'ตั้งแต่ 2 คนได้ 2/3'} (อัน-นิสาอ์ 4:176)');
      }
      if (has(HeirType.paternalSister) && !has(HeirType.paternalBrother)) {
        final withDaughters = femaleDesc && !has(HeirType.fullSister);
        if (!withDaughters) {
          if (has(HeirType.fullSister)) {
            setFard(HeirType.paternalSister, Frac(1, 6), '1/6 (ตักมิละฮ์)',
                'พี่น้องสาวร่วมพ่อแม่ได้ 1/2 พี่น้องสาวร่วมพ่อจึงได้ 1/6 เติมให้ครบ 2/3');
          } else {
            final one = c(HeirType.paternalSister) == 1;
            setFard(HeirType.paternalSister, one ? Frac(1, 2) : Frac(2, 3), one ? '1/2' : '2/3',
                'พี่น้องสาวร่วมพ่อมีฐานะแทนพี่น้องสาวร่วมพ่อแม่ จึงได้ ${one ? '1/2' : '2/3'} (อัน-นิสาอ์ 4:176)');
          }
        }
      }
    }

    // ---------- Grandfather with siblings (Zayd ibn Thabit) ----------
    final asabah = <HeirType, Frac>{};
    final asabahLabel = <HeirType, String>{};
    final asabahWhy = <HeirType, String>{};
    final basisOverride = <HeirType, ShareBasis>{};

    if (gfWithSiblings) {
      special ??= 'ปู่ร่วมกับพี่น้อง (الجد والإخوة)';
      final f = fard.values.fold(Frac.zero, (a, b) => a + b);
      final r = Frac.one - f;
      final siblingTypes = [
        HeirType.fullBrother,
        HeirType.fullSister,
        HeirType.paternalBrother,
        HeirType.paternalSister,
      ].where(has).toList();

      if (r <= Frac(1, 6)) {
        setFard(HeirType.grandfather, Frac(1, 6), '1/6',
            'ส่วนที่เหลือหลังหักฟัรฎ์ไม่เกิน 1/6 ปู่จึงได้ 1/6 ซึ่งเป็นสิทธิ์ขั้นต่ำของปู่');
        for (final t in siblingTypes) {
          block(t, 'ไม่มีส่วนเหลือหลังจากปู่ได้ 1/6 พี่น้องจึงไม่ได้รับ');
        }
      } else {
        final brothers = c(HeirType.fullBrother) + c(HeirType.paternalBrother);
        final sisters = c(HeirType.fullSister) + c(HeirType.paternalSister);
        final units = 2 + 2 * brothers + sisters;
        final muq = r * Frac(2, units);
        final options = <MapEntry<String, Frac>>[
          MapEntry('มุกอซะมะฮ์ (المقاسمة) นับปู่เป็นพี่น้องชายอีกคน', muq),
        ];
        if (f.isZero) {
          options.add(MapEntry('1/3 ของทั้งหมด (ثلث المال)', Frac(1, 3)));
        } else {
          options.add(MapEntry('1/3 ของส่วนที่เหลือ (ثلث الباقي)', r.over(3)));
          options.add(MapEntry('1/6 ของทั้งหมด (السدس)', Frac(1, 6)));
        }
        var best = options.first;
        for (final o in options) {
          if (o.value > best.value) best = o;
        }
        final gfShare = best.value;
        asabah[HeirType.grandfather] = gfShare;
        asabahLabel[HeirType.grandfather] = 'เลือกทางที่ดีที่สุด';
        basisOverride[HeirType.grandfather] = ShareBasis.muqasamah;
        asabahWhy[HeirType.grandfather] =
            'ตามมัซฮับชาฟิอีย์ (แนวท่านซัยด์ บิน ษาบิต) ปู่ได้ทางเลือกที่มากที่สุด: '
            '${options.map((o) => '${o.key} = ${_pct(o.value)}').join(' • ')} → ได้ "${best.key}"';

        var left = r - gfShare;
        if (has(HeirType.fullBrother)) {
          _splitMaleFemale(asabah, asabahLabel, asabahWhy, HeirType.fullBrother, HeirType.fullSister, c, left,
              'พี่น้องร่วมพ่อแม่รับส่วนที่เหลือหลังจากปู่ ชาย 2 : หญิง 1');
          for (final t in [HeirType.paternalBrother, HeirType.paternalSister]) {
            block(t,
                'นับรวมเพื่อลดส่วนของปู่ (المعادّة) แต่สุดท้ายถูกพี่น้องชายร่วมพ่อแม่กันสิทธิ์');
          }
        } else if (has(HeirType.fullSister)) {
          final paternalPresent = has(HeirType.paternalBrother) || has(HeirType.paternalSister);
          if (!paternalPresent) {
            asabah[HeirType.fullSister] = left;
            asabahLabel[HeirType.fullSister] = 'ส่วนที่เหลือ';
            asabahWhy[HeirType.fullSister] = 'พี่น้องสาวร่วมพ่อแม่รับส่วนที่เหลือหลังจากปู่';
          } else {
            final cap = c(HeirType.fullSister) == 1 ? Frac(1, 2) : Frac(2, 3);
            final take = left < cap ? left : cap;
            asabah[HeirType.fullSister] = take;
            asabahLabel[HeirType.fullSister] = 'ไม่เกิน $cap';
            asabahWhy[HeirType.fullSister] =
                'หลักอัล-มุอาดดะฮ์ (المعادّة): พี่น้องร่วมพ่อถูกนับเพื่อลดส่วนของปู่ แล้วคืนส่วนให้พี่น้องสาวร่วมพ่อแม่จนครบ $cap';
            left = left - take;
            if (left.isPositive) {
              _splitMaleFemale(asabah, asabahLabel, asabahWhy, HeirType.paternalBrother, HeirType.paternalSister, c,
                  left, 'พี่น้องร่วมพ่อได้ส่วนที่ยังเหลือ ชาย 2 : หญิง 1');
            } else {
              for (final t in [HeirType.paternalBrother, HeirType.paternalSister]) {
                block(t, 'นับรวมเพื่อลดส่วนของปู่ (المعادّة) แต่ไม่มีส่วนเหลือมาถึง');
              }
            }
          }
        } else {
          _splitMaleFemale(asabah, asabahLabel, asabahWhy, HeirType.paternalBrother, HeirType.paternalSister, c, left,
              'พี่น้องร่วมพ่อรับส่วนที่เหลือหลังจากปู่ ชาย 2 : หญิง 1');
        }
      }
    }

    // ---------- 3. Asabah (residuaries) ----------
    final sumF = fard.values.fold(Frac.zero, (a, b) => a + b);
    var residue = Frac.one - sumF;
    if (gfWithSiblings) residue = Frac.zero;

    List<HeirType> residGroup = [];
    String residWhy = '';
    var residFemaleOnly = false;
    String? residName;
    if (!gfWithSiblings) {
      if (has(HeirType.son)) {
        residGroup = [HeirType.son, if (has(HeirType.daughter)) HeirType.daughter];
        residName = 'ลูกชาย';
        residWhy = has(HeirType.daughter)
            ? 'ลูกชายเป็นอะศอบะฮ์ด้วยตนเอง (عصبة بالنفس) และพาลูกสาวเป็นอะศอบะฮ์ (عصبة بالغير) แบ่งชาย 2 : หญิง 1 (อัน-นิสาอ์ 4:11)'
            : 'ลูกชายเป็นอะศอบะฮ์ด้วยตนเอง (عصبة بالنفس) รับส่วนที่เหลือทั้งหมด';
      } else if (has(HeirType.sonsSon)) {
        residGroup = [HeirType.sonsSon, if (has(HeirType.sonsDaughter)) HeirType.sonsDaughter];
        residName = 'หลานชาย';
        residWhy = 'หลานชาย (ลูกของลูกชาย) แทนที่ลูกชาย รับส่วนที่เหลือ${has(HeirType.sonsDaughter) ? ' ร่วมกับหลานสาว ชาย 2 : หญิง 1' : ''}';
      } else if (fatherLikeAsabah) {
        residGroup = [fatherLike!];
        residName = fatherLike == HeirType.father ? 'พ่อ' : 'ปู่';
        residWhy = '$residName เป็นอะศอบะฮ์ที่ใกล้ชิดที่สุดเมื่อไม่มีลูกชาย/หลานชาย จึงรับส่วนที่เหลือ';
      } else if (has(HeirType.fullBrother)) {
        residGroup = [HeirType.fullBrother, if (has(HeirType.fullSister)) HeirType.fullSister];
        residName = 'พี่น้องชายร่วมพ่อแม่';
        residWhy = 'พี่น้องชายร่วมพ่อแม่รับส่วนที่เหลือ${has(HeirType.fullSister) ? ' และพาพี่น้องสาวร่วมพ่อแม่ร่วมรับ ชาย 2 : หญิง 1 (อัน-นิสาอ์ 4:176)' : ''}';
      } else if (fullSisterWithDaughters) {
        residGroup = [HeirType.fullSister];
        residFemaleOnly = true;
        residName = 'พี่น้องสาวร่วมพ่อแม่';
        residWhy = 'พี่น้องสาวร่วมพ่อแม่เป็นอะศอบะฮ์ร่วมกับลูกสาว/หลานสาว (عصبة مع الغير) ตามหะดีษ "ให้พี่น้องสาวเป็นอะศอบะฮ์ร่วมกับลูกสาว"';
      } else if (has(HeirType.paternalBrother)) {
        residGroup = [HeirType.paternalBrother, if (has(HeirType.paternalSister)) HeirType.paternalSister];
        residName = 'พี่น้องชายร่วมพ่อ';
        residWhy = 'พี่น้องชายร่วมพ่อรับส่วนที่เหลือ${has(HeirType.paternalSister) ? ' ร่วมกับพี่น้องสาวร่วมพ่อ ชาย 2 : หญิง 1' : ''}';
      } else if (has(HeirType.paternalSister) && femaleDesc && !has(HeirType.fullSister)) {
        residGroup = [HeirType.paternalSister];
        residFemaleOnly = true;
        residName = 'พี่น้องสาวร่วมพ่อ';
        residWhy = 'พี่น้องสาวร่วมพ่อเป็นอะศอบะฮ์ร่วมกับลูกสาว/หลานสาว (عصبة مع الغير)';
      } else {
        for (final t in _distantChain) {
          if (has(t)) {
            residGroup = [t];
            residName = t.th;
            residWhy = '${t.th} เป็นญาติผู้ชายสายพ่อที่ใกล้ชิดที่สุดที่ยังมีชีวิต จึงรับส่วนที่เหลือ (عصبة بالنفس)';
            break;
          }
        }
      }
    }

    // Distant male relatives only inherit when no closer residuary exists.
    final closerName = residName ?? (gfWithSiblings ? 'ปู่' : 'ญาติที่ใกล้ชิดกว่า');
    for (final t in _distantChain) {
      if (has(t) && !residGroup.contains(t)) {
        block(t, 'มีอะศอบะฮ์ที่ใกล้ชิดกว่า คือ $closerName');
      }
    }

    var awlTo = 0;
    var isRadd = false;
    var unallocated = Frac.zero;
    final residueInfo = <String>[];

    // Mushtarakah: husband + mother/grandmother + 2+ maternal siblings + full brother(s), nothing left.
    final isMushtarakah = !gfWithSiblings &&
        has(HeirType.husband) &&
        (has(HeirType.mother) || grandmothers.isNotEmpty) &&
        mCount >= 2 &&
        residGroup.isNotEmpty &&
        residGroup.first == HeirType.fullBrother &&
        !residue.isPositive;
    if (isMushtarakah) {
      special = 'อัล-มุชตะเราะกะฮ์ (المشتركة) / อัล-ฮิมาริยะฮ์';
      final heads = mCount + c(HeirType.fullBrother) + c(HeirType.fullSister);
      final pool = Frac(1, 3);
      for (final t in [
        HeirType.maternalBrother,
        HeirType.maternalSister,
        HeirType.fullBrother,
        HeirType.fullSister,
      ].where(has)) {
        fard[t] = pool * Frac(c(t), heads);
        label[t] = '1/3 หารรายหัว';
        why[t] =
            'กรณีมุชตะเราะกะฮ์: ส่วนเหลือไม่มีให้พี่น้องร่วมพ่อแม่ ท่านอุมัร (ร.ฎ.) จึงให้พี่น้องร่วมพ่อแม่เข้าร่วมแบ่ง 1/3 กับพี่น้องร่วมแม่ เพราะมาจากแม่เดียวกัน (ชายหญิงเท่ากัน)';
        basisOverride[t] = ShareBasis.special;
      }
      residGroup = [];
    }

    final sumF2 = fard.values.fold(Frac.zero, (a, b) => a + b);
    final finalShare = <HeirType, Frac>{};

    if (sumF2 > Frac.one) {
      // Al-'Awl
      for (final e in fard.entries) {
        finalShare[e.key] = e.value / sumF2;
      }
      for (final t in residGroup) {
        finalShare.putIfAbsent(t, () => Frac.zero);
        asabahWhy[t] = 'ส่วนแบ่งตายตัวรวมกันเกินกองมรดกแล้ว จึงไม่มีส่วนเหลือให้อะศอบะฮ์';
      }
      residueInfo.add('ส่วนแบ่งตายตัวรวมกันได้ ${_pct(sumF2)} เกิน 100% จึงต้องใช้ "อัล-เอาล์" (العول) ลดทุกคนลงตามสัดส่วน');
    } else {
      fard.forEach((t, f) => finalShare[t] = f);
      final rest = Frac.one - sumF2;
      if (gfWithSiblings) {
        asabah.forEach((t, f) => finalShare[t] = (finalShare[t] ?? Frac.zero) + f);
      } else if (residGroup.isNotEmpty) {
        if (rest.isPositive) {
          if (residFemaleOnly || residGroup.length == 1) {
            finalShare[residGroup.first] = (finalShare[residGroup.first] ?? Frac.zero) + rest;
          } else {
            final male = residGroup[0];
            final female = residGroup[1];
            final units = 2 * c(male) + c(female);
            finalShare[male] = (finalShare[male] ?? Frac.zero) + rest * Frac(2 * c(male), units);
            finalShare[female] = (finalShare[female] ?? Frac.zero) + rest * Frac(c(female), units);
          }
          residueInfo.add('เหลือ ${_pct(rest)} ($rest) ให้อะศอบะฮ์: $residName');
        } else {
          for (final t in residGroup) {
            finalShare.putIfAbsent(t, () => Frac.zero);
            asabahWhy[t] = 'ส่วนแบ่งตายตัวรวมกันพอดี 100% จึงไม่มีส่วนเหลือให้อะศอบะฮ์';
          }
        }
        for (final t in residGroup) {
          asabahWhy.putIfAbsent(t, () => residWhy);
        }
      } else if (rest.isPositive) {
        final raddHeirs = fard.keys.where((t) => t != HeirType.husband && t != HeirType.wife).toList();
        if (raddHeirs.isNotEmpty) {
          isRadd = true;
          final nonSpouse = raddHeirs.fold(Frac.zero, (a, t) => a + fard[t]!);
          for (final t in raddHeirs) {
            finalShare[t] = fard[t]! * (Frac.one - spouseShare) / nonSpouse;
          }
          residueInfo.add(
              'ไม่มีอะศอบะฮ์ และยังเหลือ ${_pct(rest)} จึงใช้ "อัร-ร็อด" (الرد) เฉลี่ยคืนให้ทายาทฟัรฎ์ตามสัดส่วน (ยกเว้นคู่สมรส)');
        } else {
          unallocated = rest;
          residueInfo.add(
              'ไม่มีอะศอบะฮ์และไม่มีทายาทที่รับร็อดได้ ส่วนที่เหลือ ${_pct(rest)} ตกแก่ญาติสายอื่น (ذوو الأرحام) หรือบัยตุลมาล (بيت المال)');
        }
      }
    }

    // ---------- Asl al-Mas'alah & Tashih ----------
    var aslBig = BigInt.one;
    for (final f in fard.values) {
      aslBig = _lcm(aslBig, f.den);
    }
    if (fard.isEmpty && residGroup.isNotEmpty) {
      aslBig = BigInt.from(residFemaleOnly || residGroup.length == 1
          ? c(residGroup.first)
          : 2 * c(residGroup[0]) + c(residGroup[1]));
    }
    final asl = aslBig.toInt();
    if (sumF2 > Frac.one) {
      awlTo = (sumF2 * Frac(asl)).toDouble().round();
    }

    var tashihBig = BigInt.one;
    finalShare.forEach((t, f) {
      if (f.isPositive) tashihBig = _lcm(tashihBig, f.over(c(t)).den);
    });
    if (unallocated.isPositive) tashihBig = _lcm(tashihBig, unallocated.den);
    final tashih = tashihBig.toInt();

    // ---------- Build shares ----------
    final shares = <HeirShare>[];
    for (final t in HeirType.values) {
      if (!finalShare.containsKey(t)) continue;
      final inFard = fard.containsKey(t);
      final inAsabah = residGroup.contains(t) || asabah.containsKey(t);
      ShareBasis basis;
      if (basisOverride.containsKey(t)) {
        basis = basisOverride[t]!;
      } else if (isRadd && inFard && t != HeirType.husband && t != HeirType.wife) {
        basis = ShareBasis.radd;
      } else if (inFard && inAsabah) {
        basis = ShareBasis.fardAndAsabah;
      } else if (inFard) {
        basis = ShareBasis.fard;
      } else {
        basis = ShareBasis.asabah;
      }
      final reasons = <String>[
        if (why[t] != null) why[t]!,
        if (inAsabah && asabahWhy[t] != null && asabahWhy[t] != why[t]) asabahWhy[t]!,
        if (basis == ShareBasis.radd) 'ได้รับส่วนเกินเฉลี่ยคืน (ร็อด) ตามสัดส่วนเดิม',
        if (sumF2 > Frac.one && inFard) 'ถูกลดตามสัดส่วนเพราะเกิดอัล-เอาล์ (จาก ${fard[t]} เหลือ ${finalShare[t]})',
      ];
      shares.add(HeirShare(
        type: t,
        count: presentAtStart[t] ?? c(t),
        share: finalShare[t]!,
        fractionLabel: inFard
            ? (label[t] ?? '${fard[t]}')
            : (asabahLabel[t] ?? (residFemaleOnly || residGroup.length == 1 ? 'ส่วนที่เหลือ' : 'ที่เหลือ ชาย 2 : หญิง 1')),
        basis: basis,
        reason: reasons.join('\n'),
      ));
    }

    // ---------- Explanation steps ----------
    steps.add(FaraidStep(
      'ระบุทายาทที่มีชีวิตอยู่',
      'الورثة',
      presentAtStart.isEmpty
          ? 'ไม่มีทายาทที่ระบุไว้'
          : presentAtStart.entries.map((e) => '${e.key.th} ${e.value} คน').join(', '),
    ));
    steps.add(FaraidStep(
      'ตัดสิทธิ์ทายาทที่ห่างกว่า',
      'الحجب',
      blocked.isEmpty
          ? 'ไม่มีทายาทคนใดถูกกันสิทธิ์'
          : blocked.map((b) => '• ${b.type.th}: ${b.reason}').join('\n'),
    ));
    if (fard.isNotEmpty) {
      steps.add(FaraidStep(
        'กำหนดส่วนแบ่งตายตัว',
        'الفروض المقدرة',
        fard.entries.map((e) => '• ${e.key.th}: ${label[e.key]} (= ${e.value})').join('\n'),
      ));
      final aslLine = fard.entries
          .map((e) => '${e.key.th} ${(e.value * Frac(asl)).toDouble().round()} ส่วน')
          .join(', ');
      steps.add(FaraidStep(
        'หาฐานของโจทย์',
        'أصل المسألة',
        'ตัวคูณร่วมน้อยของส่วนทั้งหมด = $asl จึงตั้งกองมรดกเป็น $asl ส่วน: $aslLine',
      ));
    }
    if (awlTo > 0) {
      steps.add(FaraidStep(
        'เพิ่มฐาน (เกิน 100%)',
        'العول',
        'ส่วนแบ่งรวมกันได้ $awlTo ส่วน มากกว่าฐาน $asl จึงเพิ่มฐานจาก $asl เป็น $awlTo ทุกคนได้ส่วนเท่าเดิมแต่หารด้วย $awlTo แทน (เหมือนเอาเค้กชิ้นเดียวแบ่งให้ทุกคนลดลงตามสัดส่วน)',
      ));
    }
    if (residueInfo.isNotEmpty) {
      steps.add(FaraidStep(
        isRadd ? 'เฉลี่ยคืนส่วนที่เหลือ' : 'แบ่งส่วนที่เหลือ',
        isRadd ? 'الرد' : 'التعصيب',
        residueInfo.join('\n'),
      ));
    }
    if (special != null) {
      steps.add(FaraidStep('กรณีพิเศษที่พบ', 'مسألة خاصة', special));
    }
    steps.add(FaraidStep(
      'ตัวหารสุดท้ายรายคน',
      'تصحيح المسألة',
      'แบ่งกองมรดกเป็น $tashih ส่วนเท่า ๆ กัน: ${shares.where((s) => s.share.isPositive).map((s) => '${s.type.th} คนละ ${(s.perPerson * Frac(tashih)).toDouble().round()} ส่วน').join(', ')}',
    ));

    return FaraidResult(
      shares: shares,
      blocked: blocked,
      steps: steps,
      asl: asl,
      awlTo: awlTo > 0 ? awlTo : null,
      isRadd: isRadd,
      tashih: tashih,
      unallocated: shares.isEmpty && presentAtStart.isEmpty ? Frac.one : unallocated,
      specialCase: special,
    );
  }

  static void _splitMaleFemale(
    Map<HeirType, Frac> out,
    Map<HeirType, String> labels,
    Map<HeirType, String> whys,
    HeirType male,
    HeirType female,
    int Function(HeirType) c,
    Frac amount,
    String reason,
  ) {
    final units = 2 * c(male) + c(female);
    if (units == 0) return;
    if (c(male) > 0) {
      out[male] = amount * Frac(2 * c(male), units);
      labels[male] = c(female) > 0 ? 'ที่เหลือ ชาย 2 : หญิง 1' : 'ส่วนที่เหลือ';
      whys[male] = reason;
    }
    if (c(female) > 0) {
      out[female] = amount * Frac(c(female), units);
      labels[female] = c(male) > 0 ? 'ที่เหลือ ชาย 2 : หญิง 1' : 'ส่วนที่เหลือ';
      whys[female] = reason;
    }
  }

  static FaraidResult _akdariyyah(
    Map<HeirType, int> n,
    List<BlockedHeir> blocked,
    Map<HeirType, int> presentAtStart,
  ) {
    final sister = n.containsKey(HeirType.fullSister) ? HeirType.fullSister : HeirType.paternalSister;
    const special = 'อัล-อักดะรียะฮ์ (الأكدرية)';
    final shares = [
      HeirShare(
        type: HeirType.husband,
        count: 1,
        share: Frac(9, 27),
        fractionLabel: '1/2 → 9/27',
        basis: ShareBasis.special,
        reason: 'สามีได้ 1/2 (3 ส่วนจากฐาน 6) ฐานเพิ่มเป็น 9 แล้วปรับเป็น 27 → 9/27',
      ),
      HeirShare(
        type: HeirType.mother,
        count: 1,
        share: Frac(6, 27),
        fractionLabel: '1/3 → 6/27',
        basis: ShareBasis.special,
        reason: 'แม่ได้ 1/3 (2 ส่วนจากฐาน 6) → 6/27',
      ),
      HeirShare(
        type: HeirType.grandfather,
        count: 1,
        share: Frac(8, 27),
        fractionLabel: '1/6 รวมแล้วแบ่ง 2:1 → 8/27',
        basis: ShareBasis.special,
        reason: 'ปู่ได้ 1/6 (1 ส่วน) แล้วนำส่วนของปู่และพี่น้องสาวมารวมกัน (1+3 = 4 ส่วน) แบ่งใหม่ ชาย 2 : หญิง 1 → ปู่ 8/27',
      ),
      HeirShare(
        type: sister,
        count: 1,
        share: Frac(4, 27),
        fractionLabel: '1/2 รวมแล้วแบ่ง 2:1 → 4/27',
        basis: ShareBasis.special,
        reason: 'พี่น้องสาวได้ 1/2 (3 ส่วน) แล้วรวมกับส่วนของปู่แบ่งใหม่ ชาย 2 : หญิง 1 → 4/27',
      ),
    ];
    return FaraidResult(
      shares: shares,
      blocked: blocked,
      steps: [
        FaraidStep('ระบุทายาทที่มีชีวิตอยู่', 'الورثة',
            presentAtStart.entries.map((e) => '${e.key.th} ${e.value} คน').join(', ')),
        const FaraidStep('กรณีพิเศษที่พบ', 'الأكدرية',
            'สามี + แม่ + ปู่ + พี่น้องสาว 1 คน เป็นกรณีที่ท่านซัยด์ บิน ษาบิต ตัดสินไว้เป็นการเฉพาะ'),
        const FaraidStep('หาฐานและเพิ่มฐาน', 'أصل المسألة والعول',
            'ฐาน 6: สามี 3, แม่ 2, ปู่ 1, พี่น้องสาว 3 = 9 ส่วน จึงเอาล์จาก 6 เป็น 9'),
        const FaraidStep('รวมส่วนปู่กับพี่น้องสาวแล้วแบ่งใหม่', 'المقاسمة',
            'ปู่ 1 + พี่น้องสาว 3 = 4 ส่วน แบ่ง ชาย 2 : หญิง 1 (3 ส่วนย่อย) หาร 4 ไม่ลงตัว จึงคูณฐาน 9 × 3 = 27'),
        const FaraidStep('ตัวหารสุดท้ายรายคน', 'تصحيح المسألة',
            'สามี 9, แม่ 6, ปู่ 8, พี่น้องสาว 4 จากทั้งหมด 27 ส่วน'),
      ],
      asl: 6,
      awlTo: 9,
      isRadd: false,
      tashih: 27,
      unallocated: Frac.zero,
      specialCase: special,
    );
  }

  // ---------------------------------------------------------------------------
  // Al-Munasakhat (an heir dies before the estate is distributed)
  // ---------------------------------------------------------------------------
  static MunasakhatResult calculateChain({
    required double estate,
    required FaraidInput root,
    List<LaterDeath> laterDeaths = const [],
  }) {
    final stages = <StageOutcome>[
      StageOutcome(
        index: 0,
        title: 'ผู้เสียชีวิตคนแรก',
        deceased: null,
        estate: estate,
        inherited: estate,
        ownAssets: 0,
        fractionOfOriginal: Frac.one,
        result: calculate(root),
      ),
    ];
    final errors = <String>[];

    for (final d in laterDeaths) {
      if (d.fromStage < 0 || d.fromStage >= stages.length) {
        errors.add('ไม่พบขั้นที่ ${d.fromStage + 1}');
        continue;
      }
      final parent = stages[d.fromStage];
      final share = parent.result.shareOf(d.heirType);
      if (share == null || d.heirIndex < 1 || d.heirIndex > share.count) {
        errors.add('${d.heirType.th} คนที่ ${d.heirIndex} ไม่ใช่ทายาทที่ได้รับมรดกในขั้นที่ ${d.fromStage + 1}');
        continue;
      }
      final key = DeceasedRef(d.fromStage, d.heirType, d.heirIndex);
      if (stages.any((s) => s.deceased == key)) {
        errors.add('${d.heirType.th} คนที่ ${d.heirIndex} ถูกเลือกซ้ำ');
        continue;
      }
      final inherited = share.perPerson.toDouble() * parent.estate;
      final frac = parent.fractionOfOriginal * share.perPerson;
      stages.add(StageOutcome(
        index: stages.length,
        title: '${d.heirType.th}${share.count > 1 ? ' คนที่ ${d.heirIndex}' : ''} (เสียชีวิตตามมา)',
        deceased: key,
        estate: inherited + d.ownAssets,
        inherited: inherited,
        ownAssets: d.ownAssets,
        fractionOfOriginal: frac,
        result: calculate(FaraidInput(deceasedMale: d.heirType.isMale, heirs: d.heirs)),
      ));
    }
    return MunasakhatResult(stages, errors);
  }
}

class DeceasedRef {
  final int stage;
  final HeirType type;
  final int index;

  const DeceasedRef(this.stage, this.type, this.index);

  @override
  bool operator ==(Object other) =>
      other is DeceasedRef && other.stage == stage && other.type == type && other.index == index;

  @override
  int get hashCode => Object.hash(stage, type, index);
}

class LaterDeath {
  final int fromStage; // 0 = the first deceased
  final HeirType heirType;
  final int heirIndex; // 1-based
  final Map<HeirType, int> heirs;
  final double ownAssets;

  const LaterDeath({
    required this.fromStage,
    required this.heirType,
    required this.heirIndex,
    required this.heirs,
    this.ownAssets = 0,
  });
}

class StageOutcome {
  final int index;
  final String title;
  final DeceasedRef? deceased;
  final double estate;
  final double inherited;
  final double ownAssets;
  final Frac fractionOfOriginal;
  final FaraidResult result;

  const StageOutcome({
    required this.index,
    required this.title,
    required this.deceased,
    required this.estate,
    required this.inherited,
    required this.ownAssets,
    required this.fractionOfOriginal,
    required this.result,
  });
}

class MunasakhatResult {
  final List<StageOutcome> stages;
  final List<String> errors;

  const MunasakhatResult(this.stages, this.errors);

  /// Individuals of [stage] that died later and passed their share on (heir type -> index -> stage no).
  Map<HeirType, Map<int, int>> passedOn(int stage) {
    final out = <HeirType, Map<int, int>>{};
    for (final s in stages) {
      final d = s.deceased;
      if (d != null && d.stage == stage) {
        out.putIfAbsent(d.type, () => {})[d.index] = s.index;
      }
    }
    return out;
  }
}
