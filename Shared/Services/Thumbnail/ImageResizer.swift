import Foundation
import UIKit

/// Utility for resizing images to thumbnail sizes
struct ImageResizer {
    /// Standard thumbnail sizes
    enum ThumbnailSize {
        /// Small size - 88px width (for list rows, 2x)
        case small

        /// Medium size - 160px width (for cards, 2x)
        case medium

        /// Large size - 240px width (for detail view, 2x)
        case large

        /// Custom size with specific width
        case custom(width: CGFloat)

        var width: CGFloat {
            switch self {
            case .small: return 88
            case .medium: return 160
            case .large: return 240
            case .custom(let width): return width
            }
        }
    }

    /// JPEG compression quality for thumbnails
    static let compressionQuality: CGFloat = 0.8

    /// Resize a UIImage to the specified thumbnail size
    /// - Parameters:
    ///   - image: The source image
    ///   - size: The target thumbnail size
    /// - Returns: JPEG data of the resized image, or nil if resizing fails
    static func resize(_ image: UIImage, to size: ThumbnailSize) -> Data? {
        let targetWidth = size.width

        // Calculate target size maintaining aspect ratio
        let aspectRatio = image.size.height / image.size.width
        let targetHeight = targetWidth * aspectRatio

        let targetSize = CGSize(width: targetWidth, height: targetHeight)

        // Use UIGraphicsImageRenderer for efficient resizing
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        return resizedImage.jpegData(compressionQuality: compressionQuality)
    }

    /// Resize image data to the specified thumbnail size
    /// - Parameters:
    ///   - data: The source image data
    ///   - size: The target thumbnail size
    /// - Returns: JPEG data of the resized image, or nil if resizing fails
    static func resize(_ data: Data, to size: ThumbnailSize) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        return resize(image, to: size)
    }

    /// Resize an image to fit within a maximum dimension while maintaining aspect ratio
    /// - Parameters:
    ///   - image: The source image
    ///   - maxDimension: The maximum width or height
    /// - Returns: JPEG data of the resized image, or nil if resizing fails
    static func resizeToFit(_ image: UIImage, maxDimension: CGFloat) -> Data? {
        let originalSize = image.size

        // Check if resizing is needed
        if originalSize.width <= maxDimension && originalSize.height <= maxDimension {
            return image.jpegData(compressionQuality: compressionQuality)
        }

        // Calculate scale factor
        let widthScale = maxDimension / originalSize.width
        let heightScale = maxDimension / originalSize.height
        let scale = min(widthScale, heightScale)

        let targetSize = CGSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        return resizedImage.jpegData(compressionQuality: compressionQuality)
    }

    /// Create a square crop of an image (center crop)
    /// - Parameters:
    ///   - image: The source image
    ///   - size: The target square size
    /// - Returns: JPEG data of the cropped and resized image, or nil if processing fails
    static func squareCrop(_ image: UIImage, size: CGFloat) -> Data? {
        let originalSize = image.size
        let minDimension = min(originalSize.width, originalSize.height)

        // Calculate crop rect (center crop)
        let cropRect = CGRect(
            x: (originalSize.width - minDimension) / 2,
            y: (originalSize.height - minDimension) / 2,
            width: minDimension,
            height: minDimension
        )

        // Crop the image
        guard let cgImage = image.cgImage,
              let croppedCGImage = cgImage.cropping(to: cropRect) else {
            return nil
        }

        let croppedImage = UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)

        // Resize to target size
        let targetSize = CGSize(width: size, height: size)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            croppedImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        return resizedImage.jpegData(compressionQuality: compressionQuality)
    }

    /// Get image dimensions without loading full image into memory
    /// - Parameter data: The image data
    /// - Returns: The image size, or nil if it cannot be determined
    static func imageDimensions(from data: Data) -> CGSize? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
              let height = properties[kCGImagePropertyPixelHeight] as? CGFloat else {
            return nil
        }
        return CGSize(width: width, height: height)
    }
}
