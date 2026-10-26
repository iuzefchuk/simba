import AppKit
import Vision
import CoreImage
let args = CommandLine.arguments
guard args.count == 3 else { FileHandle.standardError.write(Data("usage: subjectmask <in> <out>\n".utf8)); exit(2) }
let handler = VNImageRequestHandler(url: URL(fileURLWithPath: args[1]), options: [:])
let request = VNGenerateForegroundInstanceMaskRequest()
try handler.perform([request])
guard let result = request.results?.first else { FileHandle.standardError.write(Data("no subject found\n".utf8)); exit(1) }
let buffer = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
let ci = CIImage(cvPixelBuffer: buffer)
let cg = CIContext().createCGImage(ci, from: ci.extent)!
let rep = NSBitmapImageRep(cgImage: cg)
try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: args[2]))
print("mask \(cg.width)x\(cg.height), \(result.allInstances.count) instance(s)")
