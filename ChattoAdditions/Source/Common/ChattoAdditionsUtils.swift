//
// The MIT License (MIT)
//
// Copyright (c) 2015-present Badoo Trading Limited.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import Foundation
import CoreGraphics

private let scale = UIScreen.main.scale

public enum HorizontalAlignment {
    case left
    case center
    case right
}

public enum VerticalAlignment {
    case top
    case center
    case bottom
}

public extension CGSize {
    func bmaInsetBy(dxValue: CGFloat, dyValue: CGFloat) -> CGSize {
        return CGSize(width: self.width - dxValue, height: self.height - dyValue)
    }

    func bmaOutsetBy(dxValue: CGFloat, dyValue: CGFloat) -> CGSize {
        return self.bmaInsetBy(dxValue: -dxValue, dyValue: -dyValue)
    }
}

public extension CGSize {
    func bmaRound() -> CGSize {
        return CGSize(width: self.width.bmaRound(), height: self.height.bmaRound())
    }

    func bmaRect(inContainer containerRect: CGRect, xAlignament: HorizontalAlignment,
                 yAlignment: VerticalAlignment, dxValue: CGFloat, dyValue: CGFloat) -> CGRect {
        var originX: CGFloat
        var originY: CGFloat

        // Horizontal alignment
        switch xAlignament {
        case .left:
            originX = 0
        case .center:
            originX = containerRect.midX - self.width / 2.0
        case .right:
            originX = containerRect.maxY - self.width
        }

        // Vertical alignment
        switch yAlignment {
        case .top:
            originY = 0
        case .center:
            originY = containerRect.midY - self.height / 2.0
        case .bottom:
            originY = containerRect.maxY - self.height
        }

        return CGRect(origin: CGPoint(x: originX, y: originY).bmaOffsetBy(dxx: dxValue, dyy: dyValue), size: self)
    }
}

public extension CGRect {
    var bmaBounds: CGRect {
        return CGRect(origin: CGPoint.zero, size: self.size)
    }

    var bmaCenter: CGPoint {
        return CGPoint(x: self.midX, y: self.midY)
    }

    var bmaMaxY: CGFloat {
        get {
            return self.maxY
        }
        set {
            let delta = newValue - self.maxY
            self.origin = self.origin.bmaOffsetBy(dxx: 0, dyy: delta)
        }
    }

    func bmaRound() -> CGRect {
        let origin = CGPoint(x: self.origin.x.bmaRound(), y: self.origin.y.bmaRound())
        return CGRect(origin: origin, size: self.size.bmaRound())
    }
}

public extension CGPoint {
    func bmaOffsetBy(dxx: CGFloat, dyy: CGFloat) -> CGPoint {
        return CGPoint(x: self.x + dxx, y: self.y + dyy)
    }
}

public extension CGFloat {
    func bmaRound() -> CGFloat {
        return ceil(self * scale) * (1.0 / scale)
    }
}

public extension UIView {
    var bmaRect: CGRect {
        get {
            return CGRect(origin: CGPoint(x: self.center.x - self.bounds.width / 2, y: self.center.y - self.bounds.height), size: self.bounds.size)
        }
        set {
            let roundedRect = newValue.bmaRound()
            self.bounds = roundedRect.bmaBounds
            self.center = roundedRect.bmaCenter
        }
    }
}

public extension UIEdgeInsets {

    var bmaHorziontalInset: CGFloat {
        return self.left + self.right
    }

    var bmaVerticalInset: CGFloat {
        return self.top + self.bottom
    }

    var bmaHashValue: Int {
        return self.top.hashValue ^ self.left.hashValue ^ self.bottom.hashValue ^ self.right.hashValue
    }

}

public extension UIImage {

