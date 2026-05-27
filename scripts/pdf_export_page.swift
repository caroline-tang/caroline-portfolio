#!/usr/bin/env swift
import AppKit
import PDFKit
import Foundation

/// 导出 PDF 单页（1-based）为 PNG。
/// 用法: swift pdf_export_page.swift <in.pdf> <out.png> <page1Based> [targetWidth]

guard CommandLine.argc >= 4 else {
    fputs("Usage: pdf_export_page.swift <in.pdf> <out.png> <page1Based> [targetWidth]\n", stderr)
    exit(1)
}

let pdfPath = CommandLine.arguments[1]
let outPath = CommandLine.arguments[2]
let p1 = Int(CommandLine.arguments[3])!
let tw = CommandLine.argc >= 5 ? CGFloat(Double(CommandLine.arguments[4])!) : 1200

guard let doc = PDFDocument(url: URL(fileURLWithPath: pdfPath)),
      p1 >= 1, p1 <= doc.pageCount,
      let page = doc.page(at: p1 - 1) else {
    fputs("Bad PDF or page\n", stderr)
    exit(2)
}

let box: PDFDisplayBox = .mediaBox
let r = page.bounds(for: box)
let scale = tw / r.width
let size = NSSize(width: tw, height: r.height * scale)
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

guard let tiff = img.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let data = rep.representation(using: .png, properties: [:]) else {
    fputs("Encode fail\n", stderr)
    exit(3)
}
try data.write(to: URL(fileURLWithPath: outPath))
print("OK", outPath, Int(size.width), Int(size.height))
