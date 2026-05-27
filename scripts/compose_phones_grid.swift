#!/usr/bin/env swift
import AppKit
import Foundation

guard CommandLine.argc >= 5 else {
    fputs("用法: compose_phones_grid.swift <宽> <高> <列数> <输出png> <屏1> [屏2...]\n", stderr)
    exit(1)
}

let outW = Int(CommandLine.arguments[1]) ?? 1536
let outH = Int(CommandLine.arguments[2]) ?? 1024
let cols = max(1, Int(CommandLine.arguments[3]) ?? 8)
let outPath = CommandLine.arguments[4]
let screenPaths = Array(CommandLine.arguments[5...])
guard !screenPaths.isEmpty else {
    fputs("至少一张屏图\n", stderr)
    exit(1)
}

func drawRoundedScreen(_ img: NSImage, in rect: NSRect, corner: CGFloat, ctx: CGContext) {
    ctx.saveGState()
    let path = CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil)
    ctx.addPath(path)
    ctx.clip()
    img.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
    ctx.restoreGState()
    ctx.setStrokeColor(NSColor(white: 0.15, alpha: 0.35).cgColor)
    ctx.setLineWidth(1.2)
    ctx.addPath(path)
    ctx.strokePath()
}

let canvas = NSImage(size: NSSize(width: outW, height: outH))
canvas.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else { exit(1) }

let colors = [
    NSColor(red: 0.91, green: 0.89, blue: 0.86, alpha: 1).cgColor,
    NSColor(red: 0.82, green: 0.80, blue: 0.77, alpha: 1).cgColor,
] as CFArray
let space = CGColorSpaceCreateDeviceRGB()
if let grad = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1]) {
    ctx.drawLinearGradient(
        grad,
        start: CGPoint(x: 0, y: CGFloat(outH)),
        end: CGPoint(x: CGFloat(outW) * 0.3, y: 0),
        options: []
    )
}

let n = screenPaths.count
let rows = Int(ceil(Double(n) / Double(cols)))
let marginX: CGFloat = 36
let marginY: CGFloat = 40
let usableW = CGFloat(outW) - marginX * 2
let usableH = CGFloat(outH) - marginY * 2
let cellW = usableW / CGFloat(cols)
let cellH = usableH / CGFloat(rows)

for (i, path) in screenPaths.enumerated() {
    guard let img = NSImage(contentsOfFile: path) else { continue }
    let row = i / cols
    let col = i % cols
    let aspect = img.size.width / max(img.size.height, 1)
    var h = cellH * 0.88
    var w = h * aspect
    let maxW = cellW * 0.9
    if w > maxW {
        w = maxW
        h = w / aspect
    }
    let t = CGFloat(col) / CGFloat(max(cols - 1, 1))
    let arcLift = sin(t * .pi) * (row == 0 ? 14 : 10)
    let cx = marginX + cellW * (CGFloat(col) + 0.5)
    let rowCenter = marginY + cellH * (CGFloat(rows - 1 - row) + 0.5)
    let cy = rowCenter + arcLift
    let rect = NSRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h)
    drawRoundedScreen(img, in: rect, corner: 10, ctx: ctx)
}

canvas.unlockFocus()
guard let tiff = canvas.tiffRepresentation,
    let rep = NSBitmapImageRep(data: tiff),
    let png = rep.representation(using: .png, properties: [:])
else { exit(1) }
try png.write(to: URL(fileURLWithPath: outPath))
print("已输出 \(outPath) \(outW)x\(outH) · \(n) 屏 · \(cols)×\(rows)")
