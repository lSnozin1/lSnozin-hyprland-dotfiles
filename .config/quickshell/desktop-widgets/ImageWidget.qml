import QtQuick

DesktopPanel {
    id: widget

    property string imagePath: ""
    // Image width in pixels at zoom 1.0
    property int baseWidth: 300

    contentWidth: baseWidth
    contentHeight: img.implicitWidth > 0 ? baseWidth * img.implicitHeight / img.implicitWidth : baseWidth

    Image {
        id: img
        width: widget.contentWidth
        height: widget.contentHeight
        source: widget.imagePath !== "" ? "file://" + widget.imagePath : ""
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        asynchronous: true
    }
}