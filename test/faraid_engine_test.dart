import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/services/faraid_engine.dart';

FaraidResult calc(bool male, Map<HeirType, int> heirs) =>
    FaraidEngine.calculate(FaraidInput(deceasedMale: male, heirs: heirs));

Frac shareOf(FaraidResult r, HeirType t) => r.shareOf(t)?.share ?? Frac.zero;

void expectTotalIsOne(FaraidResult r) {
  expect(r.totalAllocated + r.unallocated, Frac.one);
}

void main() {
  group('Basic furud & asabah', () {
    test('wife, father, mother, son, daughter', () {
      final r = calc(true, {
        HeirType.wife: 1,
        HeirType.father: 1,
        HeirType.mother: 1,
        HeirType.son: 1,
        HeirType.daughter: 1,
      });
      expect(shareOf(r, HeirType.wife), Frac(1, 8));
      expect(shareOf(r, HeirType.father), Frac(1, 6));
      expect(shareOf(r, HeirType.mother), Frac(1, 6));
      expect(shareOf(r, HeirType.son), Frac(13, 36));
      expect(shareOf(r, HeirType.daughter), Frac(13, 72));
      expect(r.asl, 24);
      expect(r.tashih, 72);
      expectTotalIsOne(r);
    });

    test('wife with full brother blocks paternal brother', () {
      final r = calc(true, {HeirType.wife: 1, HeirType.fullBrother: 1, HeirType.paternalBrother: 2});
      expect(shareOf(r, HeirType.wife), Frac(1, 4));
      expect(shareOf(r, HeirType.fullBrother), Frac(3, 4));
      expect(r.blocked.map((b) => b.type), contains(HeirType.paternalBrother));
      expectTotalIsOne(r);
    });

    test('daughter + full sister: sister is asabah ma\'a al-ghayr', () {
      final r = calc(true, {HeirType.daughter: 1, HeirType.fullSister: 1});
      expect(shareOf(r, HeirType.daughter), Frac(1, 2));
      expect(shareOf(r, HeirType.fullSister), Frac(1, 2));
    });

    test('daughter + son\'s daughter + full sister (Ibn Mas\'ud case)', () {
      final r = calc(true, {HeirType.daughter: 1, HeirType.sonsDaughter: 1, HeirType.fullSister: 1});
      expect(shareOf(r, HeirType.daughter), Frac(1, 2));
      expect(shareOf(r, HeirType.sonsDaughter), Frac(1, 6));
      expect(shareOf(r, HeirType.fullSister), Frac(1, 3));
    });

    test('father with only a daughter takes 1/6 plus residue', () {
      final r = calc(true, {HeirType.daughter: 1, HeirType.father: 1});
      expect(shareOf(r, HeirType.father), Frac(1, 2));
      expect(r.shareOf(HeirType.father)!.basis, ShareBasis.fardAndAsabah);
    });

    test('both grandmothers share 1/6', () {
      final r = calc(true, {HeirType.grandmotherPaternal: 1, HeirType.grandmotherMaternal: 1, HeirType.son: 1});
      expect(shareOf(r, HeirType.grandmotherPaternal), Frac(1, 12));
      expect(shareOf(r, HeirType.grandmotherMaternal), Frac(1, 12));
      expect(shareOf(r, HeirType.son), Frac(5, 6));
    });

    test('nephew blocked by father, uncle takes residue when alone', () {
      final r1 = calc(true, {HeirType.father: 1, HeirType.fullNephew: 2});
      expect(shareOf(r1, HeirType.father), Frac.one);
      expect(r1.blocked.map((b) => b.type), contains(HeirType.fullNephew));

      final r2 = calc(false, {HeirType.husband: 1, HeirType.fullUncle: 2, HeirType.fullCousin: 1});
      expect(shareOf(r2, HeirType.husband), Frac(1, 2));
      expect(shareOf(r2, HeirType.fullUncle), Frac(1, 2));
      expect(r2.blocked.map((b) => b.type), contains(HeirType.fullCousin));
    });
  });

  group('Awl & Radd', () {
    test('Al-Minbariyyah: wife, 2 daughters, father, mother (24 -> 27)', () {
      final r = calc(true, {HeirType.wife: 1, HeirType.daughter: 2, HeirType.father: 1, HeirType.mother: 1});
      expect(r.asl, 24);
      expect(r.awlTo, 27);
      expect(shareOf(r, HeirType.wife), Frac(3, 27));
      expect(shareOf(r, HeirType.daughter), Frac(16, 27));
      expect(shareOf(r, HeirType.father), Frac(4, 27));
      expect(shareOf(r, HeirType.mother), Frac(4, 27));
      expectTotalIsOne(r);
    });

    test('husband + 2 full sisters (6 -> 7)', () {
      final r = calc(false, {HeirType.husband: 1, HeirType.fullSister: 2});
      expect(r.awlTo, 7);
      expect(shareOf(r, HeirType.husband), Frac(3, 7));
      expect(shareOf(r, HeirType.fullSister), Frac(4, 7));
    });

    test('Radd: mother + daughter', () {
      final r = calc(true, {HeirType.mother: 1, HeirType.daughter: 1});
      expect(r.isRadd, true);
      expect(shareOf(r, HeirType.mother), Frac(1, 4));
      expect(shareOf(r, HeirType.daughter), Frac(3, 4));
    });

    test('Radd with husband: spouse is not part of radd', () {
      final r = calc(false, {HeirType.husband: 1, HeirType.mother: 1, HeirType.daughter: 1});
      expect(shareOf(r, HeirType.husband), Frac(1, 4));
      expect(shareOf(r, HeirType.mother), Frac(3, 16));
      expect(shareOf(r, HeirType.daughter), Frac(9, 16));
      expectTotalIsOne(r);
    });

    test('only a wife: the rest goes to dhawu al-arham / bayt al-mal', () {
      final r = calc(true, {HeirType.wife: 1});
      expect(shareOf(r, HeirType.wife), Frac(1, 4));
      expect(r.unallocated, Frac(3, 4));
      expectTotalIsOne(r);
    });
  });

  group('Famous cases', () {
    test('Al-Umariyyatayn with husband', () {
      final r = calc(false, {HeirType.husband: 1, HeirType.father: 1, HeirType.mother: 1});
      expect(shareOf(r, HeirType.husband), Frac(1, 2));
      expect(shareOf(r, HeirType.mother), Frac(1, 6));
      expect(shareOf(r, HeirType.father), Frac(1, 3));
    });

    test('Al-Umariyyatayn with wife', () {
      final r = calc(true, {HeirType.wife: 1, HeirType.father: 1, HeirType.mother: 1});
      expect(shareOf(r, HeirType.wife), Frac(1, 4));
      expect(shareOf(r, HeirType.mother), Frac(1, 4));
      expect(shareOf(r, HeirType.father), Frac(1, 2));
    });

    test('Al-Mushtarakah', () {
      final r = calc(false, {
        HeirType.husband: 1,
        HeirType.mother: 1,
        HeirType.maternalBrother: 2,
        HeirType.fullBrother: 1,
      });
      expect(shareOf(r, HeirType.husband), Frac(1, 2));
      expect(shareOf(r, HeirType.mother), Frac(1, 6));
      expect(shareOf(r, HeirType.maternalBrother), Frac(2, 9));
      expect(shareOf(r, HeirType.fullBrother), Frac(1, 9));
      expect(r.specialCase, contains('มุชตะเราะกะฮ์'));
      expectTotalIsOne(r);
    });

    test('Al-Akdariyyah', () {
      final r = calc(false, {
        HeirType.husband: 1,
        HeirType.mother: 1,
        HeirType.grandfather: 1,
        HeirType.fullSister: 1,
      });
      expect(shareOf(r, HeirType.husband), Frac(9, 27));
      expect(shareOf(r, HeirType.mother), Frac(6, 27));
      expect(shareOf(r, HeirType.grandfather), Frac(8, 27));
      expect(shareOf(r, HeirType.fullSister), Frac(4, 27));
      expectTotalIsOne(r);
    });
  });

  group('Grandfather with siblings (Zayd)', () {
    test('gf + 1 full brother: muqasamah 1/2', () {
      final r = calc(true, {HeirType.grandfather: 1, HeirType.fullBrother: 1});
      expect(shareOf(r, HeirType.grandfather), Frac(1, 2));
      expect(shareOf(r, HeirType.fullBrother), Frac(1, 2));
    });

    test('gf + 3 full brothers: gf takes 1/3', () {
      final r = calc(true, {HeirType.grandfather: 1, HeirType.fullBrother: 3});
      expect(shareOf(r, HeirType.grandfather), Frac(1, 3));
      expect(shareOf(r, HeirType.fullBrother), Frac(2, 3));
    });

    test('husband + gf + full brother: muqasamah of the rest', () {
      final r = calc(false, {HeirType.husband: 1, HeirType.grandfather: 1, HeirType.fullBrother: 1});
      expect(shareOf(r, HeirType.husband), Frac(1, 2));
      expect(shareOf(r, HeirType.grandfather), Frac(1, 4));
      expect(shareOf(r, HeirType.fullBrother), Frac(1, 4));
    });

    test('mother + gf + full sister + paternal brother (\'addah)', () {
      final r = calc(true, {
        HeirType.mother: 1,
        HeirType.grandfather: 1,
        HeirType.fullSister: 1,
        HeirType.paternalBrother: 1,
      });
      expect(shareOf(r, HeirType.mother), Frac(1, 6));
      expect(shareOf(r, HeirType.grandfather), Frac(1, 3));
      expect(shareOf(r, HeirType.fullSister), Frac(1, 2));
      expect(r.blocked.map((b) => b.type), contains(HeirType.paternalBrother));
      expectTotalIsOne(r);
    });

    test('gf blocks maternal siblings', () {
      final r = calc(true, {HeirType.grandfather: 1, HeirType.maternalSister: 2});
      expect(shareOf(r, HeirType.grandfather), Frac.one);
      expect(r.blocked.map((b) => b.type), contains(HeirType.maternalSister));
    });
  });

  group('Al-Munasakhat', () {
    test('father dies, then one son dies before distribution', () {
      final chain = FaraidEngine.calculateChain(
        estate: 480000,
        root: const FaraidInput(deceasedMale: true, heirs: {HeirType.wife: 1, HeirType.son: 2}),
        laterDeaths: const [
          LaterDeath(
            fromStage: 0,
            heirType: HeirType.son,
            heirIndex: 1,
            heirs: {HeirType.mother: 1, HeirType.fullBrother: 1},
          ),
        ],
      );
      expect(chain.errors, isEmpty);
      expect(chain.stages.length, 2);
      final s1 = chain.stages[1];
      expect(s1.fractionOfOriginal, Frac(7, 16));
      expect(s1.estate, closeTo(210000, 0.001));
      expect(shareOf(s1.result, HeirType.mother), Frac(1, 3));
      expect(shareOf(s1.result, HeirType.fullBrother), Frac(2, 3));
      expect(chain.passedOn(0)[HeirType.son], {1: 1});
    });

    test('later death with own assets and invalid heir index', () {
      final chain = FaraidEngine.calculateChain(
        estate: 100000,
        root: const FaraidInput(deceasedMale: true, heirs: {HeirType.son: 1}),
        laterDeaths: const [
          LaterDeath(fromStage: 0, heirType: HeirType.son, heirIndex: 1, heirs: {HeirType.daughter: 1}, ownAssets: 50000),
          LaterDeath(fromStage: 0, heirType: HeirType.son, heirIndex: 2, heirs: {HeirType.daughter: 1}),
        ],
      );
      expect(chain.stages.length, 2);
      expect(chain.stages[1].estate, closeTo(150000, 0.001));
      expect(chain.errors.length, 1);
    });
  });

  group('Uncertain heirs (al-Haml, al-Mafqud)', () {
    test('fetus of the deceased, up to twins: heirs get their smallest share', () {
      final u = FaraidEngine.calculateUncertain(
        const FaraidInput(deceasedMale: true, heirs: {HeirType.wife: 1, HeirType.father: 1, HeirType.mother: 1}),
        [FaraidEngine.fetusScenarios(HeirType.son, HeirType.daughter, 2)],
      );
      expect(u.outcomes.length, 6); // stillborn, 1 boy, 1 girl, 2 boys, boy+girl, 2 girls
      expect(u.minPerPerson[HeirType.wife], Frac(1, 9)); // 2 daughters: 24 raised to 27
      expect(u.minPerPerson[HeirType.mother], Frac(4, 27));
      expect(u.minPerPerson[HeirType.father], Frac(4, 27));
      expect(u.reserved, Frac(16, 27));
      expect(u.paidNow(HeirType.wife) + u.paidNow(HeirType.mother) + u.paidNow(HeirType.father) + u.reserved, Frac.one);
    });

    test('one missing son: share held back until the ruling', () {
      final u = FaraidEngine.calculateUncertain(
        const FaraidInput(deceasedMale: true, heirs: {HeirType.wife: 1, HeirType.son: 1, HeirType.daughter: 1}),
        [FaraidEngine.missingScenarios(HeirType.son, 1)],
      );
      expect(u.outcomes.length, 2);
      expect(u.minPerPerson[HeirType.wife], Frac(1, 8));
      expect(u.minPerPerson[HeirType.son], Frac(7, 20));
      expect(u.minPerPerson[HeirType.daughter], Frac(7, 40));
      expect(u.reserved, Frac(7, 20));
    });

    test('missing son blocks the brother in one outcome, so the brother gets nothing yet', () {
      final u = FaraidEngine.calculateUncertain(
        const FaraidInput(deceasedMale: true, heirs: {HeirType.wife: 1, HeirType.fullBrother: 1}),
        [FaraidEngine.missingScenarios(HeirType.son, 1)],
      );
      expect(u.minPerPerson[HeirType.wife], Frac(1, 8));
      expect(u.minPerPerson[HeirType.fullBrother], Frac.zero);
      expect(u.reserved, Frac(7, 8));
    });

    test('fetus and missing heir together use every combination', () {
      final u = FaraidEngine.calculateUncertain(
        const FaraidInput(deceasedMale: true, heirs: {HeirType.wife: 1, HeirType.son: 1}),
        [FaraidEngine.fetusScenarios(HeirType.son, HeirType.daughter, 1), FaraidEngine.missingScenarios(HeirType.son, 1)],
      );
      expect(u.outcomes.length, 6);
      expect(u.minPerPerson[HeirType.son], Frac(7, 24)); // 3 sons alive: 7/8 / 3
    });
  });

  group('Simultaneous deaths (al-Gharqa)', () {
    test('each estate goes only to its own living heirs', () {
      final chain = FaraidEngine.calculateChain(
        estate: 1200000,
        root: const FaraidInput(deceasedMale: true, heirs: {HeirType.wife: 1, HeirType.daughter: 1, HeirType.fullBrother: 1}),
        simultaneous: const [
          SimultaneousDeath(
            label: 'ลูกชาย',
            isMale: true,
            heirs: {HeirType.wife: 1, HeirType.mother: 1, HeirType.fullSister: 1},
            ownAssets: 300000,
          ),
        ],
      );
      expect(chain.stages.length, 2);
      final first = chain.stages[0].result;
      expect(first.shareOf(HeirType.wife)!.share, Frac(1, 8));
      expect(first.shareOf(HeirType.daughter)!.share, Frac(1, 2));
      expect(first.shareOf(HeirType.fullBrother)!.share, Frac(3, 8));

      final son = chain.stages[1];
      expect(son.simultaneous, isTrue);
      expect(son.inherited, 0); // nothing from the father
      expect(son.estate, 300000);
      // 1/4 + 1/3 + 1/2 = 13/12, so the base 12 is raised to 13
      expect(son.result.shareOf(HeirType.wife)!.share, Frac(3, 13));
      expect(son.result.shareOf(HeirType.mother)!.share, Frac(4, 13));
      expect(son.result.shareOf(HeirType.fullSister)!.share, Frac(6, 13));
      expect(chain.passedOn(0), isEmpty);
    });
  });
}
