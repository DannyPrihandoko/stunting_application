// lib/pages/change_pin_page.dart
import 'package:flutter/material.dart';
import 'package:stunting_application/services/pin_service.dart';

enum ChangePinStep { oldPin, newPin, confirmPin }

class ChangePinPage extends StatefulWidget {
  const ChangePinPage({super.key});

  @override
  State<ChangePinPage> createState() => _ChangePinPageState();
}

class _ChangePinPageState extends State<ChangePinPage> {
  ChangePinStep _currentStep = ChangePinStep.oldPin;
  String _enteredPin = '';
  String _newPin = '';
  String _errorMessage = '';
  final int _pinLength = 4;
  final _pinService = PinService();

  void _onNumberPressed(String number) {
    if (_enteredPin.length >= _pinLength) return;
    setState(() {
      _errorMessage = '';
      _enteredPin += number;
    });

    if (_enteredPin.length == _pinLength) {
      _processPin();
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

  Future<void> _processPin() async {
    switch (_currentStep) {
      case ChangePinStep.oldPin:
        final isValid = await _pinService.verifyPin(_enteredPin);
        if (isValid) {
          setState(() {
            _currentStep = ChangePinStep.newPin;
            _enteredPin = '';
          });
        } else {
          setState(() {
            _errorMessage = 'PIN lama salah.';
            _enteredPin = '';
          });
        }
        break;
      case ChangePinStep.newPin:
        setState(() {
          _newPin = _enteredPin;
          _currentStep = ChangePinStep.confirmPin;
          _enteredPin = '';
        });
        break;
      case ChangePinStep.confirmPin:
        if (_enteredPin == _newPin) {
          await _pinService.setPin(_newPin);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PIN berhasil diubah!')),
            );
            Navigator.of(context).pop();
          }
        } else {
          setState(() {
            _errorMessage = 'PIN tidak cocok. Ulangi PIN baru.';
            _currentStep = ChangePinStep.newPin;
            _enteredPin = '';
            _newPin = '';
          });
        }
        break;
    }
  }

  String _getTitle() {
    switch (_currentStep) {
      case ChangePinStep.oldPin:
        return 'Masukkan PIN Lama';
      case ChangePinStep.newPin:
        return 'Masukkan PIN Baru';
      case ChangePinStep.confirmPin:
        return 'Konfirmasi PIN Baru';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ganti PIN Admin'),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Text(_getTitle(), style: const TextStyle(fontSize: 16)),
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  // (Salin widget _buildPinDots, _buildNumpad, _buildNumberButton, dan _buildBackspaceButton
  // dari PinEntryPage ke sini untuk tampilan yang konsisten)

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
            const SizedBox(width: 70, height: 70),
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