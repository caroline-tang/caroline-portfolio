#!/usr/bin/env swift
import AppKit
import Foundation

/// 覆盖左下角说明条（与 Editorial 深色底接近的纯色），用于去掉生成图里误加的小字。
/// 用法: swift remove_bottom_left_caption.swift <输入.png> [输出.png]
/// 若省略输出路径，则覆盖输入文件。

guard CommandLine.argc >= 2 else {
    fputs("Usage: remove_bottom_left_caption.swift <input.png> [output.png]\n", stderr)
    exit(1)
}

let inPath = CommandLine.arguments[1]
let outPath = CommandLine.arguments.count >= 3 ? CommandLine.arguments[2] : inPath

guard let src = NSImage(contentsOfFile: inPath) else {
    fputs("Failed to load: \(inPath)\n", stderr)
    exit(2)
}

let w = src.size.width
let h = src.size.height
guard w > 10, h > 10 else { exit(3) }

// 左下角条带：宽约 42%，高约 16%（可按图再调）
let stripW = w * 0.42
let stripH = h * 0.16
let erase = NSRect(x: 0, y: 0, width: stripW, height: stripH)

let out = NSImage(size: NSSize(width: w, height: h))
out.lockFocus()
NSGraphicsContext.current?.imageInterpolation = .high
src.draw(
    in: NSRect(origin: .zero, size: NSSize(width: w, height: h)),
    from: NSRect(origin: .zero, size: NSSize(width: w, height: h)),
    operation: .copy,
    fraction: 1
)
// 与站点 Editorial 背景 #0e0e10 接近
NSColor(calibratedRed: 0.055, green: 0.055, blue: 0.063, alpha: 1).setFill()
NSBezierPath(rect: erase).fill()
out.unlockFocus()

guard let tiff = out.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let data = rep.representation(using: .png, properties: [:]) else {
    fputs("Failed to encode PNG\n", stderr)
    exit(4)
}

do {
    try data.write(to: URL(fileURLWithPath: outPath))
    print("OK \(inPath) -> \(outPath) erased \(Int(stripW))x\(Int(stripH)) strip")
} catch {
    fputs("Write error: \(error)\n", stderr)
    exit(5)
}
