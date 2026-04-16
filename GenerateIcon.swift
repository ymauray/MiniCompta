#!/usr/bin/env swift

import AppKit
import CoreGraphics

let size: CGFloat = 1024
let outputPath = "Sources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"

// 1. Créer un contexte Core Graphics SANS alpha (opaque)
guard let ctx = CGContext(
    data: nil,
    width: Int(size),
    height: Int(size),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue // Pas d'alpha
) else {
    print("Impossible de créer le contexte CG")
    exit(1)
}

// 2. Dessiner
let colors = [
    CGColor(red: 0.12, green: 0.42, blue: 0.95, alpha: 1),
    CGColor(red: 0.48, green: 0.18, blue: 0.92, alpha: 1)
] as CFArray
let locations: [CGFloat] = [0, 1]
guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) else {
    exit(1)
}

ctx.drawLinearGradient(
    gradient,
    start: CGPoint(x: size * 0.1, y: size),
    end: CGPoint(x: size * 0.9, y: 0),
    options: []
)

// Cercles
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.08))
ctx.fillEllipse(in: CGRect(x: size * 0.52, y: size * 0.52, width: size * 0.65, height: size * 0.65))
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.05))
ctx.fillEllipse(in: CGRect(x: -size * 0.15, y: -size * 0.15, width: size * 0.6, height: size * 0.6))

// 3. Utiliser NSGraphicsContext pour le texte (plus facile)
// On doit wrapper notre CGContext dans un NSGraphicsContext
let nsContext = NSGraphicsContext(cgContext: ctx, flipped: false)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = nsContext

let paraStyle = NSMutableParagraphStyle()
paraStyle.alignment = .center

let attrsMini: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 150, weight: .black),
    .foregroundColor: NSColor(white: 1, alpha: 1.0),
    .paragraphStyle: paraStyle,
    .kern: 8.0
]

let attrsCompta: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 118, weight: .bold),
    .foregroundColor: NSColor(white: 1, alpha: 1.0),
    .paragraphStyle: paraStyle,
    .kern: 8.0
]

let labelMini   = NSAttributedString(string: "MINI",   attributes: attrsMini)
let labelCompta = NSAttributedString(string: "COMPTA", attributes: attrsCompta)

let miniSize   = labelMini.size()
let comptaSize = labelCompta.size()

let miniY   = size - 90 - miniSize.height
let comptaY = miniY - 6 - comptaSize.height

labelMini.draw(in: CGRect(x: (size - miniSize.width) / 2, y: miniY, width: miniSize.width, height: miniSize.height))
labelCompta.draw(in: CGRect(x: (size - comptaSize.width) / 2, y: comptaY, width: comptaSize.width, height: comptaSize.height))

// Trait
let underlineW: CGFloat = 220
let underlineX = (size - underlineW) / 2
let underlineY = comptaY - 20
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.35))
ctx.setLineWidth(2.5)
ctx.setLineCap(.round)
ctx.move(to: CGPoint(x: underlineX, y: underlineY))
ctx.addLine(to: CGPoint(x: underlineX + underlineW, y: underlineY))
ctx.strokePath()

// Barres
let barW: CGFloat = 100
let barSpacing: CGFloat = 30
let baseY: CGFloat = 210
let barHeights: [CGFloat] = [220, 370, 155, 300]
let totalW = CGFloat(barHeights.count) * barW + CGFloat(barHeights.count - 1) * barSpacing
let startX = (size - totalW) / 2
let barColors: [CGColor] = [
    CGColor(red: 1, green: 1, blue: 1, alpha: 0.50),
    CGColor(red: 1, green: 1, blue: 1, alpha: 0.95),
    CGColor(red: 1, green: 1, blue: 1, alpha: 0.40),
    CGColor(red: 1, green: 1, blue: 1, alpha: 0.75),
]

for (i, h) in barHeights.enumerated() {
    let x = startX + CGFloat(i) * (barW + barSpacing)
    let barRect = CGRect(x: x, y: baseY, width: barW, height: h)
    let barPath = CGPath(roundedRect: barRect, cornerWidth: 18, cornerHeight: 18, transform: nil)
    ctx.setFillColor(barColors[i])
    ctx.addPath(barPath)
    ctx.fillPath()
}

// Ligne de base
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.30))
ctx.setLineWidth(3)
ctx.move(to: CGPoint(x: startX - 20, y: baseY))
ctx.addLine(to: CGPoint(x: startX + totalW + 20, y: baseY))
ctx.strokePath()

NSGraphicsContext.restoreGraphicsState()

// 4. Exporter
guard let cgImage = ctx.makeImage() else {
    print("Erreur makeImage")
    exit(1)
}

let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
// On s'assure que le PNG final n'a pas d'alpha lors de l'écriture
guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
    exit(1)
}

try pngData.write(to: URL(fileURLWithPath: outputPath))
print("✅ Icône générée sans canal alpha (Opaque) : \(outputPath)")
