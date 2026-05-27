#!/usr/bin/env swift
import AppKit
import AVFoundation
import Foundation

guard CommandLine.argc >= 3 else {
    fputs("用法: extract_video_frames.swift <输入.mp4> <输出目录>\n", stderr)
    exit(1)
}

let inputPath = CommandLine.arguments[1]
let outputDir = CommandLine.arguments[2]
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
let step = track.minFrameDuration
if step.seconds <= 0 && step.value <= 0 {
    fputs("无效的 minFrameDuration\n", stderr)
    exit(1)
}

var t = CMTime.zero
var index = 0
while t < duration {
    do {
        let cg = try gen.copyCGImage(at: t, actualTime: nil)
        let img = NSImage(cgImage: cg, size: NSSize(width: cg.width, height: cg.height))
        let pad = String(format: "%05d", index)
        let file = outURL.appendingPathComponent("frame_\(pad).png")
        guard let tiff = img.tiffRepresentation,
            let rep = NSBitmapImageRep(data: tiff),
            let png = rep.representation(using: .png, properties: [:])
        else {
            fputs("编码失败 frame \(index)\n", stderr)
            exit(1)
        }
        try png.write(to: file)
    } catch {
        fputs("抽帧 \(index) @\(CMTimeGetSeconds(t))s: \(error)\n", stderr)
        exit(1)
    }
    t = CMTimeAdd(t, step)
    index += 1
}

print("完成，共 \(index) 张 PNG → \(outputDir)")
