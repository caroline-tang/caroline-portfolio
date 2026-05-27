#!/usr/bin/env swift
import AppKit
import AVFoundation
import Foundation

guard CommandLine.argc >= 3 else {
    fputs(
        "用法: extract_video_every_nth_frame.swift <输入.mp4> <输出目录> [每隔几帧取一张，默认5]\n",
        stderr
    )
    exit(1)
}

let inputPath = CommandLine.arguments[1]
let outputDir = CommandLine.arguments[2]
let everyN = max(1, Int(CommandLine.arguments[3]) ?? 5)

let inputURL = URL(fileURLWithPath: inputPath)
let outURL = URL(fileURLWithPath: outputDir, isDirectory: true)

try FileManager.default.createDirectory(at: outURL, withIntermediateDirectories: true)

let asset = AVAsset(url: inputURL)
let keys = ["tracks", "duration"]
let sem = DispatchSemaphore(value: 0)
asset.loadValuesAsynchronously(forKeys: keys) { sem.signal() }
sem.wait()

var err: NSError?
if asset.statusOfValue(forKey: "tracks", error: &err) != .loaded {
    fputs("无法加载视频轨: \(err?.localizedDescription ?? "?")\n", stderr)
    exit(1)
}

guard let track = asset.tracks(withMediaType: .video).first else {
    fputs("没有视频轨\n", stderr)
    exit(1)
}

let gen = AVAssetImageGenerator(asset: asset)
gen.appliesPreferredTrackTransform = true
gen.requestedTimeToleranceBefore = .zero
gen.requestedTimeToleranceAfter = .zero

let duration = asset.duration
let oneFrame = track.minFrameDuration
if oneFrame.seconds <= 0 && oneFrame.value <= 0 {
    fputs("无效的 minFrameDuration\n", stderr)
    exit(1)
}

var frameIdx = 0
var outSeq = 0
while true {
    let t = CMTimeMultiply(oneFrame, multiplier: Int32(frameIdx))
    if CMTimeCompare(t, duration) >= 0 { break }

    do {
        let cg = try gen.copyCGImage(at: t, actualTime: nil)
        let img = NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
        let pad = String(format: "%04d", outSeq + 1)
        let file = outURL.appendingPathComponent("frame_every\(everyN)f_\(pad).jpg")
        guard let tiff = img.tiffRepresentation,
            let rep = NSBitmapImageRep(data: tiff),
            let data = rep.representation(
                using: .jpeg,
                properties: [.compressionFactor: 0.88] as [NSBitmapImageRep.PropertyKey: Any]
            )
        else {
            fputs("JPEG 编码失败 seq \(outSeq)\n", stderr)
            exit(1)
        }
        try data.write(to: file)
    } catch {
        fputs("抽帧 视频第\(frameIdx)帧 @\(CMTimeGetSeconds(t))s: \(error)\n", stderr)
        exit(1)
    }

    outSeq += 1
    frameIdx += everyN
}

print("每隔 \(everyN) 帧取一张，共 \(outSeq) 张 JPG → \(outputDir)")
