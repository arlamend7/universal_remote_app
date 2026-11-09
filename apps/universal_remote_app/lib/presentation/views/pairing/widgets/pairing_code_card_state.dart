import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remote_ui/remote_ui.dart';

import 'pairing_code_card.dart';
import 'pairing_code_slots.dart';

class PairingCodeCardState extends State<PairingCodeCard> {
  final _code = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) => AppSheet(
    title: 'Pair TV',
    subtitle: 'Enter the six characters shown on ${widget.deviceName}.',
    onClose: widget.onCancel,
    child: _codeEntry(),
    footer: _actions(),
  );

  Widget _actions() => AppSheetActions(
    secondary: OutlinedButton(
      onPressed: widget.onCancel,
      child: const Text('Cancel connection'),
    ),
    primary: FilledButton(
      onPressed: _submitting ? null : _submit,
      child: const Text('Connect'),
    ),
  );

  Widget _codeEntry() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            ValueListenableBuilder(
              valueListenable: _code,
              builder: (_, value, _) => PairingCodeSlots(code: value.text),
            ),
            Positioned.fill(child: _field()),
          ],
        ),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    ),
  );

  Widget _field() => Semantics(label: 'TV pairing code', child: _input());

  Widget _input() => TextField(
    controller: _code,
    autofocus: true,
    textAlign: TextAlign.center,
    showCursor: false,
    style: const TextStyle(
      fontSize: 24,
      color: Colors.transparent,
      fontWeight: FontWeight.w700,
      letterSpacing: 8,
    ),
    autocorrect: false,
    textCapitalization: TextCapitalization.characters,
    textInputAction: TextInputAction.done,
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]'))],
    maxLength: 6,
    decoration: const InputDecoration(
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      counterText: '',
    ),
    onSubmitted: (_) => _submit(),
  );

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    if (_code.text.length != 6) {
      setState(() => _error = 'Enter all six characters.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final accepted = await widget.receiver.submitPairingCode(_code.text);
    if (!mounted || accepted) {
      return;
    }
    setState(() {
      _submitting = false;
      _error = 'Check the six characters on your TV.';
    });
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }
}
