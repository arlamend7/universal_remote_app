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

  test('clearing a color through copyWith removes it', () {
    final style = const RemoteItemStyle(background: 1)
        .copyWith(background: null);
    expect(style.background, isNull);
  });
}
