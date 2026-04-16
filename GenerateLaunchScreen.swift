#!/usr/bin/env swift

import AppKit
import CoreGraphics

// iPhone 15 Pro Max @3x — bon rendu sur tous les écrans
let W: CGFloat = 1290
let H: CGFloat = 2796
let outputPath = "Sources/Assets.xcassets/LaunchImage.imageset/LaunchScreen.png"

let image = NSImage(size: NSSize(width: W, height: H))
image.lockFocus()

guard let ctx = NSGraphicsContext.current?.cgContext else { exit(1) }

// ── Dégradé bleu → violet (identique à l'icône) ──────────────────────────────

let colors = [
    CGColor(red: 0.12, green: 0.42, blue: 0.95, alpha: 1),
    CGColor(red: 0.48, green: 0.18, blue: 0.92, alpha: 1),
]
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let gradient = CGGradient(
    colorsSpace: colorSpace,
    colors: colors as CFArray,
    locations: [0, 1] as [CGFloat]
) else { exit(1) }

ctx.drawLinearGradient(
    gradient,
    start: CGPoint(x: W * 0.1, y: H),
    end: CGPoint(x: W * 0.9, y: 0),
    options: []
)

// ── Cercles glassmorphisme ────────────────────────────────────────────────────

ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.07))
ctx.fillEllipse(in: CGRect(x: W * 0.45, y: H * 0.45, width: W * 1.1, height: W * 1.1))

ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.04))
ctx.fillEllipse(in: CGRect(x: -W * 0.3, y: -W * 0.2, width: W * 1.0, height: W * 1.0))

// ── Texte "MINI" ─────────────────────────────────────────────────────────────

let paraStyle = NSMutableParagraphStyle()
paraStyle.alignment = .center

let attrsMini: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 310, weight: .black),
    .foregroundColor: NSColor(white: 1, alpha: 0.97),
    .paragraphStyle: paraStyle,
    .kern: 10.0,
]
let attrCompta: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 230, weight: .bold),
    .foregroundColor: NSColor(white: 1, alpha: 0.95),
    .paragraphStyle: paraStyle,
    .kern: 10.0,
]

let labelMini   = NSAttributedString(string: "MINI",   attributes: attrsMini)
let labelCompta = NSAttributedString(string: "COMPTA", attributes: attrCompta)

let miniSize   = labelMini.size()
let comptaSize = labelCompta.size()
let interLigne: CGFloat = 10

// ── Calcul automatique du centrage ───────────────────────────────────────────
// On empile : MINI + interLigne + COMPTA + gapTextBars + barres
// puis on centre la composition dans l'image avec marges égales.

let barW: CGFloat = 175
let barSpacing: CGFloat = 55
let barHeights: [CGFloat] = [490, 820, 350, 660]
let maxBarH = barHeights.max()!
let gapTextBars: CGFloat = 45   // espace serré entre COMPTA et le haut des barres

let compositionH = miniSize.height + interLigne + comptaSize.height + gapTextBars + maxBarH
let baseMargin   = (H - compositionH) / 2   // ~586px de marge haut et bas

// Positions en coordonnées CG (y=0 en bas)
let baseY   = baseMargin                                          // pied des barres
let comptaY = baseY + maxBarH + gapTextBars                      // pied de "COMPTA"
let miniY   = comptaY + comptaSize.height + interLigne           // pied de "MINI"

labelMini.draw(in: CGRect(x: (W - miniSize.width) / 2, y: miniY,
                          width: miniSize.width, height: miniSize.height))
labelCompta.draw(in: CGRect(x: (W - comptaSize.width) / 2, y: comptaY,
                            width: comptaSize.width, height: comptaSize.height))

// Séparateur fin dans le gap entre COMPTA et les barres
let sepW: CGFloat = 520
let sepX = (W - sepW) / 2
let sepY = baseY + maxBarH + gapTextBars / 2
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.35))
ctx.setLineWidth(5)
ctx.setLineCap(.round)
ctx.move(to: CGPoint(x: sepX, y: sepY))
ctx.addLine(to: CGPoint(x: sepX + sepW, y: sepY))
ctx.strokePath()
let totalBarsW = CGFloat(barHeights.count) * barW + CGFloat(barHeights.count - 1) * barSpacing
let startX = (W - totalBarsW) / 2

let barColors: [CGColor] = [
    CGColor(red: 1, green: 1, blue: 1, alpha: 0.50),
    CGColor(red: 1, green: 1, blue: 1, alpha: 0.92),
    CGColor(red: 1, green: 1, blue: 1, alpha: 0.40),
    CGColor(red: 1, green: 1, blue: 1, alpha: 0.72),
]

for (i, h) in barHeights.enumerated() {
    let x = startX + CGFloat(i) * (barW + barSpacing)
    let barPath = CGPath(
        roundedRect: CGRect(x: x, y: baseY, width: barW, height: h),
        cornerWidth: 40, cornerHeight: 40, transform: nil
    )
    ctx.setFillColor(barColors[i])
    ctx.addPath(barPath)
    ctx.fillPath()
}

// Ligne de base
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.28))
ctx.setLineWidth(5)
ctx.move(to: CGPoint(x: startX - 40, y: baseY))
ctx.addLine(to: CGPoint(x: startX + totalBarsW + 40, y: baseY))
ctx.strokePath()

// ── Export PNG ────────────────────────────────────────────────────────────────

image.unlockFocus()

guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("Impossible de convertir en CGImage"); exit(1)
}

let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
bitmapRep.size = NSSize(width: W, height: H)

guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
    print("Impossible de générer le PNG"); exit(1)
}

do {
    try pngData.write(to: URL(fileURLWithPath: outputPath))
    print("✅ Launch screen généré : \(outputPath)")
} catch {
    print("❌ Erreur : \(error)"); exit(1)
}
