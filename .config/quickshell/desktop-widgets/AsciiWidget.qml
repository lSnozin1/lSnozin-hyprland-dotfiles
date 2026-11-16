import QtQuick
import Quickshell.Io

DesktopPanel {
    id: widget

    property string artPath: ""
    property string fontFamily: "monospace"
    property int fontSize: 10
    property real lineHeightFactor: 1.0
    property real artOpacity: 0.95
    property int trimLeft: 0
    property int trimRight: 0

    contentWidth: art.implicitWidth - trimLeft - trimRight
    contentHeight: art.implicitHeight

    FileView {
        id: artFile
        path: widget.artPath
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
    }

    Text {
        id: art
        x: -widget.trimLeft
        text: artFile.text()
        textFormat: Text.PlainText
        color: widget.accentColor
        opacity: widget.artOpacity
        font.family: widget.fontFamily
        font.pixelSize: widget.fontSize
        lineHeight: widget.lineHeightFactor
        lineHeightMode: Text.ProportionalHeight
    }
}