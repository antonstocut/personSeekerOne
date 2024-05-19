import SwiftUI
import ARKit
import RealityKit

struct ARViewContainer: UIViewRepresentable {
    var completion: (Result<Double, Error>) -> Void
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        context.coordinator.setupARView(arView: arView)
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.startTracking()
    }
    
    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator.shared
        coordinator.completion = completion
        return coordinator
    }
}
