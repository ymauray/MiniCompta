#!/usr/bin/env swift

import AppKit
import CoreGraphics

let size: CGFloat = 1024
let outputPath = "Sources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"

let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

guard let ctx = NSGraphicsContext.current?.cgContext else {
    print("Impossible d'obtenir le contexte graphique")
    exit(1)
}

// ── Fond avec dégradé bleu → violet ──────────────────────────────────────────

let colors = [
    CGColor(red: 0.12, green: 0.42, blue: 0.95, alpha: 1),   // bleu vif
    CGColor(red: 0.48, green: 0.18, blue: 0.92, alpha: 1),   // violet
]
let locations: [CGFloat] = [0, 1]
let colorSpace = CGColorSpaceCreateDeviceRGB()

guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations) else {
    exit(1)
}

// Arrondi iOS (rayon = 22.5% de la taille)
let radius: CGFloat = size * 0.225
let rect = CGRect(x: 0, y: 0, width: size, height: size)
let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
ctx.addPath(path)
ctx.clip()

ctx.drawLinearGradient(
    gradient,
    start: CGPoint(x: size * 0.1, y: size),
    end: CGPoint(x: size * 0.9, y: 0),
    options: []
)

// ── Cercle blanc semi-transparent (effet glassmorphisme) ──────────────────────

ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.08))
ctx.fillEllipse(in: CGRect(x: size * 0.52, y: size * 0.52, width: size * 0.65, height: size * 0.65))

ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.05))
ctx.fillEllipse(in: CGRect(x: -size * 0.15, y: -size * 0.15, width: size * 0.6, height: size * 0.6))

// ── Texte "MINI" + "COMPTA" en haut ─────────────────────────────────────────
// y=0 est en bas en CG → grandes valeurs de y = haut visuellement

let paraStyle = NSMutableParagraphStyle()
paraStyle.alignment = .center

// "MINI" — grande, très grasse
let attrsMini: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 150, weight: .black),
    .foregroundColor: NSColor(white: 1, alpha: 0.97),
    .paragraphStyle: paraStyle,
    .kern: 8.0
]

// "COMPTA" — grande, bien visible
let attrsCompta: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 118, weight: .bold),
    .foregroundColor: NSColor(white: 1, alpha: 0.95),
    .paragraphStyle: paraStyle,
    .kern: 8.0
]

let labelMini   = NSAttributedString(string: "MINI",   attributes: attrsMini)
let labelCompta = NSAttributedString(string: "COMPTA", attributes: attrsCompta)

let miniSize   = labelMini.size()
let comptaSize = labelCompta.size()

// Espacement entre les deux lignes
let interLigne: CGFloat = 6

// Bloc total centré verticalement dans la zone haute (visuellement y ≈ 90..310 depuis le haut)
// En CG : mini démarre à y = size - 90 - miniSize.height
let miniY   = size - 90 - miniSize.height
let comptaY = miniY - interLigne - comptaSize.height

let miniRect = CGRect(
    x: (size - miniSize.width) / 2,
    y: miniY,
    width: miniSize.width,
    height: miniSize.height
)
let comptaRect = CGRect(
    x: (size - comptaSize.width) / 2,
    y: comptaY,
    width: comptaSize.width,
    height: comptaSize.height
)

labelMini.draw(in: miniRect)
labelCompta.draw(in: comptaRect)

// Trait séparateur sous "COMPTA" (visuellement)
let underlineW: CGFloat = 220
let underlineX = (size - underlineW) / 2
let underlineY = comptaRect.minY - 20
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.35))
ctx.setLineWidth(2.5)
ctx.setLineCap(.round)
ctx.move(to: CGPoint(x: underlineX, y: underlineY))
ctx.addLine(to: CGPoint(x: underlineX + underlineW, y: underlineY))
ctx.strokePath()

// ── Barres de graphique ───────────────────────────────────────────────────────
// Baseline visuellement à ~y=220 depuis le bas → CG baseY = 220
// Les barres montent depuis la baseline (y CG croissant = montée visuelle)

let barW: CGFloat = 100
let barSpacing: CGFloat = 30
let baseY: CGFloat = 210           // baseline en CG (220px depuis le bas visuellement)
let barHeights: [CGFloat] = [220, 370, 155, 300]
let totalW = CGFloat(barHeights.count) * barW + CGFloat(barHeights.count - 1) * barSpacing
let startX = (size - totalW) / 2

let barColors: [CGColor] = [
    CGColor(red: 1, green: 1, blue: 1, alpha: 0.50),
    CGColor(red: 1, green: 1, blue: 1, alpha: 0.92),
    CGColor(red: 1, green: 1, blue: 1, alpha: 0.40),
    CGColor(red: 1, green: 1, blue: 1, alpha: 0.72),
]

for (i, h) in barHeights.enumerated() {
    let x = startX + CGFloat(i) * (barW + barSpacing)
    // Rect en CG : origine en bas-gauche, hauteur vers le haut
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

// ── Export PNG ───────────────────────────────────────────────────────────────

image.unlockFocus()

guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("Impossible de convertir en CGImage")
    exit(1)
}

let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
bitmapRep.size = NSSize(width: size, height: size)

guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
    print("Impossible de générer le PNG")
    exit(1)
}

let fileURL = URL(fileURLWithPath: outputPath)
do {
    try pngData.write(to: fileURL)
    print("✅ Icône générée : \(outputPath)")
} catch {
    print("❌ Erreur d'écriture : \(error)")
    exit(1)
}
