#!/usr/bin/env swift
import AppKit
import Foundation

/// 将图片从正中央垂直一分为二，并自动判断哪一侧更接近「纯色封底」
/// （用亮度标准差启发式；若判断反了，可改 swap 参数）。
/// 用法: swift split_cover_spread.swift <in.png> <outFront.png> <outBack.png> [--swap]

func luminanceStd(of img: NSImage) -> Double {
    let w = max(8, Int(img.size.width) / 64)
    let h = max(8, Int(img.size.height) / 64)
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: w,
        pixelsHigh: h,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { return 0 }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    img.draw(
        in: NSRect(x: 0, y: 0, width: w, height: h),
        from: NSRect(origin: .zero, size: img.size),
        operation: .copy,
        fraction: 1
    )
    NSGraphicsContext.restoreGraphicsState()

    var vals: [Double] = []
    for y in 0..<h {
        for x in 0..<w {
            guard let c = rep.colorAt(x: x, y: y) else { continue }
            let r = Double(c.redComponent)
            let g = Double(c.greenComponent)
            let b = Double(c.blueComponent)
            vals.append(0.2126 * r + 0.7152 * g + 0.0722 * b)
        }
    }
    guard !vals.isEmpty else { return 0 }
    let mean = vals.reduce(0, +) / Double(vals.count)
    let varSum = vals.map { ($0 - mean) * ($0 - mean) }.reduce(0, +)
    return sqrt(varSum / Double(vals.count))
}

func cgHalf(from img: NSImage, left: Bool) -> NSImage? {
    var rect = NSRect(origin: .zero, size: img.size)
    guard let cg = img.cgImage(forProposedRect: &rect, context: nil, hints: nil) else { return nil }
    let W = cg.width
    let H = cg.height
    let mid = W / 2
    let crop = left ? CGRect(x: 0, y: 0, width: mid, height: H)
        : CGRect(x: mid, y: 0, width: W - mid, height: H)
    guard let part = cg.cropping(to: crop) else { return nil }
    return NSImage(cgImage: part, size: NSSize(width: crop.width, height: crop.height))
}

func savePNG(_ img: NSImage, _ path: String) throws {
    guard let tiff = img.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "png", code: 1)
    }
    try data.write(to: URL(fileURLWithPath: path))
}

guard CommandLine.argc >= 4 else {
    fputs("Usage: split_cover_spread.swift <in.png> <outFront.png> <outBack.png> [--swap]\n", stderr)
    exit(1)
}

let inPath = CommandLine.arguments[1]
let outFront = CommandLine.arguments[2]
let outBack = CommandLine.arguments[3]
let swap = CommandLine.arguments.contains("--swap")

guard let src = NSImage(contentsOfFile: inPath) else {
    fputs("Cannot load \(inPath)\n", stderr)
    exit(2)
}

guard var leftImg = cgHalf(from: src, left: true),
      var rightImg = cgHalf(from: src, left: false) else {
    fputs("Crop failed\n", stderr)
    exit(3)
}

let stdL = luminanceStd(of: leftImg)
let stdR = luminanceStd(of: rightImg)
// 标准差更小的一侧更像「大块纯色」封底
var backIsLeft = stdL < stdR
if swap { backIsLeft.toggle() }

let frontImg = backIsLeft ? rightImg : leftImg
let backImg = backIsLeft ? leftImg : rightImg

do {
    try savePNG(frontImg, outFront)
    try savePNG(backImg, outBack)
    print("OK front=\(outFront) back=\(outBack) stdL=\(String(format: "%.4f", stdL)) stdR=\(String(format: "%.4f", stdR)) backIsLeft=\(backIsLeft)")
} catch {
    fputs("\(error)\n", stderr)
    exit(4)
}
