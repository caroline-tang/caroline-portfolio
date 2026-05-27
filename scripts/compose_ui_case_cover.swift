#!/usr/bin/env swift
import AppKit
import Foundation

guard CommandLine.argc >= 5 else {
    fputs("用法: compose_ui_case_cover.swift <宽> <高> <输出png> <左屏> <右屏>\n", stderr)
    exit(1)
}

let outW = CGFloat(Int(CommandLine.arguments[1]) ?? 1920)
let outH = CGFloat(Int(CommandLine.arguments[2]) ?? 960)
let outPath = CommandLine.arguments[3]
let leftPath = CommandLine.arguments[4]
let rightPath = CommandLine.arguments[5]

func load(_ path: String) -> NSImage? { NSImage(contentsOfFile: path) }

func drawGlow(ctx: CGContext, center: CGPoint, radius: CGFloat, color: NSColor) {
    let colors = [color.withAlphaComponent(0.22).cgColor, color.withAlphaComponent(0).cgColor] as CFArray
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

func drawPhone(_ img: NSImage, center: CGPoint, height: CGFloat, tilt: CGFloat, ctx: CGContext) {
    let aspect = img.size.width / max(img.size.height, 1)
    let h = height
    let w = h * aspect
    let bezel: CGFloat = 10
    let corner: CGFloat = 28

    ctx.saveGState()
    ctx.translateBy(x: center.x, y: center.y)
    ctx.rotate(by: tilt * .pi / 180)
    ctx.translateBy(x: -center.x, y: -center.y)

    // 阴影
    ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 42, color: NSColor.black.withAlphaComponent(0.45).cgColor)
    let outer = NSRect(x: center.x - w / 2 - bezel, y: center.y - h / 2 - bezel * 1.4, width: w + bezel * 2, height: h + bezel * 2.2)
    let bodyPath = CGPath(roundedRect: outer, cornerWidth: corner + 6, cornerHeight: corner + 6, transform: nil)
    ctx.setFillColor(NSColor(white: 0.12, alpha: 1).cgColor)
    ctx.addPath(bodyPath)
    ctx.fillPath()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)

    // 屏幕
    let screen = NSRect(x: center.x - w / 2, y: center.y - h / 2, width: w, height: h)
    ctx.saveGState()
    let screenPath = CGPath(roundedRect: screen, cornerWidth: corner, cornerHeight: corner, transform: nil)
    ctx.addPath(screenPath)
    ctx.clip()
    img.draw(in: screen, from: .zero, operation: .sourceOver, fraction: 1)
    ctx.restoreGState()

    ctx.setStrokeColor(NSColor(white: 0.28, alpha: 0.5).cgColor)
    ctx.setLineWidth(1)
    ctx.addPath(screenPath)
    ctx.strokePath()

    ctx.restoreGState()
}

let canvas = NSImage(size: NSSize(width: outW, height: outH))
canvas.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else { exit(1) }

// 深色编辑背景
let bgColors = [
    NSColor(red: 0.11, green: 0.10, blue: 0.09, alpha: 1).cgColor,
    NSColor(red: 0.18, green: 0.17, blue: 0.16, alpha: 1).cgColor,
    NSColor(red: 0.13, green: 0.12, blue: 0.11, alpha: 1).cgColor,
] as CFArray
let space = CGColorSpaceCreateDeviceRGB()
if let grad = CGGradient(colorsSpace: space, colors: bgColors, locations: [0, 0.55, 1]) {
    ctx.drawLinearGradient(
        grad,
        start: CGPoint(x: 0, y: outH),
        end: CGPoint(x: outW, y: 0),
        options: []
    )
}

// 细颗粒感 vignette
ctx.setFillColor(NSColor.black.withAlphaComponent(0.18).cgColor)
ctx.fillEllipse(in: CGRect(x: -outW * 0.1, y: -outH * 0.2, width: outW * 1.2, height: outH * 0.5))
ctx.fillEllipse(in: CGRect(x: -outW * 0.1, y: outH * 0.7, width: outW * 1.2, height: outH * 0.5))

drawGlow(ctx: ctx, center: CGPoint(x: outW * 0.28, y: outH * 0.52), radius: outW * 0.32, color: NSColor(red: 0.95, green: 0.45, blue: 0.12, alpha: 1))
drawGlow(ctx: ctx, center: CGPoint(x: outW * 0.72, y: outH * 0.48), radius: outW * 0.30, color: NSColor(red: 0.85, green: 0.15, blue: 0.12, alpha: 1))

let phoneH = outH * 0.78
if let left = load(leftPath) {
    drawPhone(left, center: CGPoint(x: outW * 0.32, y: outH * 0.46), height: phoneH, tilt: -7, ctx: ctx)
}
if let right = load(rightPath) {
    drawPhone(right, center: CGPoint(x: outW * 0.68, y: outH * 0.46), height: phoneH, tilt: 7, ctx: ctx)
}

canvas.unlockFocus()
guard let tiff = canvas.tiffRepresentation,
    let rep = NSBitmapImageRep(data: tiff),
    let png = rep.representation(using: .png, properties: [:])
else { exit(1) }
try png.write(to: URL(fileURLWithPath: outPath))
print("已输出 \(outPath) \(Int(outW))x\(Int(outH))")
