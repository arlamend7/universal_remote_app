import 'package:flutter_test/flutter_test.dart';
import 'package:remote_ui/remote_ui.dart';

void main() {
  test('item style stores border and corner choices and omits defaults', () {
    expect(const RemoteItemStyle().isDefault, isTrue);
    expect(const RemoteItemStyle().toJson(), isEmpty);

    final style = const RemoteItemStyle().copyWith(
      background: 0xff243531,
      showBorder: true,
      borderColor: 0xffbce4cd,
      borderWidth: 3,
      cornerRadius: 0,
    );
    final restored = RemoteItemStyle.fromJson(style.toJson());
    expect(restored.background, 0xff243531);
    expect(restored.showBorder, isTrue);
    expect(restored.borderColor, 0xffbce4cd);
    expect(restored.borderWidth, 3);
    expect(restored.isRounded, isFalse);
    expect(restored.isDefault, isFalse);
  });

  test(
    'child overrides preserve saved icon styles and reset labels independently',
    () {
      final old = RemoteElementStyle.fromJson({
        'iconSize': 30,
        'foreground': 0xff336699,
      });
      final styled = old.copyWith(
        label: 'Sound level',
        visible: false,
        showLabel: false,
        showOfflineIndicator: true,
        borderWidth: 2,
        cornerRadius: 10,
      );
      final restored = RemoteElementStyle.fromJson(styled.toJson());
      expect(restored.label, 'Sound level');
      expect(restored.visible, isFalse);
      expect(restored.showLabel, isFalse);
      expect(restored.showOfflineIndicator, isTrue);
      expect(restored.borderWidth, 2);
      expect(restored.cornerRadius, 10);
      expect(restored.iconSize, 30);
      expect(restored.foreground, 0xff336699);
      expect(restored.copyWith(label: '').toJson(), isNot(contains('label')));
      expect(old.visible, isTrue);
    },
  );

  test('label visibility can inherit the definition or explicitly opt in', () {
    final inherited = RemoteElementStyle.fromJson({'radius': 8});
    expect(inherited.showLabel, isNull);
    expect(inherited.toJson(), isNot(contains('showLabel')));
    final shown = inherited.copyWith(showLabel: true);
    expect(RemoteElementStyle.fromJson(shown.toJson()).showLabel, isTrue);
  });

  test('clearing a color through copyWith removes it', () {
    final style = const RemoteItemStyle(background: 1)
        .copyWith(background: null);
    expect(style.background, isNull);
  });
}
