import AVFoundation
import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else {
    fputs("usage: ExtractVideoFrames <video> <output-directory>\n", stderr)
    exit(2)
}

let sourceURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

let asset = AVURLAsset(url: sourceURL)
let duration = try await asset.load(.duration)
let seconds = duration.seconds
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.maximumSize = NSSize(width: 1_600, height: 1_600)

for (index, fraction) in [0.03, 0.16, 0.32, 0.48, 0.64, 0.80, 0.96].enumerated() {
    let time = CMTime(seconds: seconds * fraction, preferredTimescale: 600)
    let (image, _) = try await generator.image(at: time)
    let bitmap = NSBitmapImageRep(cgImage: image)
    guard let data = bitmap.representation(using: .png, properties: [:]) else { continue }
    try data.write(to: outputURL.appendingPathComponent(String(format: "%02d.png", index)))
}

print(String(format: "duration=%.2fs frames=7", seconds))
