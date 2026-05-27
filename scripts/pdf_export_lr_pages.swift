#!/usr/bin/env swift
import AppKit
import PDFKit
import Foundation

/// 将任意两页（1-based）左右拼成一张跨页 PNG，左=L 右=R（可非连续）。
/// 用法: swift pdf_export_lr_pages.swift <in.pdf> <out.png> <L> <R> [targetSinglePageWidth]
/// 例: swift ... album.pdf out.png 4 6 900

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

guard CommandLine.argc >= 5 else {
    fputs("Usage: pdf_export_lr_pages.swift <in.pdf> <out.png> <L> <R> [targetW]\n", stderr)
    exit(1)
}

let pdfPath = CommandLine.arguments[1]
let outPath = CommandLine.arguments[2]
let L = Int(CommandLine.arguments[3])!
let R = Int(CommandLine.arguments[4])!
let tw = CommandLine.argc >= 6 ? CGFloat(Double(CommandLine.arguments[5])!) : 900

guard let doc = PDFDocument(url: URL(fileURLWithPath: pdfPath)) else {
    fputs("Cannot open PDF\n", stderr)
    exit(2)
}
let n = doc.pageCount
guard L >= 1, L <= n, R >= 1, R <= n, let pL = doc.page(at: L - 1), let pR = doc.page(at: R - 1) else {
    fputs("Bad page range L=\(L) R=\(R) n=\(n)\n", stderr)
    exit(3)
}

let spread = compositeSideBySide(renderPageToImage(pL, targetWidth: tw), renderPageToImage(pR, targetWidth: tw))
guard let tiff = spread.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let data = rep.representation(using: .png, properties: [:]) else {
    fputs("Encode fail\n", stderr)
    exit(4)
}
try data.write(to: URL(fileURLWithPath: outPath))
print("OK \(outPath) \(Int(spread.size.width))x\(Int(spread.size.height)) L=\(L) R=\(R)")
