import 'collection_layout.dart';
import 'dial_layout.dart';
import 'direction_pad_layout.dart';
import 'element_grid_layout.dart';
import 'empty_layout.dart';
import 'group_layout.dart';
import 'linear_layout.dart';
import 'touch_surface_layout.dart';
import 'unavailable_layout.dart';

/// One method per layout; implementers are checked for completeness.
abstract interface class RemoteLayoutVisitor<T> {
  T visitCollection(CollectionLayout layout);
  T visitDial(DialLayout layout);
  T visitDirectionPad(DirectionPadLayout layout);
  T visitElementGrid(ElementGridLayout layout);
  T visitEmpty(EmptyLayout layout);
  T visitGroup(GroupLayout layout);
  T visitLinear(LinearLayout layout);
  T visitTouchSurface(TouchSurfaceLayout layout);
  T visitUnavailable(UnavailableLayout layout);
}
