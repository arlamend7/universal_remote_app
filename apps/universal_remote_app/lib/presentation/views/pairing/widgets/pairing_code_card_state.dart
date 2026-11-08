import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pairing_code_card.dart';

class PairingCodeCardState extends State<PairingCodeCard> {
  final _code = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      24,
      24,
      24,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Enter the code on your TV',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        _field(),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: const Text('Pair TV'),
        ),
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Cancel connection'),
        ),
      ],
    ),
  );

  Widget _field() => TextField(
    controller: _code,
    autofocus: true,
    autocorrect: false,
    textCapitalization: TextCapitalization.characters,
    textInputAction: TextInputAction.done,
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]'))],
    maxLength: 6,
    decoration: InputDecoration(
      labelText: 'TV pairing code',
      errorText: _error,
    ),
    onSubmitted: (_) => _submit(),
  );

  Future<void> _submit() async {
    if (_submitting) {
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
