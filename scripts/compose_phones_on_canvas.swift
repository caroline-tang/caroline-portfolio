#!/usr/bin/env swift
import AppKit
import Foundation

guard CommandLine.argc >= 4 else {
    fputs("用法: compose_phones_on_canvas.swift <宽> <高> <输出png> <屏1> [屏2...]\n", stderr)
    exit(1)
}

let outW = Int(CommandLine.arguments[1]) ?? 1536
let outH = Int(CommandLine.arguments[2]) ?? 1024
let outPath = CommandLine.arguments[3]
let screenPaths = Array(CommandLine.arguments[4...])
guard !screenPaths.isEmpty else {
    fputs("至少一张屏图\n", stderr)
    exit(1)
}

func loadImage(_ path: String) -> NSImage? {
    guard let img = NSImage(contentsOfFile: path) else { return nil }
    return img
}

func drawRoundedScreen(_ img: NSImage, in rect: NSRect, corner: CGFloat, ctx: CGContext) {
    ctx.saveGState()
    let path = CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil)
    ctx.addPath(path)
    ctx.clip()
    img.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
    ctx.restoreGState()
    ctx.setStrokeColor(NSColor(white: 0.15, alpha: 0.35).cgColor)
    ctx.setLineWidth(1.5)
    ctx.addPath(path)
    ctx.strokePath()
}

let canvas = NSImage(size: NSSize(width: outW, height: outH))
canvas.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else { exit(1) }

// 暖灰桌面渐变
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
let margin: CGFloat = 48
let usableW = CGFloat(outW) - margin * 2
let phoneH = CGFloat(outH) * 0.78
let gap = usableW / CGFloat(n)

for (i, path) in screenPaths.enumerated() {
    guard let img = loadImage(path) else { continue }
    let aspect = img.size.width / img.size.height
    var h = phoneH
    var w = h * aspect
    let maxW = gap * 0.92
    if w > maxW {
        w = maxW
        h = w / aspect
    }
    // 浅弧：中间略高
    let t = CGFloat(i) / CGFloat(max(n - 1, 1))
    let arcLift = sin(t * .pi) * 28
    let cx = margin + gap * (CGFloat(i) + 0.5)
    let cy = CGFloat(outH) * 0.42 + arcLift
    let rect = NSRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h)
    drawRoundedScreen(img, in: rect, corner: 14, ctx: ctx)
}

canvas.unlockFocus()
guard let tiff = canvas.tiffRepresentation,
    let rep = NSBitmapImageRep(data: tiff),
    let png = rep.representation(using: .png, properties: [:])
else { exit(1) }
try png.write(to: URL(fileURLWithPath: outPath))
print("已输出 \(outPath) \(outW)x\(outH) · \(n) 屏")
