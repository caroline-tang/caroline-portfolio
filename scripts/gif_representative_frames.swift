#!/usr/bin/env swift
import AppKit
import ImageIO
import Foundation

guard CommandLine.argc >= 3 else {
    fputs(
        "用法: gif_representative_frames.swift <输入.gif> <输出目录> [最多张数，默认6]\n",
        stderr
    )
    exit(1)
}

let inputPath = CommandLine.arguments[1]
let outputDir = CommandLine.arguments[2]
let maxFrames = Int(CommandLine.arguments[3]) ?? 6

let inputURL = URL(fileURLWithPath: inputPath) as CFURL
let outURL = URL(fileURLWithPath: outputDir, isDirectory: true)

guard let src = CGImageSourceCreateWithURL(inputURL, nil) else {
    fputs("无法打开图像源\n", stderr)
    exit(1)
}

let count = CGImageSourceGetCount(src)
if count < 1 {
    fputs("没有可读帧\n", stderr)
    exit(1)
}

try FileManager.default.createDirectory(at: outURL, withIntermediateDirectories: true)

let k = min(max(1, maxFrames), count)
let indices: [Int]
if count <= k {
    indices = Array(0 ..< count)
} else {
    indices = (0 ..< k).map { i in
        Int(round(Double(i) * Double(count - 1) / Double(k - 1)))
    }
}

for (seq, frameIndex) in indices.enumerated() {
    guard let cg = CGImageSourceCreateImageAtIndex(src, frameIndex, nil) else {
        fputs("跳过帧 \(frameIndex)\n", stderr)
        continue
    }
    let img = NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
    let pad = String(format: "%02d", seq + 1)
    let file = outURL.appendingPathComponent("jianye-loop-rep-\(pad).jpg")
    guard let tiff = img.tiffRepresentation,
        let rep = NSBitmapImageRep(data: tiff),
        let data = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.88])
    else {
        fputs("编码失败 rep-\(pad)\n", stderr)
        exit(1)
    }
    try data.write(to: file)
}

print("GIF 共 \(count) 帧，导出 \(indices.count) 张代表帧 → \(outputDir)")
