import 'package:flutter_test/flutter_test.dart';
import 'package:ai_expense_tracker/widgets/calculator_numpad.dart';

void main() {
  group('CalculatorNumpad math evaluation tests', () {
    test('Simple addition', () {
      final res = CalculatorNumpad.evaluateExpression('50+25');
      expect(res, 75.0);
    });

    test('Multiplication with precedence', () {
      final res = CalculatorNumpad.evaluateExpression('10+5×2');
      expect(res, 20.0);
    });

    test('Division and decimals', () {
      final res = CalculatorNumpad.evaluateExpression('100÷4');
      expect(res, 25.0);
    });

    test('Subtraction with decimal numbers', () {
      final res = CalculatorNumpad.evaluateExpression('120.50-20.50');
      expect(res, 100.0);
    });

    test('Trailing operator cleanup before eval', () {
      final res = CalculatorNumpad.evaluateExpression('80+');
      expect(res, 80.0);
    });
  });
}
