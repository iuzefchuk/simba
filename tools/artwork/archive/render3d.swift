import AppKit
import SceneKit
import Metal
import simd

func hash(_ x: Int, _ y: Int) -> Float {
    var h = UInt32(truncatingIfNeeded: x &* 374_761_393 &+ y &* 668_265_263)
    h = (h ^ (h >> 13)) &* 1_274_126_177
    h ^= h >> 16
    return Float(h & 0xFFFF) / 65535
}
func smooth(_ t: Float) -> Float { t * t * (3 - 2 * t) }
func mix(_ a: Float, _ b: Float, _ t: Float) -> Float { a + (b - a) * t }
func mix(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ t: Float) -> SIMD3<Float> { a + (b - a) * t }
func smoothstep(_ e0: Float, _ e1: Float, _ x: Float) -> Float { smooth(max(0, min(1, (x - e0) / (e1 - e0)))) }
func noise(_ x: Float, _ y: Float, period: Int) -> Float {
    let xi = Int(floor(x)), yi = Int(floor(y))
    let fx = smooth(x - floor(x)), fy = smooth(y - floor(y))
    func h(_ i: Int, _ j: Int) -> Float { hash(((i % period) + period) % period, j) }
    let a = mix(h(xi, yi), h(xi + 1, yi), fx)
    let b = mix(h(xi, yi + 1), h(xi + 1, yi + 1), fx)
    return mix(a, b, fy)
}
func fbm(_ x: Float, _ y: Float, period: Int, octaves: Int) -> Float {
    var sum: Float = 0, amp: Float = 0.5, fx = x, fy = y, p = period, norm: Float = 0
    for _ in 0..<octaves {
        sum += amp * noise(fx, fy, period: p); norm += amp
        amp *= 0.5; fx *= 2; fy *= 2; p *= 2
    }
    return sum / norm
}

typealias RGB = SIMD3<Float>
func rgb(_ r: Float, _ g: Float, _ b: Float) -> RGB { RGB(r, g, b) }

