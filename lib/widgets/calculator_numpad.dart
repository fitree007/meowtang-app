import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme_model.dart';

class CalculatorNumpad extends StatelessWidget {
  final String rawInput;
  final ValueChanged<String> onInputChanged;
  final VoidCallback onSave;
  final AppThemeModel currentTheme;
  final String saveButtonText;

  const CalculatorNumpad({
    super.key,
    required this.rawInput,
    required this.onInputChanged,
    required this.onSave,
    required this.currentTheme,
    this.saveButtonText = 'บันทึกรายการ',
  });

  // EVALUATE MATH EXPRESSION
  static double? evaluateExpression(String input) {
    if (input.trim().isEmpty) return 0.0;
    try {
      // Replace display operators
      String sanitized = input.replaceAll('×', '*').replaceAll('÷', '/').replaceAll(' ', '');
      if (sanitized.isEmpty) return 0.0;

      // Strip trailing operator if user didn't finish typing next number
      while (sanitized.isNotEmpty && (sanitized.endsWith('+') || sanitized.endsWith('-') || sanitized.endsWith('*') || sanitized.endsWith('/'))) {
        sanitized = sanitized.substring(0, sanitized.length - 1);
      }
      if (sanitized.isEmpty) return 0.0;

      // Simple parser for + - * /
      final tokens = <dynamic>[];
      String currentNum = '';

      for (int i = 0; i < sanitized.length; i++) {
        final ch = sanitized[i];
        if (ch == '+' || ch == '-' || ch == '*' || ch == '/') {
          if (currentNum.isNotEmpty) {
            tokens.add(double.tryParse(currentNum) ?? 0.0);
            currentNum = '';
          } else if (ch == '-' && (i == 0 || sanitized[i - 1] == '*' || sanitized[i - 1] == '/')) {
            currentNum += ch;
            continue;
          }
          tokens.add(ch);
        } else {
          currentNum += ch;
        }
      }
      if (currentNum.isNotEmpty) {
        tokens.add(double.tryParse(currentNum) ?? 0.0);
      }

      if (tokens.isEmpty) return 0.0;

      // First pass: * and /
      final pass1 = <dynamic>[];
      int idx = 0;
      while (idx < tokens.length) {
        final token = tokens[idx];
        if (token == '*' || token == '/') {
          final prev = pass1.removeLast() as double;
          final next = tokens[idx + 1] as double;
          if (token == '*') {
            pass1.add(prev * next);
          } else {
            pass1.add(next != 0 ? prev / next : 0.0);
          }
          idx += 2;
        } else {
          pass1.add(token);
          idx++;
        }
      }

      // Second pass: + and -
      double result = pass1.first as double;
      idx = 1;
      while (idx < pass1.length) {
        final op = pass1[idx] as String;
        final next = pass1[idx + 1] as double;
        if (op == '+') {
          result += next;
        } else if (op == '-') {
          result -= next;
        }
        idx += 2;
      }

      return result;
    } catch (_) {
      return null;
    }
  }

