//
//  UIImage+.swift
//  Anlaka
//
//  Created by 최정안 on 6/2/25.
//

import UIKit
import CoreImage

extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

extension UIImage {
    /// 이미지 3사분면(좌하단) 평균 밝기 계산 (0.0 = 완전 어두움, 1.0 = 완전 밝음)
    func averageBrightness() -> CGFloat? {
        return calculateBrightness(for: .thirdQuadrant)
    }
    
    /// 이미지 하위 1/3 부분 평균 밝기 계산 (0.0 = 완전 어두움, 1.0 = 완전 밝음)
    func averageBrightnessBottomThird() -> CGFloat? {
        return calculateBrightness(for: .bottomThird)
    }
    
    private enum BrightnessArea {
        case thirdQuadrant
        case bottomThird
    }
    
    private func calculateBrightness(for area: BrightnessArea) -> CGFloat? {
        guard let inputImage = CIImage(image: self) else { return nil }

        let extent = inputImage.extent
        let width = extent.width
        let height = extent.height
        
        let targetRect: CGRect
        
        switch area {
        case .thirdQuadrant:
            // 3사분면 영역 계산 (좌하단)
            let quarterWidth = width / 2
            let quarterHeight = height / 2
            targetRect = CGRect(
                x: extent.minX,
                y: extent.minY,
                width: quarterWidth,
                height: quarterHeight
            )
        case .bottomThird:
            // 하위 1/3 영역 계산
            let bottomThirdHeight = height / 3
            targetRect = CGRect(
                x: extent.minX,
                y: extent.minY,
                width: width,
                height: bottomThirdHeight
            )
        }
        
        let filter = CIFilter(name: "CIAreaAverage",
                              parameters: [kCIInputImageKey: inputImage,
                                           kCIInputExtentKey: CIVector(cgRect: targetRect)])

        guard let outputImage = filter?.outputImage else { return nil }

        let context = CIContext()
        var bitmap = [UInt8](repeating: 0, count: 4)

        context.render(outputImage,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: CGColorSpaceCreateDeviceRGB())

        let red = CGFloat(bitmap[0]) / 255.0
        let green = CGFloat(bitmap[1]) / 255.0
        let blue = CGFloat(bitmap[2]) / 255.0

        // 밝기 계산 (luminance, perceived brightness)
        let brightness = 0.299 * red + 0.587 * green + 0.114 * blue
        return brightness
    }
}

