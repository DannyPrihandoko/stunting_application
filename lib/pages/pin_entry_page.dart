// lib/pages/pin_entry_page.dart
import 'package:flutter/material.dart';
import 'package:stunting_application/services/pin_service.dart';
import 'change_pin_page.dart';

class PinEntryPage extends StatefulWidget {
  const PinEntryPage({super.key});

  @override
  State<PinEntryPage> createState() => _PinEntryPageState();
}

class _PinEntryPageState extends State<PinEntryPage> {
  String _enteredPin = '';
  final int _pinLength = 4;
  final _pinService = PinService();
  bool _isVerifying = false;
  String _errorMessage = '';

  void _onNumberPressed(String number) {
    if (_isVerifying || _enteredPin.length >= _pinLength) return;
    setState(() {
      _errorMessage = '';
      _enteredPin += number;
    });
    if (_enteredPin.length == _pinLength) {
      _verifyPin();
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _errorMessage = '';
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    setState(() => _isVerifying = true);
    final isValid = await _pinService.verifyPin(_enteredPin);

    if (mounted) {
      if (isValid) {
        Navigator.pushReplacementNamed(context, '/srs-history');
      } else {
        setState(() {
          _errorMessage = 'PIN salah, coba lagi.';
          _enteredPin = '';
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Masukkan PIN Admin'),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const Text(
              'Masukkan PIN untuk mengakses riwayat',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            _buildPinDots(),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage,
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 14),
              ),
            ],
            const Spacer(),
            _buildNumpad(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChangePinPage()),
                  );
                },
                child: const Text('Ganti PIN'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < _enteredPin.length
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
          ),
        );
      }),
    );
  }

  Widget _buildNumpad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['1', '2', '3'].map((e) => _buildNumberButton(e)).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6'].map((e) => _buildNumberButton(e)).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9'].map((e) => _buildNumberButton(e)).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 70, height: 70), // Placeholder
            _buildNumberButton('0'),
            _buildBackspaceButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberButton(String number) {
    return SizedBox(
      width: 70,
      height: 70,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: Colors.grey.shade200,
          shape: const CircleBorder(),
        ),
        onPressed: () => _onNumberPressed(number),
        child: Text(
          number,
          style: const TextStyle(fontSize: 28, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return SizedBox(
      width: 70,
      height: 70,
      child: IconButton(
        onPressed: _onBackspacePressed,
        icon: const Icon(Icons.backspace_outlined),
        iconSize: 28,
        color: Colors.grey.shade700,
      ),
    );
  }
}