enum RemoteBorderShape {
  square('Square', 0),
  small('Small rounded square', 4),
  normal('Normal rounded square', 8),
  rounded('Rounded square', 12),
  circle('Circle border', 1000);

  const RemoteBorderShape(this.label, this.radius);

  final String label;
  final double radius;
}
