#!/usr/bin/env swift
import AppKit
import PDFKit
import Foundation

/// 导出 PDF 跨页 PNG：左页 N，右页 N+1。
/// 用法: swift pdf_export_spreads.swift <in.pdf> <outDir> <左页1-based> ...

func renderPageToImage(_ page: PDFPage, targetWidth: CGFloat) -> NSImage {
    let box: PDFDisplayBox = .mediaBox
    let r = page.bounds(for: box)
    let scale = targetWidth / r.width
    let size = NSSize(width: targetWidth, height: r.height * scale)
    let img = NSImage(size: size)
    img.lockFocus()
    if let ctx = NSGraphicsContext.current?.cgContext {
        ctx.saveGState()
        ctx.translateBy(x: 0, y: size.height)
        ctx.scaleBy(x: scale, y: -scale)
        page.draw(with: box, to: ctx)
        ctx.restoreGState()
    }
    img.unlockFocus()
    return img
}

func compositeSideBySide(_ left: NSImage, _ right: NSImage) -> NSImage {
    let w = left.size.width + right.size.width
    let h = max(left.size.height, right.size.height)
    let out = NSImage(size: NSSize(width: w, height: h))
    out.lockFocus()
    NSColor.white.set()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: w, height: h)).fill()
    let yL = (h - left.size.height) / 2
    let yR = (h - right.size.height) / 2
    left.draw(at: NSPoint(x: 0, y: yL), from: .zero, operation: .sourceOver, fraction: 1)
    right.draw(at: NSPoint(x: left.size.width, y: yR), from: .zero, operation: .sourceOver, fraction: 1)
    out.unlockFocus()
    return out
}

guard CommandLine.argc >= 4 else {
    fputs("Usage: pdf_export_spreads.swift <in.pdf> <outDir> <leftPage1Based...>\n", stderr)
    exit(1)
}

let pdfPath = CommandLine.arguments[1]
let outDir = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
let leftPages = CommandLine.arguments.dropFirst(3).compactMap { Int($0) }

guard let doc = PDFDocument(url: URL(fileURLWithPath: pdfPath)) else {
    fputs("Cannot open PDF: \(pdfPath)\n", stderr)
    exit(2)
}

let count = doc.pageCount
print("PDF pages: \(count)")

try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

let targetSinglePageWidth: CGFloat = 900

for L in leftPages {
    let R = L + 1
    guard L >= 1, R <= count, let pL = doc.page(at: L - 1), let pR = doc.page(at: R - 1) else {
        fputs("Skip spread \(L)-\(R)\n", stderr)
        continue
    }
    let imgL = renderPageToImage(pL, targetWidth: targetSinglePageWidth)
    let imgR = renderPageToImage(pR, targetWidth: targetSinglePageWidth)
    let spread = compositeSideBySide(imgL, imgR)

    guard let tiff = spread.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let data = rep.representation(using: .png, properties: [:]) else {
        fputs("Encode fail \(L)-\(R)\n", stderr)
        continue
    }
    let name = String(format: "spread-%02d-%02d.png", L, R)
    let url = outDir.appendingPathComponent(name)
    try data.write(to: url)
    print("OK \(url.path) size \(Int(spread.size.width))x\(Int(spread.size.height))")
}
