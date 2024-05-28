import RealityKit
import UIKit

final class HumanDetectView: ARView {
    struct RectangleConfiguration {
        let uuid: UUID
        let rect: CGRect
        let text: String?
    }
    
    // MARK: Properties
    
    private var viewsCache = [UUID: UILabel]()
    
    // MARK: Methods

    func getLabel(for uuid: UUID) -> UILabel {
        if let label = viewsCache[uuid] {
            return label
        } else {
            let label = UILabel()
            label.layer.borderColor = UIColor.red.cgColor
            label.layer.borderWidth = 2
            label.textAlignment = .center
            label.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            viewsCache[uuid] = label
            return label
        }
    }
    
    func showRectangle(configuration: RectangleConfiguration) {
        let label = getLabel(for: configuration.uuid)
        label.frame = configuration.rect
        label.text = configuration.text
        
        if label.superview == nil {
            addSubview(label)
        }
    }

    func hideRectangle(uuid: UUID) {
        guard let label = viewsCache.removeValue(forKey: uuid) else { return }
        label.removeFromSuperview()
    }
    
    func hideAllRectangles() {
        // Remove from screen
        viewsCache.values.forEach { label in
            label.removeFromSuperview()
        }
        
        // Clean up cache
        viewsCache.removeAll()
    }
}
