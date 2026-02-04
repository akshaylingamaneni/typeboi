#!/usr/bin/env swift
import Cocoa

// @2x for Retina - matches window-size 540x380
let width: CGFloat = 1080
let height: CGFloat = 760

let rootDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let outputPath = rootDir.appendingPathComponent("Resources/AppBundle/dmg_background.png")

let image = NSImage(size: NSSize(width: width, height: height))
image.lockFocus()

// Light background like Codex
let bgColor = NSColor(calibratedWhite: 0.95, alpha: 1.0)
bgColor.setFill()
NSRect(x: 0, y: 0, width: width, height: height).fill()

// Draw chevron arrow pointing right
let arrowColor = NSColor(calibratedWhite: 0.3, alpha: 1.0)
arrowColor.setStroke()

let arrowPath = NSBezierPath()
let centerX = width / 2
let centerY = height / 2 + 40  // Slightly above center to account for labels
let arrowSize: CGFloat = 60

arrowPath.move(to: NSPoint(x: centerX - arrowSize/3, y: centerY + arrowSize/2))
arrowPath.line(to: NSPoint(x: centerX + arrowSize/3, y: centerY))
arrowPath.line(to: NSPoint(x: centerX - arrowSize/3, y: centerY - arrowSize/2))
arrowPath.lineWidth = 12
arrowPath.lineCapStyle = .round
arrowPath.lineJoinStyle = .round
arrowPath.stroke()

image.unlockFocus()

if let tiff = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiff),
   let png = bitmap.representation(using: .png, properties: [:]) {
    try! png.write(to: outputPath)
    print("Created DMG background at: \(outputPath.path)")
}
