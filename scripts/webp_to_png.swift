#!/usr/bin/env swift
import AppKit
import Foundation

guard CommandLine.argc >= 3 else {
    fputs("Usage: webp_to_png.swift <input.webp-or-png> <output.png>\n", stderr)
    exit(1)
}

let input = URL(fileURLWithPath: CommandLine.arguments[1])
let output = URL(fileURLWithPath: CommandLine.arguments[2])

guard let img = NSImage(contentsOf: input) else {
    fputs("Failed to load image: \(input.path)\n", stderr)
    exit(2)
}

guard let tiff = img.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let pngData = rep.representation(using: .png, properties: [:]) else {
    fputs("Failed to encode PNG\n", stderr)
    exit(3)
}

do {
    try pngData.write(to: output)
    print("OK \(input.path) -> \(output.path) \(img.size.width)x\(img.size.height)")
} catch {
    fputs("Write error: \(error)\n", stderr)
    exit(4)
}
