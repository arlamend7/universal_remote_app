/// A valid footprint proposed while resizing: [width] by [height] cells, at
/// [dx], [dy] cells from the item's current place.
typedef ResizeCandidate = ({int dx, int dy, int width, int height});
