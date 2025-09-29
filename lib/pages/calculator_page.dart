import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final _formKey = GlobalKey<FormState>();
  final _aCtrl = TextEditingController();
  final _bCtrl = TextEditingController();

  String _op = '+';
  String _result = '-';

  // Style fallback agar simbol × dan ÷ tidak jadi kotak silang
  static const _symbolStyle = TextStyle(
    fontSize: 16,
    fontFamilyFallback: ['Roboto', 'Noto Sans Symbols 2', 'Noto Sans'],
  );

  @override
  void dispose() {
    _aCtrl.dispose();
    _bCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final a = double.parse(_aCtrl.text.replaceAll(',', '.'));
    final b = double.parse(_bCtrl.text.replaceAll(',', '.'));

    double res;
    switch (_op) {
      case '+':
        res = a + b;
        break;
      case '-':
        res = a - b;
        break;
      case '×':
        res = a * b;
        break;
      case '÷':
        if (b == 0) {
          _showSnack('Pembagian dengan nol tidak diperbolehkan.');
          return;
        }
        res = a / b;
        break;
      default:
        res = 0;
    }

    setState(() {
      _result = _prettyNumber(res);
    });
  }

  void _reset() {
    _aCtrl.clear();
    _bCtrl.clear();
    setState(() {
      _op = '+';
      _result = '-';
    });
  }

  String _prettyNumber(double v) {
    final s = v.toStringAsFixed(8);
    final trimmed = s.replaceFirst(RegExp(r'\.?0+$'), '');
    return trimmed;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text('Kalkulator - SITUNTAS'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Text(
              'Masukkan dua angka, pilih operasi, lalu tekan Hitung.',
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),

          // FORM INPUT
          Form(
            key: _formKey,
            child: Column(
              children: [
                _numberField(
                  controller: _aCtrl,
                  label: 'Angka 1',
                ),
                const SizedBox(height: 12),
                _numberField(
                  controller: _bCtrl,
                  label: 'Angka 2',
                ),
                const SizedBox(height: 12),

                // DROPDOWN OPERASI
                Row(
                  children: [
                    const Text(
                      'Operasi:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _op,
                      items: const [
                        DropdownMenuItem(
                          value: '+',
                          child: Text('+', style: _symbolStyle),
                        ),
                        // konsisten pakai '-' biasa (hyphen)
                        DropdownMenuItem(
                          value: '-',
                          child: Text('-', style: _symbolStyle),
                        ),
                        DropdownMenuItem(
                          value: '×',
                          child: Text('×', style: _symbolStyle),
                        ),
                        DropdownMenuItem(
                          value: '÷',
                          child: Text('÷', style: _symbolStyle),
                        ),
                      ],
                      onChanged: (v) => setState(() => _op = v ?? '+'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // TOMBOL AKSI
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _calculate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.calculate),
                        label: const Text(
                          'Hitung',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _reset,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.orange.shade300),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // HASIL
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Hasil',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  _result,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.\-]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'Tidak boleh kosong';
        }
        final parsed = double.tryParse(v.replaceAll(',', '.'));
        if (parsed == null) {
          return 'Masukkan angka yang valid';
        }
        return null;
      },
    );
  }
}
