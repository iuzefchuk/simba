import AppKit

let args = CommandLine.arguments
guard args.count == 5, let width = Int(args[2]), let height = Int(args[3]) else {
    FileHandle.standardError.write(Data("usage: svg2png <input.svg> <width> <height> <output.png>\n".utf8))
    exit(2)
}
guard let image = NSImage(contentsOf: URL(fileURLWithPath: args[1])) else {
    FileHandle.standardError.write(Data("cannot load \(args[1])\n".utf8))
    exit(1)
}
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4,
    hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else {
    exit(1)
}
bitmap.size = NSSize(width: width, height: height)
NSGraphicsContext.saveGraphicsState()
let context = NSGraphicsContext(bitmapImageRep: bitmap)
NSGraphicsContext.current = context
context?.imageInterpolation = .high
image.draw(in: NSRect(x: 0, y: 0, width: width, height: height), from: .zero, operation: .sourceOver, fraction: 1)
NSGraphicsContext.restoreGraphicsState()
guard let png = bitmap.representation(using: .png, properties: [:]) else { exit(1) }
try png.write(to: URL(fileURLWithPath: args[4]))
