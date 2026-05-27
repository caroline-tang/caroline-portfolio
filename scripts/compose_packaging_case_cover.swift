#!/usr/bin/env swift
import AppKit
import Foundation

guard CommandLine.argc >= 6 else {
    fputs(
        "用法: compose_packaging_case_cover.swift <宽> <高> <输出jpg> <左图> <右图>\n",
        stderr
    )
    exit(1)
}

let outW = CGFloat(Int(CommandLine.arguments[1]) ?? 1536)
let outH = CGFloat(Int(CommandLine.arguments[2]) ?? 1024)
let outPath = CommandLine.arguments[3]
let leftPath = CommandLine.arguments[4]
let rightPath = CommandLine.arguments[5]

func load(_ path: String) -> NSImage? { NSImage(contentsOfFile: path) }

func drawGlow(
    ctx: CGContext,
    center: CGPoint,
    radius: CGFloat,
    color: NSColor,
    alpha: CGFloat = 0.28
) {
    let colors = [
        color.withAlphaComponent(alpha).cgColor,
        color.withAlphaComponent(0).cgColor,
    ] as CFArray
    let space = CGColorSpaceCreateDeviceRGB()
    guard let g = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1]) else { return }
    ctx.drawRadialGradient(
        g,
        startCenter: center,
        startRadius: 0,
        endCenter: center,
        endRadius: radius,
        options: []
    )
}

func aspectFitRect(imageSize: NSSize, in container: NSRect) -> NSRect {
    let iw = max(imageSize.width, 1)
    let ih = max(imageSize.height, 1)
    let scale = min(container.width / iw, container.height / ih)
    let w = iw * scale
    let h = ih * scale
    return NSRect(
        x: container.midX - w / 2,
        y: container.midY - h / 2,
        width: w,
        height: h
    )
}

func drawSceneCard(
    _ img: NSImage,
    in container: NSRect,
    corner: CGFloat,
    tilt: CGFloat,
    shadowOpacity: CGFloat,
    ctx: CGContext
) {
    let fit = aspectFitRect(imageSize: img.size, in: container)
    let card = fit.insetBy(dx: -8, dy: -8)
    let pivot = CGPoint(x: card.midX, y: card.midY)

    ctx.saveGState()
    ctx.translateBy(x: pivot.x, y: pivot.y)
    ctx.rotate(by: tilt * .pi / 180)
    ctx.translateBy(x: -pivot.x, y: -pivot.y)

    ctx.setShadow(
        offset: CGSize(width: 0, height: -20),
        blur: 44,
        color: NSColor.black.withAlphaComponent(shadowOpacity).cgColor
    )
    let cardPath = CGPath(
        roundedRect: card,
        cornerWidth: corner,
        cornerHeight: corner,
        transform: nil
    )
    ctx.setFillColor(NSColor(white: 0.06, alpha: 0.65).cgColor)
    ctx.addPath(cardPath)
    ctx.fillPath()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)

    ctx.addPath(cardPath)
    ctx.clip()
    img.draw(in: fit, from: .zero, operation: .sourceOver, fraction: 1)

    let fade = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            NSColor.black.withAlphaComponent(0.36).cgColor,
            NSColor.clear.cgColor,
            NSColor.clear.cgColor,
            NSColor.black.withAlphaComponent(0.36).cgColor,
        ] as CFArray,
        locations: [0, 0.14, 0.86, 1]
    )
    if let fade {
        ctx.drawLinearGradient(
            fade,
            start: CGPoint(x: card.minX, y: card.midY),
            end: CGPoint(x: card.maxX, y: card.midY),
            options: []
        )
        ctx.drawLinearGradient(
            fade,
            start: CGPoint(x: card.midX, y: card.minY),
            end: CGPoint(x: card.midX, y: card.maxY),
            options: []
        )
    }

    ctx.restoreGState()

    ctx.saveGState()
    ctx.translateBy(x: pivot.x, y: pivot.y)
    ctx.rotate(by: tilt * .pi / 180)
    ctx.translateBy(x: -pivot.x, y: -pivot.y)
    ctx.addPath(cardPath)
    ctx.setStrokeColor(NSColor(white: 1, alpha: 0.10).cgColor)
    ctx.setLineWidth(1)
    ctx.strokePath()
    ctx.restoreGState()
}

let canvas = NSImage(size: NSSize(width: outW, height: outH))
canvas.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else { exit(1) }

let bgColors = [
    NSColor(red: 0.08, green: 0.06, blue: 0.07, alpha: 1).cgColor,
    NSColor(red: 0.15, green: 0.09, blue: 0.10, alpha: 1).cgColor,
    NSColor(red: 0.07, green: 0.06, blue: 0.06, alpha: 1).cgColor,
] as CFArray
let space = CGColorSpaceCreateDeviceRGB()
if let grad = CGGradient(colorsSpace: space, colors: bgColors, locations: [0, 0.5, 1]) {
    ctx.drawLinearGradient(
        grad,
        start: CGPoint(x: 0, y: outH),
        end: CGPoint(x: outW, y: 0),
        options: []
    )
}

drawGlow(
    ctx: ctx,
    center: CGPoint(x: outW * 0.30, y: outH * 0.56),
    radius: outW * 0.36,
    color: NSColor(red: 0.98, green: 0.91, blue: 0.86, alpha: 1),
    alpha: 0.22
)
drawGlow(
    ctx: ctx,
    center: CGPoint(x: outW * 0.70, y: outH * 0.50),
    radius: outW * 0.34,
    color: NSColor(red: 0.82, green: 0.14, blue: 0.16, alpha: 1),
    alpha: 0.30
)

ctx.setFillColor(NSColor.black.withAlphaComponent(0.40).cgColor)
ctx.fillEllipse(in: CGRect(x: outW * 0.06, y: -outH * 0.10, width: outW * 0.88, height: outH * 0.44))

let cardH = outH * 0.82
let cardW = outW * 0.46
let leftContainer = NSRect(
    x: outW * 0.02,
    y: outH * 0.5 - cardH / 2 + 8,
    width: cardW,
    height: cardH
)
let rightContainer = NSRect(
    x: outW * 0.50,
    y: outH * 0.5 - cardH / 2 - 8,
    width: cardW,
    height: cardH
)

if let left = load(leftPath) {
    drawSceneCard(left, in: leftContainer, corner: 16, tilt: -4.5, shadowOpacity: 0.42, ctx: ctx)
}
if let right = load(rightPath) {
    drawSceneCard(right, in: rightContainer, corner: 16, tilt: 4.5, shadowOpacity: 0.50, ctx: ctx)
}

ctx.setFillColor(NSColor.black.withAlphaComponent(0.24).cgColor)
ctx.fillEllipse(in: CGRect(x: -outW * 0.12, y: outH * 0.58, width: outW * 1.24, height: outH * 0.52))
ctx.fillEllipse(in: CGRect(x: -outW * 0.12, y: -outH * 0.16, width: outW * 1.24, height: outH * 0.42))

canvas.unlockFocus()

guard let tiff = canvas.tiffRepresentation,
    let rep = NSBitmapImageRep(data: tiff)
else { exit(1) }

rep.size = NSSize(width: outW, height: outH)
guard let jpg = rep.representation(
    using: .jpeg,
    properties: [.compressionFactor: 0.93]
) else { exit(1) }

try jpg.write(to: URL(fileURLWithPath: outPath))
print("已输出 \(outPath) \(Int(outW))x\(Int(outH))")