func makeImage(width: Int, height: Int, pixel: (Float, Float) -> RGB) -> NSImage {
    var data = [UInt8](repeating: 255, count: width * height * 4)
    for y in 0..<height {
        let v = (Float(y) + 0.5) / Float(height)
        for x in 0..<width {
            let u = (Float(x) + 0.5) / Float(width)
            let c = pixel(u, v)
            let i = (y * width + x) * 4
            data[i] = UInt8(max(0, min(255, c.x * 255)))
            data[i + 1] = UInt8(max(0, min(255, c.y * 255)))
            data[i + 2] = UInt8(max(0, min(255, c.z * 255)))
        }
    }
    let cs = CGColorSpaceCreateDeviceRGB()
    let ctx = CGContext(data: &data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                        space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    let cg = ctx.makeImage()!
    return NSImage(cgImage: cg, size: NSSize(width: width, height: height))
}

func surface(_ nu: Int, _ nv: Int, _ P: (Float, Float) -> SIMD3<Float>) -> SCNGeometry {
    var positions: [SCNVector3] = [], normals: [SCNVector3] = [], uvs: [CGPoint] = [], indices: [UInt32] = []
    for j in 0...nv {
        let v = Float(j) / Float(nv)
        for i in 0...nu {
            let u = Float(i) / Float(nu)
            let pos = P(u, v)
            let du = P(min(1, u + 0.002), v) - P(max(0, u - 0.002), v)
            let dv = P(u, min(1, v + 0.002)) - P(u, max(0, v - 0.002))
            var n = cross(dv, du)
            if length(n) < 1e-7 { n = SIMD3(0, v > 0.5 ? 1 : -1, 0) }
            n = normalize(n)
            positions.append(SCNVector3(pos)); normals.append(SCNVector3(n)); uvs.append(CGPoint(x: CGFloat(u), y: CGFloat(v)))
        }
    }
    let stride = UInt32(nu + 1)
    for j in 0..<nv {
        for i in 0..<nu {
            let a = UInt32(j) * stride + UInt32(i), b = a + 1, c = a + stride, d = c + 1
            indices += [a, c, b, b, c, d]
        }
    }
    let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
    return SCNGeometry(sources: [SCNGeometrySource(vertices: positions), SCNGeometrySource(normals: normals),
                                 SCNGeometrySource(textureCoordinates: uvs)], elements: [element])
}
func lathe(samples: Int, around: Int, profile: @escaping (Float) -> SIMD2<Float>) -> SCNGeometry {
    surface(around, samples) { u, v in
        let p = profile(v), a = u * 2 * Float.pi
        return SIMD3(p.x * cos(a), p.y, p.x * sin(a))
    }
}

let state = ProcessInfo.processInfo.environment["STATE"] ?? "open"
guard state == "open" || state == "closed" else { fatalError("STATE must be open or closed") }
let huskR: Float = 1.0, huskRi: Float = 0.76
let mouth: Float = 0.95
let notch: Float = state == "open" ? mouth : 0

struct SeededRandom: RandomNumberGenerator {
    var s: UInt64
    mutating func next() -> UInt64 {
        s &+= 0x9E37_79B9_7F4A_7C15
        var z = s
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

func shellProfile(_ v: Float) -> SIMD2<Float> {
    if v < 0.47 { let phi = mix(-Float.pi / 2, Float.pi / 2, v / 0.47); return SIMD2(huskR * cos(phi), huskR * sin(phi)) }
    if v < 0.50 { return SIMD2(0, mix(huskR, huskRi, (v - 0.47) / 0.03)) }
    if v < 0.97 { let phi = mix(Float.pi / 2, -Float.pi / 2, (v - 0.50) / 0.47); return SIMD2(huskRi * cos(phi), huskRi * sin(phi)) }
    return SIMD2(0, mix(-huskRi, -huskR, (v - 0.97) / 0.03))
}
func huskAngle(_ u: Float) -> Float { notch / 2 + u * (2 * Float.pi - notch) }
func huskP(_ u: Float, _ v: Float) -> SIMD3<Float> {
    let p = shellProfile(v), a = huskAngle(u)
    return SIMD3(p.x * cos(a), p.y, p.x * sin(a))
}
func cutFaceP(_ side: Float) -> (Float, Float) -> SIMD3<Float> {
    { s, t in
        let phi = mix(-Float.pi / 2, Float.pi / 2, s), rho = mix(huskRi, huskR, t), a = side * notch / 2
        return SIMD3(rho * cos(phi) * cos(a), rho * sin(phi), rho * cos(phi) * sin(a))
    }
}

let sage = rgb(0.54, 0.58, 0.29), sageDeep = rgb(0.34, 0.40, 0.16), cream = rgb(0.90, 0.85, 0.62)
func huskSkin(_ u: Float, _ e: Float) -> RGB { mix(sageDeep, sage, 0.8) }
func cutFaceColor(_ s: Float, _ t: Float) -> RGB {
    let fibre = noise(s * 400, t * 6, period: 400)
    var c = cream * (0.95 + 0.08 * fibre)
    c = mix(c, mix(sage, cream, 0.6), smoothstep(0.90, 1.0, t))
    return c
}
func innerWall(_ u: Float, _ depth: Float) -> RGB {
    let mottle = fbm(u * 12, depth * 8, period: 12, octaves: 3)
    var c = mix(rgb(0.88, 0.83, 0.61), rgb(0.60, 0.54, 0.37), smoothstep(0.05, 0.9, depth))
    c *= 0.94 + 0.12 * mottle
    return c
}
func huskDiffuse(_ u: Float, _ v: Float) -> RGB {
    let a = huskAngle(u)
    let fromMouth = min(a, 2 * Float.pi - a) / Float.pi
    if v < 0.47 { return huskSkin(u, v / 0.47) }
    if v < 0.50 || v >= 0.97 { return cream }
    return innerWall(u, fromMouth)
}
func huskRoughness(_ u: Float, _ v: Float) -> RGB { RGB(repeating: v < 0.47 ? 0.62 : 0.85) }

func conkerProfile(_ v: Float) -> SIMD2<Float> {
    let phi = mix(-Float.pi / 2, Float.pi / 2, v)
    let y = sin(phi) * (phi < 0 ? 0.80 : 1.0)
    return SIMD2(cos(phi), y) * 0.76
}
func conkerDiffuse(_ u: Float, _ v: Float) -> RGB {
    let cloud = fbm(u * 6, v * 5, period: 6, octaves: 3)
    let grain = noise(u * 500, v * 250, period: 500)
    var c = mix(rgb(0.30, 0.08, 0.045), rgb(0.40, 0.125, 0.065), smoothstep(0.35, 0.8, cloud))
    c = mix(c, rgb(0.46, 0.14, 0.08), 0.5)
    c = mix(c, rgb(0.19, 0.045, 0.03), smoothstep(0.80, 1.0, v) * 0.6)
    c *= 0.97 + 0.06 * grain
    let edge = 0.17 + 0.03 * sin(2 * Float.pi * 3 * u + 1) + 0.02 * (noise(u * 9, 2.2, period: 9) - 0.5)
    let hilum = rgb(0.78, 0.66, 0.48) * (0.93 + 0.1 * fbm(u * 20, v * 20, period: 20, octaves: 3))
    return mix(hilum, c, smoothstep(edge - 0.01, edge + 0.01, v))
}
func conkerRoughness(_ u: Float, _ v: Float) -> RGB { RGB(repeating: mix(0.85, 0.42, smoothstep(0.15, 0.19, v))) }

func material(diffuse: Any, roughness: Any) -> SCNMaterial {
    let m = SCNMaterial()
    m.lightingModel = .physicallyBased
    m.diffuse.contents = diffuse
    m.roughness.contents = roughness
    m.metalness.contents = 0.0
    m.isDoubleSided = true
    return m
}

let cameraPosition = SIMD3<Float>(0.0, 1.35, 6.3)

func buildScene(groundShadow: Bool) -> (SCNScene, SCNNode) {
    let scene = SCNScene()
    var rng = SeededRandom(s: 7)

    let husk = SCNNode()
    let yAxis = normalize(SIMD3<Float>(0.68, -0.12, 0.72))
    var xAxis = normalize(SIMD3<Float>(-1.0, 0.30, 0.0))
    xAxis = normalize(xAxis - yAxis * dot(xAxis, yAxis))
    let zAxis = cross(xAxis, yAxis)
    husk.simdOrientation = simd_quatf(simd_float3x3(columns: (xAxis, yAxis, zAxis)))
    let localDown = husk.simdOrientation.inverse.act(SIMD3(0, -1, 0))

    let shell = SCNNode(geometry: surface(300, 220, huskP))
    shell.geometry?.materials = [material(diffuse: makeImage(width: 2048, height: 1024, pixel: huskDiffuse),
                                          roughness: makeImage(width: 512, height: 256, pixel: huskRoughness))]
    husk.addChildNode(shell)
    if notch > 0 {
        for side: Float in [-1, 1] {
            let face = SCNNode(geometry: surface(120, 24, cutFaceP(side)))
            face.geometry?.materials = [material(diffuse: makeImage(width: 1024, height: 128, pixel: cutFaceColor), roughness: 0.85)]
            husk.addChildNode(face)
        }
    }

    let thornMat = material(diffuse: makeImage(width: 4, height: 64) { _, v in mix(sage * 0.95, rgb(0.74, 0.76, 0.42), smoothstep(0.35, 1.0, v)) },
                            roughness: 0.6)
    let foot: Float = 0.17
    let baseRadius: Float = 0.13, heights: ClosedRange<Float> = 0.30...0.36
    var thornCount = 0
    func placeThorn(_ d: SIMD3<Float>) {
        let ang = atan2(d.z, d.x)
        let perp = sqrt(max(0, 1 - d.y * d.y))
        if perp < foot || abs(ang) < mouth / 2 + asin(min(1, foot / perp)) { return }
        if dot(d, localDown) > 0.90 { return }
        let base = d * huskR
        let h = Float.random(in: heights, using: &rng)
        let thorn = lathe(samples: 20, around: 14) { v in
            SIMD2(baseRadius * pow(1 - v, 1.5) + 0.25 * baseRadius * pow(1 - v, 7) + 0.003, v * h)
        }
        thorn.materials = [thornMat]
        let node = SCNNode(geometry: thorn)
        var q = simd_quatf(from: SIMD3(0, 1, 0), to: d)
        let tiltAxis = normalize(cross(d, SIMD3(Float.random(in: -1...1, using: &rng), Float.random(in: -1...1, using: &rng), Float.random(in: -1...1, using: &rng))))
        q = simd_quatf(angle: Float.random(in: 0...0.08, using: &rng), axis: tiltAxis) * q
        node.simdOrientation = q
        node.simdPosition = base - d * 0.035
        husk.addChildNode(node)
        thornCount += 1
    }
    let n = 41
    for i in 0..<n {
        let y = 1 - 2 * (Float(i) + 0.5) / Float(n)
        let r = sqrt(max(0, 1 - y * y)), a = Float(i) * 2.399963
        placeThorn(SIMD3(r * cos(a), y, r * sin(a)))
    }
    print("\(thornCount) thorns, husk \(state)")
    scene.rootNode.addChildNode(husk)

    if notch > 0 {
        let conker = SCNNode(geometry: lathe(samples: 160, around: 240, profile: conkerProfile))
        conker.geometry?.materials = [material(diffuse: makeImage(width: 2048, height: 1024, pixel: conkerDiffuse),
                                               roughness: makeImage(width: 512, height: 256, pixel: conkerRoughness))]
        conker.simdPosition = SIMD3(-0.12, 0.0, 0.03)
        conker.simdOrientation = simd_quatf(angle: 0.9, axis: SIMD3(0, 1, 0))
        scene.rootNode.addChildNode(conker)
    }

    if groundShadow {
        let floor = SCNNode(geometry: SCNPlane(width: 5, height: 5))
        floor.geometry?.firstMaterial?.lightingModel = .shadowOnly
        floor.eulerAngles.x = -.pi / 2
        floor.simdPosition = SIMD3(0, -1.05, 0)
        scene.rootNode.addChildNode(floor)
    }

    func light(_ type: SCNLight.LightType, _ intensity: CGFloat, _ color: NSColor, at: SIMD3<Float>, shadow: Bool = false) -> SCNNode {
        let l = SCNLight(); l.type = type; l.intensity = intensity; l.color = color
        if shadow {
            l.castsShadow = true; l.shadowRadius = 24; l.shadowSampleCount = 64
            l.shadowColor = NSColor(white: 0, alpha: 0.6); l.shadowMapSize = CGSize(width: 2048, height: 2048)
        }
        let n = SCNNode(); n.light = l; n.simdPosition = at; n.look(at: SCNVector3(0, -0.1, 0))
        return n
    }
    scene.rootNode.addChildNode(light(.directional, 1000, NSColor(red: 1.0, green: 0.98, blue: 0.92, alpha: 1), at: SIMD3(-3, 7, 3), shadow: true))
    scene.rootNode.addChildNode(light(.directional, 200, NSColor(red: 0.92, green: 0.94, blue: 0.90, alpha: 1), at: SIMD3(6, 2, 2)))
    scene.rootNode.addChildNode(light(.directional, 300, NSColor(red: 1.0, green: 0.96, blue: 0.86, alpha: 1), at: SIMD3(-5, -0.5, 5)))
    scene.rootNode.addChildNode(light(.directional, 160, NSColor(white: 1, alpha: 1), at: SIMD3(2, 3, -6)))
    let ambient = SCNLight(); ambient.type = .ambient; ambient.intensity = 80
    let ambientNode = SCNNode(); ambientNode.light = ambient; scene.rootNode.addChildNode(ambientNode)

    scene.lightingEnvironment.contents = makeImage(width: 512, height: 256) { u, v in
        let up = 1 - v
        var c = mix(rgb(0.12, 0.13, 0.08), rgb(0.42, 0.44, 0.28), smoothstep(0.15, 0.48, up))
        c = mix(c, rgb(0.92, 0.93, 0.90), smoothstep(0.50, 0.85, up))
        let box = smoothstep(0.10, 0.16, u) * (1 - smoothstep(0.34, 0.40, u)) * smoothstep(0.58, 0.63, up) * (1 - smoothstep(0.86, 0.91, up))
        c = mix(c, rgb(1, 1, 1), box)
        return c
    }
    scene.lightingEnvironment.intensity = 1.5

    let camera = SCNCamera()
    camera.fieldOfView = 30
    camera.zNear = 0.1; camera.zFar = 100
    camera.screenSpaceAmbientOcclusionIntensity = 0.8
    camera.screenSpaceAmbientOcclusionRadius = 0.45
    let cameraNode = SCNNode(); cameraNode.camera = camera
    cameraNode.simdPosition = cameraPosition
    cameraNode.look(at: SCNVector3(0, 0, 0))
    scene.rootNode.addChildNode(cameraNode)
    return (scene, cameraNode)
}

func pixels(_ image: NSImage, size: Int) -> [Float] {
    guard let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) else { fatalError("no bitmap") }
    var out = [Float](repeating: 0, count: size * size * 3)
    for y in 0..<size { for x in 0..<size {
        let c = rep.colorAt(x: x, y: y)!
        let i = (y * size + x) * 3
        out[i] = Float(c.redComponent); out[i + 1] = Float(c.greenComponent); out[i + 2] = Float(c.blueComponent)
    } }
    return out
}

let outDir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
let background = ProcessInfo.processInfo.environment["ICON_BG"] ?? "white"
let backgrounds: [String: (top: RGB, bottom: RGB)] = [
    "white": (rgb(1, 1, 1), rgb(1, 1, 1)),
    "olive": (rgb(0.51, 0.52, 0.33), rgb(0.39, 0.42, 0.27)),
    "khaki": (rgb(0.86, 0.84, 0.70), rgb(0.64, 0.62, 0.46)),
    "light": (rgb(0.97, 0.96, 0.93), rgb(0.84, 0.82, 0.76)),
]
guard let bgColors = backgrounds[background] else { fatalError("ICON_BG must be one of \(backgrounds.keys.sorted())") }
let groundShadow = background != "white"
let size = 2048
let (scene, cameraNode) = buildScene(groundShadow: groundShadow)
guard let device = MTLCreateSystemDefaultDevice() else { fatalError("no Metal device") }
let renderer = SCNRenderer(device: device, options: nil)
renderer.scene = scene
renderer.pointOfView = cameraNode
renderer.autoenablesDefaultLighting = false
renderer.isJitteringEnabled = true

func render(background: NSColor) -> [Float] {
    scene.background.contents = background
    let img = renderer.snapshot(atTime: 0, with: CGSize(width: size, height: size), antialiasingMode: .multisampling4X)
    return pixels(img, size: size)
}
let onBlack = render(background: .black)
let onWhite = render(background: .white)

var rgba = [UInt8](repeating: 0, count: size * size * 4)
for i in 0..<(size * size) {
    let wr = onWhite[i * 3], wg = onWhite[i * 3 + 1], wb = onWhite[i * 3 + 2]
    let br = onBlack[i * 3], bg = onBlack[i * 3 + 1], bb = onBlack[i * 3 + 2]
    var alpha = max(0, min(1, 1 - ((wr - br) + (wg - bg) + (wb - bb)) / 3))
    alpha *= smoothstep(0.04, 0.12, alpha)
    let r = alpha > 0.002 ? min(1, br / alpha) : 0, g = alpha > 0.002 ? min(1, bg / alpha) : 0, b = alpha > 0.002 ? min(1, bb / alpha) : 0
    rgba[i * 4] = UInt8(r * 255); rgba[i * 4 + 1] = UInt8(g * 255); rgba[i * 4 + 2] = UInt8(b * 255); rgba[i * 4 + 3] = UInt8(alpha * 255)
}
let cs = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(data: &rgba, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4, space: cs,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
let renderCG = ctx.makeImage()!

func writePNG(_ cg: CGImage, to url: URL) {
    let rep = NSBitmapImageRep(cgImage: cg)
    try! rep.representation(using: .png, properties: [:])!.write(to: url)
}
writePNG(renderCG, to: outDir.appendingPathComponent("render.png"))
print("rendered into \(outDir.path)")
