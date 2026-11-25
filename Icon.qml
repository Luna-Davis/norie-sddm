import QtQuick
import QtQuick.Shapes

// Stroke icon drawn from a 24x24 SVG path.
Item {
    id: icon

    property string path: ""
    property color color: "white"
    property real size: 22
    property real strokeWidth: 2

    width: size
    height: size

    Shape {
        width: 24
        height: 24
        scale: icon.size / 24
        transformOrigin: Item.TopLeft
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            strokeColor: icon.color
            strokeWidth: icon.strokeWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathSvg { path: icon.path }
        }
    }
}
