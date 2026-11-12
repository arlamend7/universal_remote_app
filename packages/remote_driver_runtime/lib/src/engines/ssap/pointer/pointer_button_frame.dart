/// Pointer-socket button frame; frames end in a blank line, independently of
/// SSAP JSON framing.
String pointerButtonFrame(String name) => 'type:button\nname:$name\n\n';

/// Button names the pointer socket accepts; integration mappings may only
/// choose from these upper-case tokens.
final pointerButtonName = RegExp(r'^[A-Z0-9_]{1,32}$');
