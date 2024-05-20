import SwiftUI
import ARKit
import RealityKit

struct HumanDetectViewContainer: UIViewControllerRepresentable {
    @Binding var isDetecting: Bool
    @Binding var distance: Double?
    
    func makeUIViewController(context: Context) -> HumanDetectViewController {
        let viewController = HumanDetectViewController()
        viewController.onDetect = { distance = $0 }
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: HumanDetectViewController, context: Context) {
        if isDetecting {
            uiViewController.startDetection()
        } else {
            uiViewController.pauseDetection()
        }
    }
}