  void _handleKey(String key) {
    HapticFeedback.selectionClick();
    String updated = rawInput;

    if (key == 'C') {
      onInputChanged('0');
      return;
    }

    if (key == 'BACKSPACE') {
      if (updated.length <= 1 || (updated.length == 2 && updated.startsWith('-'))) {
        onInputChanged('0');
      } else {
        onInputChanged(updated.substring(0, updated.length - 1));
      }
      return;
    }

    if (key == '=') {
      final evaluated = evaluateExpression(updated);
      if (evaluated != null) {
        if (evaluated == evaluated.roundToDouble()) {
          onInputChanged(evaluated.toInt().toString());
        } else {
          onInputChanged(evaluated.toStringAsFixed(2));
        }
      }
      return;
    }

    // Number keys and operators
    if (updated == '0' && (key != '.' && key != '+' && key != '-' && key != '×' && key != '÷')) {
      updated = key;
    } else {
      // Prevent consecutive operators
      final isLastOperator = updated.isNotEmpty &&
          (updated.endsWith('+') || updated.endsWith('-') || updated.endsWith('×') || updated.endsWith('÷'));

      if (isLastOperator && (key == '+' || key == '-' || key == '×' || key == '÷')) {
        updated = updated.substring(0, updated.length - 1) + key;
      } else {
        updated += key;
      }
    }

    onInputChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = currentTheme.isDark;
    final numBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final opBg = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    final textCol = currentTheme.textColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      decoration: BoxDecoration(
        color: currentTheme.surfaceBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: = , ⌫ , บันทึกรายการ (2 cols)
          Row(
            children: [
              _buildKey(
                child: const Text('=', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                bg: opBg,
                color: textCol,
                onTap: () => _handleKey('='),
              ),
              const SizedBox(width: 6),
              _buildKey(
                child: const Icon(Icons.backspace_outlined, size: 18),
                bg: opBg,
                color: textCol,
                onTap: () => _handleKey('BACKSPACE'),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      onSave();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: Text(
                      saveButtonText,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Row 2: 7, 8, 9, +
          Row(
            children: [
              _buildKey(child: const Text('7', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), bg: numBg, color: textCol, onTap: () => _handleKey('7')),
              const SizedBox(width: 6),
              _buildKey(child: const Text('8', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), bg: numBg, color: textCol, onTap: () => _handleKey('8')),
              const SizedBox(width: 6),
              _buildKey(child: const Text('9', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), bg: numBg, color: textCol, onTap: () => _handleKey('9')),
              const SizedBox(width: 6),
              _buildKey(child: const Text('+', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), bg: opBg, color: textCol, onTap: () => _handleKey('+')),
            ],
          ),
          const SizedBox(height: 6),

          // Row 3: 4, 5, 6, -
          Row(
            children: [
              _buildKey(child: const Text('4', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), bg: numBg, color: textCol, onTap: () => _handleKey('4')),
              const SizedBox(width: 6),
              _buildKey(child: const Text('5', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), bg: numBg, color: textCol, onTap: () => _handleKey('5')),
              const SizedBox(width: 6),
              _buildKey(child: const Text('6', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), bg: numBg, color: textCol, onTap: () => _handleKey('6')),
              const SizedBox(width: 6),
              _buildKey(child: const Text('-', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)), bg: opBg, color: textCol, onTap: () => _handleKey('-')),
            ],
          ),
          const SizedBox(height: 6),

          // Row 4: 1, 2, 3, ×
          Row(
            children: [
              _buildKey(child: const Text('1', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), bg: numBg, color: textCol, onTap: () => _handleKey('1')),
              const SizedBox(width: 6),
              _buildKey(child: const Text('2', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), bg: numBg, color: textCol, onTap: () => _handleKey('2')),
              const SizedBox(width: 6),
              _buildKey(child: const Text('3', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), bg: numBg, color: textCol, onTap: () => _handleKey('3')),
              const SizedBox(width: 6),
              _buildKey(child: const Text('×', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), bg: opBg, color: textCol, onTap: () => _handleKey('×')),
            ],
          ),
          const SizedBox(height: 6),

          // Row 5: ., 0, C, ÷
          Row(
            children: [
              _buildKey(child: const Text('.', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)), bg: numBg, color: textCol, onTap: () => _handleKey('.')),
              const SizedBox(width: 6),
              _buildKey(child: const Text('0', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), bg: numBg, color: textCol, onTap: () => _handleKey('0')),
              const SizedBox(width: 6),
              _buildKey(child: const Text('C', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))), bg: numBg, color: const Color(0xFFEF4444), onTap: () => _handleKey('C')),
              const SizedBox(width: 6),
              _buildKey(child: const Text('÷', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), bg: opBg, color: textCol, onTap: () => _handleKey('÷')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey({
    required Widget child,
    required Color bg,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: SizedBox(
        height: 44,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Center(
              child: DefaultTextStyle(
                style: TextStyle(
                  color: color,
                  fontFamily: 'Prompt',
                ),
                child: IconTheme(
                  data: IconThemeData(color: color),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
