#!/usr/bin/env swift
import Cocoa

let size: CGFloat = 128
let rootDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let outputPath = rootDir.appendingPathComponent("Resources/AppBundle/arrow.png")

let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

// Transparent background - draw chevron arrow
let arrowColor = NSColor.white.withAlphaComponent(0.5)
arrowColor.setStroke()

let arrowPath = NSBezierPath()
let centerX = size / 2
let centerY = size / 2
let arrowWidth: CGFloat = 35
let arrowHeight: CGFloat = 50

arrowPath.move(to: NSPoint(x: centerX - arrowWidth/2, y: centerY + arrowHeight/2))
arrowPath.line(to: NSPoint(x: centerX + arrowWidth/2, y: centerY))
arrowPath.line(to: NSPoint(x: centerX - arrowWidth/2, y: centerY - arrowHeight/2))
arrowPath.lineWidth = 8
arrowPath.lineCapStyle = .round
arrowPath.lineJoinStyle = .round
arrowPath.stroke()

image.unlockFocus()

if let tiff = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiff),
   let png = bitmap.representation(using: .png, properties: [:]) {
    try! png.write(to: outputPath)
    print("Created arrow icon at: \(outputPath.path)")
}
