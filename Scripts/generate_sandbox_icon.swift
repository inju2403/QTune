#!/usr/bin/env swift

import AppKit
import CoreGraphics

// 원본 아이콘 경로
let originalIconPath = "Projects/App/Resources/Assets.xcassets/AppIcon.appiconset/QTune_AppIcon_1024.png"
let outputPath = "Projects/App/Resources/Assets.xcassets/AppIcon-Sandbox.appiconset/QTune_AppIcon_Sandbox_1024.png"

// 디렉토리 생성
let fileManager = FileManager.default
let outputDir = "Projects/App/Resources/Assets.xcassets/AppIcon-Sandbox.appiconset"
if !fileManager.fileExists(atPath: outputDir) {
    try! fileManager.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
}

// 원본 이미지 로드
guard let originalImage = NSImage(contentsOfFile: originalIconPath) else {
    print("❌ Failed to load original icon")
    exit(1)
}

// 비트맵으로 변환하여 작업 (더 효율적)
let size = NSSize(width: 1024, height: 1024)
guard let bitmapRep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(size.width),
    pixelsHigh: Int(size.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    print("❌ Failed to create bitmap")
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)

// 원본 이미지 그리기 (크기 변경 없이 원본 그대로!)
originalImage.draw(in: NSRect(origin: .zero, size: size))

// 하단 배경 (십자가 밑 검은 부분까지 덮을 정도로 높이 설정)
let bannerHeight: CGFloat = 320  // 적당히 낮춤
let bannerRect = NSRect(x: 0, y: 0, width: size.width, height: bannerHeight)

// 그라데이션 배경
let gradient = NSGradient(colors: [
    NSColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.95),
    NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.95)
])!
gradient.draw(in: bannerRect, angle: -90)

// "Sandbox" 텍스트
let text = "Sandbox"
let textAttributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 170, weight: .bold),  // 텍스트 더 크게
    .foregroundColor: NSColor.white
]

let textSize = text.size(withAttributes: textAttributes)
let textX = (size.width - textSize.width) / 2  // X축 중앙
let textY = (bannerHeight - textSize.height) / 2  // Y축도 정확히 중앙

text.draw(at: NSPoint(x: textX, y: textY), withAttributes: textAttributes)

NSGraphicsContext.restoreGraphicsState()

// PNG로 저장 (압축 레벨 설정)
guard let pngData = bitmapRep.representation(
    using: .png,
    properties: [.compressionFactor: 0.9]
) else {
    print("❌ Failed to create PNG data")
    exit(1)
}

try! pngData.write(to: URL(fileURLWithPath: outputPath))

// Contents.json 생성
let contentsJson = """
{
  "images" : [
    {
      "filename" : "QTune_AppIcon_Sandbox_1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""

let contentsPath = "\(outputDir)/Contents.json"
try! contentsJson.write(toFile: contentsPath, atomically: true, encoding: .utf8)

print("✅ Sandbox app icon generated at: \(outputPath)")
print("✅ Contents.json created")