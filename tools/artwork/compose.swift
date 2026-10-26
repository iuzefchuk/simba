import AppKit

let args = CommandLine.arguments
guard args.count == 4 else {
    FileHandle.standardError.write(Data("usage: compose <active.png> <idle.png> <Simba.xcassets>\n".utf8))
    exit(2)
}
let masterURL = URL(fileURLWithPath: args[1])
let idleURL = URL(fileURLWithPath: args[2])
let assets = URL(fileURLWithPath: args[3])
let cs = CGColorSpaceCreateDeviceRGB()

typealias RGB = SIMD3<Double>
func rgb(_ r: Double, _ g: Double, _ b: Double) -> RGB { RGB(r, g, b) }
let backgrounds: [String: (top: RGB, bottom: RGB)] = [
    "white": (rgb(1, 1, 1), rgb(1, 1, 1)),
    "olive": (rgb(0.51, 0.52, 0.33), rgb(0.39, 0.42, 0.27)),
    "khaki": (rgb(0.86, 0.84, 0.70), rgb(0.64, 0.62, 0.46)),
    "light": (rgb(0.97, 0.96, 0.93), rgb(0.84, 0.82, 0.76)),
]
let background = ProcessInfo.processInfo.environment["ICON_BG"] ?? "white"
guard let bg = backgrounds[background] else { fatalError("ICON_BG must be one of \(backgrounds.keys.sorted())") }
let groundShadow = background != "white"

func loadImage(_ url: URL) -> CGImage {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { fatalError("cannot read \(url.path)") }
    return image
}
let master = loadImage(masterURL), idle = loadImage(idleURL)
let size = master.width
guard master.height == size, idle.width == size, idle.height == size else { fatalError("masters must be square and the same size") }
var rgba = [UInt8](repeating: 0, count: size * size * 4)
do {
    let ctx = CGContext(data: &rgba, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4, space: cs,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.draw(master, in: CGRect(x: 0, y: 0, width: size, height: size))
}
var minX = size, minY = size, maxX = 0, maxY = 0
for y in 0..<size { for x in 0..<size where rgba[(y * size + x) * 4 + 3] > 150 {
    minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
} }
guard maxX >= minX else { fatalError("the master is empty") }
let objW = CGFloat(maxX - minX + 1), objH = CGFloat(maxY - minY + 1)
let objCX = CGFloat(minX) + objW / 2, objCY = CGFloat(minY) + objH / 2

func writePNG(_ cg: CGImage, to url: URL) {
    let rep = NSBitmapImageRep(cgImage: cg)
    try! rep.representation(using: .png, properties: [:])!.write(to: url)
}
func context(_ side: CGFloat) -> CGContext {
    let c = CGContext(data: nil, width: Int(side), height: Int(side), bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    c.interpolationQuality = .high
    return c
}
func place(_ c: CGContext, _ image: CGImage = master, canvas: CGFloat, maxSide: CGFloat, center: CGPoint) {
    let s = maxSide / max(objW, objH)
    let left = center.x - objCX * s
    let top = center.y - objCY * s
    c.draw(image, in: CGRect(x: left, y: canvas - top - CGFloat(size) * s, width: CGFloat(size) * s, height: CGFloat(size) * s))
}
func color(_ c: RGB) -> CGColor { NSColor(red: c.x, green: c.y, blue: c.z, alpha: 1).cgColor }

func appIcon() -> CGImage {
    let c = context(1024)
    c.addPath(CGPath(roundedRect: CGRect(x: 100, y: 100, width: 824, height: 824), cornerWidth: 186, cornerHeight: 186, transform: nil))
    c.clip()
    c.drawLinearGradient(CGGradient(colorsSpace: cs, colors: [color(bg.top), color(bg.bottom)] as CFArray, locations: [0, 1])!,
                         start: CGPoint(x: 512, y: 1024), end: CGPoint(x: 512, y: 0), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    let maxSide: CGFloat = 700, center = CGPoint(x: 512, y: 512)
    if groundShadow {
        let s = maxSide / max(objW, objH)
        let groundY = 1024 - (center.y + (CGFloat(maxY) - objCY) * s)
        c.saveGState()
        c.translateBy(x: center.x - 70, y: groundY + 12); c.scaleBy(x: 1, y: 0.28)
        let pool = CGGradient(colorsSpace: cs, colors: [NSColor(white: 0, alpha: 0.62).cgColor, NSColor(white: 0, alpha: 0).cgColor] as CFArray, locations: [0, 1])!
        c.drawRadialGradient(pool, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: maxSide * 0.62, options: [])
        c.restoreGState()
    }
    place(c, canvas: 1024, maxSide: maxSide, center: center)
    return c.makeImage()!
}
func scaled(_ image: CGImage, to side: CGFloat, alpha: CGFloat = 1) -> CGImage {
    let c = context(side)
    c.setAlpha(alpha)
    c.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
    return c.makeImage()!
}

func write(_ image: CGImage, points: Int, scale: Int, to set: URL) {
    writePNG(image, to: set.appendingPathComponent(scale == 1 ? "\(points).png" : "\(points)@\(scale)x.png"))
}

let icon = appIcon()
let iconSet = assets.appendingPathComponent("appiconset/Main.appiconset")
for points in [16, 32, 128, 256, 512] {
    write(scaled(icon, to: CGFloat(points)), points: points, scale: 1, to: iconSet)
    write(scaled(icon, to: CGFloat(points * 2)), points: points, scale: 2, to: iconSet)
}

let markSet = assets.appendingPathComponent("imageset/Mark.imageset")
for scale in [2, 1] {
    let side = CGFloat(360 * scale)
    let c = context(side)
    place(c, canvas: side, maxSide: side * 0.82, center: CGPoint(x: side / 2, y: side * 0.47))
    write(c.makeImage()!, points: 360, scale: scale, to: markSet)
}

func menuMaster(_ image: CGImage) -> CGImage {
    let c = context(288)
    place(c, image, canvas: 288, maxSide: 288 * 0.86, center: CGPoint(x: 144, y: 144))
    return c.makeImage()!
}
for (set, image) in [("imageset/MenuBarActive.imageset", master), ("imageset/MenuBarIdle.imageset", idle)] {
    let dir = assets.appendingPathComponent(set)
    let small = menuMaster(image)
    write(scaled(small, to: 36), points: 18, scale: 2, to: dir)
    write(scaled(small, to: 18), points: 18, scale: 1, to: dir)
}
print("composed \(assets.lastPathComponent) from \(masterURL.lastPathComponent) + \(idleURL.lastPathComponent) (background: \(background))")
