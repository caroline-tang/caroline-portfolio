#!/usr/bin/env swift
import AppKit
import Foundation

guard CommandLine.argc >= 4 else {
    fputs("用法: compose_mascot_scenes.swift <宽> <高> <输出png> <素材png> [single|duo]\n", stderr)
    exit(1)
}

let outW = CGFloat(Int(CommandLine.arguments[1]) ?? 1536)
let outH = CGFloat(Int(CommandLine.arguments[2]) ?? 1024)
let outPath = CommandLine.arguments[3]
let assetPath = CommandLine.arguments[4]
let mode = CommandLine.arguments.count > 5 ? CommandLine.arguments[5] : "single"

/// 与 compose_phones_on_canvas.swift 一致的暖灰台面
func drawPortfolioBackground(ctx: CGContext, w: CGFloat, h: CGFloat) {
    let colors = [
        NSColor(red: 0.91, green: 0.89, blue: 0.86, alpha: 1).cgColor,
        NSColor(red: 0.82, green: 0.80, blue: 0.77, alpha: 1).cgColor,
    ] as CFArray
    let space = CGColorSpaceCreateDeviceRGB()
    if let grad = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1]) {
        ctx.drawLinearGradient(
            grad,
            start: CGPoint(x: 0, y: h),
            end: CGPoint(x: w * 0.3, y: 0),
            options: []
        )
    }
    // 轻微暗角，贴近 UI 样机摄影感
    if let vign = CGGradient(
        colorsSpace: space,
        colors: [NSColor.clear.cgColor, NSColor.black.withAlphaComponent(0.08).cgColor] as CFArray,
        locations: [0.55, 1]
    ) {
        ctx.drawRadialGradient(
            vign,
            startCenter: CGPoint(x: w * 0.5, y: h * 0.45),
            startRadius: h * 0.15,
            endCenter: CGPoint(x: w * 0.5, y: h * 0.45),
            endRadius: max(w, h) * 0.72,
            options: []
        )
    }
}

func cgImage(from path: String, crop: CGRect?) -> CGImage? {
    guard let img = NSImage(contentsOfFile: path),
        let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil)
    else { return nil }
    guard let crop else { return cg }
    let scaleX = CGFloat(cg.width) / img.size.width
    let scaleY = CGFloat(cg.height) / img.size.height
    let r = CGRect(
        x: crop.origin.x * scaleX,
        y: crop.origin.y * scaleY,
        width: crop.width * scaleX,
        height: crop.height * scaleY
    ).integral
    return cg.cropping(to: r)
}

/// 与手机样机一致：圆角 14、轻描边、投影
func drawAssetLikePhone(
    ctx: CGContext,
    image: CGImage,
    center: CGPoint,
    maxSize: CGSize,
    rotation: CGFloat
) {
    let iw = CGFloat(image.width)
    let ih = CGFloat(image.height)
    let scale = min(maxSize.width / iw, maxSize.height / ih)
    let dw = iw * scale
    let dh = ih * scale
    let corner: CGFloat = 14

    ctx.saveGState()
    ctx.translateBy(x: center.x, y: center.y)
    ctx.rotate(by: rotation)

    let rect = CGRect(x: -dw / 2, y: -dh / 2, width: dw, height: dh)
    let path = CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 28, color: NSColor.black.withAlphaComponent(0.28).cgColor)
    ctx.addPath(path)
    ctx.setFillColor(NSColor.black.cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    ctx.addPath(path)
    ctx.clip()
    ctx.draw(image, in: rect)

    ctx.setStrokeColor(NSColor(white: 0.15, alpha: 0.35).cgColor)
    ctx.setLineWidth(1.5)
    ctx.addPath(path)
    ctx.strokePath()

    ctx.restoreGState()
}

guard let srcImg = NSImage(contentsOfFile: assetPath),
    let srcCG = srcImg.cgImage(forProposedRect: nil, context: nil, hints: nil)
else {
    fputs("无法读取素材\n", stderr)
    exit(1)
}
let srcW = CGFloat(srcCG.width)
let srcH = CGFloat(srcCG.height)
let cropW = srcW * 0.52
let cropHeight = srcH * 0.52
let heroCrop = CGRect(x: 0, y: srcH - cropHeight, width: cropW, height: cropHeight)

let canvas = NSImage(size: NSSize(width: outW, height: outH))
canvas.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else { exit(1) }

drawPortfolioBackground(ctx: ctx, w: outW, h: outH)

let maxH = outH * 0.78

if mode == "duo" {
    let margin: CGFloat = 56
    let usableW = outW - margin * 2
    let centers: [(CGPoint, CGSize, CGFloat)] = [
        (CGPoint(x: margin + usableW * 0.32, y: outH * 0.44), CGSize(width: usableW * 0.38, height: maxH * 0.88), -0.035),
        (CGPoint(x: margin + usableW * 0.72, y: outH * 0.40), CGSize(width: usableW * 0.34, height: maxH * 0.72), 0.04),
    ]
    if let hero = cgImage(from: assetPath, crop: heroCrop) {
        drawAssetLikePhone(ctx: ctx, image: hero, center: centers[0].0, maxSize: centers[0].1, rotation: centers[0].2)
    }
    if let full = cgImage(from: assetPath, crop: nil) {
        drawAssetLikePhone(ctx: ctx, image: full, center: centers[1].0, maxSize: centers[1].1, rotation: centers[1].2)
    }
} else {
    if let full = cgImage(from: assetPath, crop: nil) {
        drawAssetLikePhone(
            ctx: ctx,
            image: full,
            center: CGPoint(x: outW * 0.5, y: outH * 0.42),
            maxSize: CGSize(width: outW * 0.58, height: maxH),
            rotation: -0.02
        )
    }
}

canvas.unlockFocus()
guard let tiff = canvas.tiffRepresentation,
    let outRep = NSBitmapImageRep(data: tiff),
    let png = outRep.representation(using: .png, properties: [:])
else { exit(1) }
try png.write(to: URL(fileURLWithPath: outPath))
print("已输出 \(outPath) · \(mode)")