    func bmaTintWithColor(_ color: UIColor) -> UIImage {
        let rect = CGRect(origin: CGPoint.zero, size: self.size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        color.setFill()
        context.fill(rect)
        self.draw(in: rect, blendMode: .destinationIn, alpha: 1)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image.resizableImage(withCapInsets: self.capInsets)
    }

    func bmaBlendWithColor(_ color: UIColor) -> UIImage {
        let rect = CGRect(origin: CGPoint.zero, size: self.size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: 0, y: rect.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setBlendMode(.normal)
        context.draw(self.cgImage!, in: rect)
        context.clip(to: rect, mask: self.cgImage!)
        color.setFill()
        context.addRect(rect)
        context.drawPath(using: .fill)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image.resizableImage(withCapInsets: self.capInsets)
    }

    static func bmaImageWithColor(_ color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRect(origin: CGPoint.zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}

public extension UIColor {
    static func bmaColor(rgb: Int) -> UIColor {
        return UIColor(red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0, green: CGFloat((rgb & 0xFF00) >> 8) / 255.0, blue: CGFloat(rgb & 0xFF) / 255.0, alpha: 1.0)
    }

    func bmaBlendWithColor(_ color: UIColor) -> UIColor {
        var r11: CGFloat = 0
        var r22: CGFloat = 0
        var g11: CGFloat = 0
        var g22: CGFloat = 0
        var b11: CGFloat = 0
        var b22: CGFloat = 0
        var a11: CGFloat = 0
        var a22: CGFloat = 0
        self.getRed(&r11, green: &g11, blue: &b11, alpha: &a11)
        color.getRed(&r22, green: &g22, blue: &b22, alpha: &a22)
        let alpha = a22
        let beta = 1 - alpha
        let rrr = r11 * beta + r22 * alpha
        let ggg = g11 * beta + g22 * alpha
        let bbb = b11 * beta + b22 * alpha
        return UIColor(red: rrr, green: ggg, blue: bbb, alpha: 1)
    }
}

enum ScreenMetrics {
    case undefined
    
    /// iPhone 4, 4s
    case inch3dot5
    
    /// iPhone 5, 5s, 5c, SE
    case inch4
    
    /// iPhone 6, 6s, 7, 8
    case inch4dot7
    
    /// iPhone 6+, 6s+, 7+, 8+
    case inch5dot5
    
    /// iPhone X, XS
    case inch5dot8
    
    /// iPhone XR
    case inch6dot1
    
    /// iPhone XMax
    case inch6dot5
    
    /// iPad, iPad Air, iPad Pro 9.7, iPad Pro 10.5
    case iPad
    
    /// iPad Pro 12.9
    case iPad12dot9
}

private extension ScreenMetrics {
    var heightInPoints: CGFloat {
        switch self {
        case .undefined: // iPhoneX
            return 812
        case .inch3dot5:
            return 480
        case .inch4:
            return 568
        case .inch4dot7:
            return 667
        case .inch5dot5:
            return 736
        case .inch5dot8:
            return 812
        case .inch6dot1, .inch6dot5:
            return 896
        case .iPad:
            return 1024
        case .iPad12dot9:
            return 1366
        }
    }
}

extension UIScreen {
    private var epsilon: CGFloat {
        return 1/self.scale
    }
    
    var pointsPerPixel: CGFloat {
        return self.epsilon
    }
    
    var screenMetric: ScreenMetrics {
        let screenHeight = self.fixedCoordinateSpace.bounds.height
        switch screenHeight {
        case ScreenMetrics.inch3dot5.heightInPoints:
            return .inch3dot5
        case ScreenMetrics.inch4.heightInPoints:
            return .inch4
        case ScreenMetrics.inch4dot7.heightInPoints:
            return .inch4dot7
        case ScreenMetrics.inch5dot5.heightInPoints:
            return .inch5dot5
        case ScreenMetrics.inch5dot8.heightInPoints:
            return .inch5dot8
        case ScreenMetrics.inch6dot1.heightInPoints:
            return .inch6dot1
        case ScreenMetrics.inch6dot5.heightInPoints:
            return .inch6dot5
        case ScreenMetrics.iPad.heightInPoints:
            return .iPad
        case ScreenMetrics.iPad12dot9.heightInPoints:
            return .iPad12dot9
        default:
            return .undefined
        }
    }
    
    var defaultPortraitKeyboardHeight: CGFloat {
        switch self.screenMetric {
        case .inch3dot5, .inch4:
            return 253
        case .inch4dot7:
            return 260
        case .inch5dot5:
            return 271
        case .inch5dot8:
            return 335
        case .inch6dot1, .inch6dot5:
            return 346
        case .iPad:
            return 313
        case .iPad12dot9:
            return 378
        case .undefined:
            return 335 // iPhoneX
        }
    }
    
    var defaultLandscapeKeyboardHeight: CGFloat {
        switch self.screenMetric {
        case .inch3dot5, .inch4:
            return 199
        case .inch4dot7, .inch5dot5:
            return 200
        case .inch5dot8, .inch6dot1, .inch6dot5:
            return 209
        case .iPad:
            return 398
        case .iPad12dot9:
            return 471
        case .undefined:
            return 209 // iPhone X
        }
    }
    
    public var defaultOrientaionKeyboardHeight: CGFloat {
        if UIDevice.current.orientation.isPortrait {
            return self.defaultPortraitKeyboardHeight
        } else {
            return self.defaultLandscapeKeyboardHeight
        }
    }
}

