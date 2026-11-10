final class GridPageSize {
  const GridPageSize(this.rows, this.cellSize);

  final int rows;
  final double cellSize;

  Map<String, Object> toJson() => {'rows': rows, 'cellSize': cellSize};

  factory GridPageSize.fromJson(Map<String, dynamic> json) =>
      GridPageSize(json['rows'] as int, (json['cellSize'] as num).toDouble());
}
