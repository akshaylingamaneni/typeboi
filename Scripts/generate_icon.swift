#!/usr/bin/env swift
import Cocoa

let sizes: [(CGFloat, String)] = [
    (16, "icon_16x16"),
    (32, "icon_16x16@2x"),
    (32, "icon_32x32"),
    (64, "icon_32x32@2x"),
    (128, "icon_128x128"),
    (256, "icon_128x128@2x"),
    (256, "icon_256x256"),
    (512, "icon_256x256@2x"),
    (512, "icon_512x512"),
    (1024, "icon_512x512@2x")
]

let rootDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let iconsetPath = rootDir.appendingPathComponent("Resources/AppBundle/AppIcon.iconset")

try? FileManager.default.removeItem(at: iconsetPath)
try! FileManager.default.createDirectory(at: iconsetPath, withIntermediateDirectories: true)

for (size, name) in sizes {
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let image = NSImage(size: rect.size)

    image.lockFocus()

    // Background gradient
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.25, alpha: 1.0),
        NSColor(calibratedRed: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
    ])!

    let path = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.05, dy: size * 0.05),
                            xRadius: size * 0.2, yRadius: size * 0.2)
    gradient.draw(in: path, angle: -90)

    // Keyboard symbol - white with full opacity for contrast
    let config = NSImage.SymbolConfiguration(pointSize: size * 0.45, weight: .medium)
        .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
    if let symbol = NSImage(systemSymbolName: "keyboard.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {
        let symbolSize = symbol.size
        let x = (size - symbolSize.width) / 2
        let y = (size - symbolSize.height) / 2
        symbol.draw(in: NSRect(x: x, y: y, width: symbolSize.width, height: symbolSize.height),
                    from: .zero, operation: .sourceOver, fraction: 1.0)
    }

    image.unlockFocus()

    let pngPath = iconsetPath.appendingPathComponent("\(name).png")
    if let tiff = image.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiff),
       let png = bitmap.representation(using: .png, properties: [:]) {
        try! png.write(to: pngPath)
    }
}

print("Created iconset at: \(iconsetPath.path)")
print("Run: iconutil -c icns \(iconsetPath.path)")
