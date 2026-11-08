import 'package:flutter/foundation.dart';
import 'package:remote_core/remote_core.dart';

import '../definitions/remote_item_registry.dart';
import '../functions/default_remote_grid.dart';
import '../layout/grid_arrangement.dart';
import '../layout/grid_geometry.dart';
import '../layout/models/enums/editor_mode.dart';
import '../layout/models/grid_item.dart';
import '../layout/models/grid_layout.dart';
import 'device_grids_controller.dart';

final class GridEditorViewModel extends ChangeNotifier {
  GridEditorViewModel(
    this.grids,
    this.device, {
    GridLayout? initial,
    this.columns = 4,
    this.maxRows = 128,
    this.reservedRows = 0,
  }) : draft = initial ?? grids.forDevice(device) ?? defaultRemoteGrid();
  final DeviceGridsController grids;
  final RemoteDevice device;
  final int columns, maxRows, reservedRows;
  GridLayout draft;
  EditorMode mode = EditorMode.edit;
  void setMode(EditorMode value) {
    mode = value;
    notifyListeners();
  }

  final _undo = <GridLayout>[];
  final _redo = <GridLayout>[];
  String? selected;
  String? error;
  bool saving = false;
  int extraRows = 0;
  void extend() {
    extraRows += 8;
    notifyListeners();
  }

  bool _disposed = false;
  int _sequence = 0;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  GridItem? get selection =>
      draft.items.where((item) => item.id == selected).firstOrNull;
  void select(String? id) {
    selected = id;
    notifyListeners();
  }

  void change(GridLayout next) {
    if (saving || _disposed) {
      return;
    }
    if (next.items.any((item) => item.y < reservedRows) ||
        !GridGeometry.valid(next.items, columns: columns, rows: maxRows)) {
      error = 'That position or size overlaps a control or does not fit.';
      notifyListeners();
      return;
    }
    _undo.add(draft);
    if (_undo.length > 50) {
      _undo.removeAt(0);
    }
    _redo.clear();
    draft = next;
    error = null;
    notifyListeners();
  }

  GridItem? add(String definitionId) {
    final definition = RemoteItemRegistry.resolve(definitionId);
    final item = GridGeometry.place(
      GridItem(
        id: 'widget-${DateTime.now().microsecondsSinceEpoch}-${_sequence++}',
        definitionId: definitionId,
        x: 0,
        y: 0,
        w: definition.width > columns ? columns : definition.width,
        h: definition.height,
      ),
      draft.items,
      columns: columns,
      rows: maxRows,
      startRow: reservedRows,
    );
    if (item == null) {
      error = 'No room for this control. Resize the group or free some space.';
      notifyListeners();
      return null;
    }
    selected = item.id;
    change(GridLayout([...draft.items, item]));
    return item;
  }

  void update(GridItem item) => change(
    GridLayout(draft.items.map((old) => old.id == item.id ? item : old)),
  );
  void replace(GridItem item) {
    final next = GridArrangement.replace(
      draft,
      item,
      columns: columns,
      rows: maxRows,
      reservedRows: reservedRows,
    );
    if (next == null) {
      error = 'That size will not fit. Try a smaller size or make the group bigger.';
      notifyListeners();
      return;
    }
    change(next);
  }

  void resize(GridItem item, int width, int height) =>
      replace(item.copy(w: width, h: height));
  void remove(String id) {
    selected = null;
    change(GridLayout(draft.items.where((item) => item.id != id)));
  }

  void duplicate(GridItem item) {
    final clone = item.copy(
      id: 'copy-${DateTime.now().microsecondsSinceEpoch}-${_sequence++}',
    );
    final placed = GridGeometry.place(
      clone,
      draft.items,
      columns: columns,
      rows: maxRows,
      startRow: reservedRows,
    );
    if (placed == null) {
      error = 'No room for a copy.';
      notifyListeners();
      return;
    }
    selected = placed.id;
    change(GridLayout([...draft.items, placed]));
  }

  void undo() {
    if (!canUndo || saving) {
      return;
    }
    _redo.add(draft);
    draft = _undo.removeLast();
    selected = null;
    error = null;
    notifyListeners();
  }

  void redo() {
    if (!canRedo || saving) {
      return;
    }
    _undo.add(draft);
    draft = _redo.removeLast();
    selected = null;
    error = null;
    notifyListeners();
  }

  void reset() => change(maxRows < 128 ? GridLayout([]) : defaultRemoteGrid());
  Future<bool> save() async {
    if (saving) {
      return false;
    }
    saving = true;
    notifyListeners();
    try {
      await grids.save(device, draft);
      return true;
    } catch (_) {
      error = 'Could not save this layout. Please retry.';
      return false;
    } finally {
      if (!_disposed) {
        saving = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
