import RealityKit
import UIKit

final class HumanDetectView: ARView {
    private lazy var rectangleLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = UIColor.red.cgColor
        layer.lineWidth = 2
        layer.fillColor = UIColor.clear.cgColor
        return layer
    }()
    
    // MARK: Methods

    func showRectangle(rect: CGRect) {
        // Update rectangle path
        rectangleLayer.path = UIBezierPath(rect: rect).cgPath
        
        // Add sublayer if needed
        if rectangleLayer.superlayer == nil {
            layer.addSublayer(rectangleLayer)
        }
    }

    
    func hideRectangle() {
        // Just remove from it's superview
        rectangleLayer.removeFromSuperlayer()
    }
}
