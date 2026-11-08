/// Grid cells an item occupies by default, and the least it may be resized to.
final class RemoteItemSize {
  const RemoteItemSize(
    this.width,
    this.height, {
    int? minimumWidth,
    int? minimumHeight,
  }) : minimumWidth = minimumWidth ?? width,
       minimumHeight = minimumHeight ?? height;

  final int width, height, minimumWidth, minimumHeight;
}
