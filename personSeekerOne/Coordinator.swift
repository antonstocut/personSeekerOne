import ARKit
import RealityKit
import Vision

class Coordinator: NSObject, ARSessionDelegate {
    var completion: (Result<Double, Error>) -> Void
    private var arView: ARView?
    private var rectangleLayer: CAShapeLayer?
    private var isLogging: Bool = false

    static let shared = Coordinator(completion: { _ in })

    init(completion: @escaping (Result<Double, Error>) -> Void) {
        self.completion = completion
    }

    func setupARView(arView: ARView) {
        self.arView = arView
        arView.session.delegate = self
        startTracking()
    }

    func startTracking() {
        guard let arView = self.arView else { return }
        let configuration = ARWorldTrackingConfiguration()
        if ARBodyTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            configuration.frameSemantics.insert(.personSegmentationWithDepth)
        }
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let arView = self.arView else { return }
        
        let visionQueue = DispatchQueue(label: "com.example.visionQueue", qos: .userInitiated)
        visionQueue.async {
            let request = VNDetectHumanRectanglesRequest { [weak self] request, error in
                guard let self = self else { return }
                if let error = error {
                    DispatchQueue.main.async {
                        self.completion(.failure(error))
                    }
                    return
                }
                
                guard let results = request.results as? [VNHumanObservation], let person = results.first else {
                    DispatchQueue.main.async {
                        self.clearRectangle()
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self.updateRectangle(person: person, arView: arView)
                }
                
                let boundingBox = person.boundingBox
                let normalizedCenter = CGPoint(x: boundingBox.midX, y: boundingBox.midY)
                
                DispatchQueue.main.async {
                    let viewSize = arView.bounds.size
                    let centerPoint = CGPoint(x: normalizedCenter.x * viewSize.width, y: (1 - normalizedCenter.y) * viewSize.height)

                    if let hitTestResult = arView.hitTest(centerPoint, types: .featurePoint).first {
                        let distance = Double(hitTestResult.distance)
                        self.completion(.success(distance))

                        if self.isLogging {
                            print("Relative horizontal position: \(normalizedCenter.x)")
                        }
                    }
                }
            }
            
            let handler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage, orientation: .up, options: [:])
            try? handler.perform([request])
        }
    }

    func startLogging() {
        isLogging = true
    }

    func stopLogging() {
        isLogging = false
    }

    private func updateRectangle(person: VNHumanObservation, arView: ARView) {
        let boundingBox = person.boundingBox
        
        DispatchQueue.main.async {
            let viewSize = arView.bounds.size
            let rect = CGRect(x: boundingBox.minX * viewSize.width,
                              y: (1 - boundingBox.maxY) * viewSize.height,
                              width: boundingBox.width * viewSize.width,
                              height: boundingBox.height * viewSize.height)
            
            if let rectangleLayer = self.rectangleLayer {
                rectangleLayer.path = UIBezierPath(rect: rect).cgPath
            } else {
                let layer = CAShapeLayer()
                layer.path = UIBezierPath(rect: rect).cgPath
                layer.strokeColor = UIColor.red.cgColor
                layer.lineWidth = 2.0
                layer.fillColor = UIColor.clear.cgColor
                arView.layer.addSublayer(layer)
                self.rectangleLayer = layer
            }
        }
    }
    
    private func clearRectangle() {
        DispatchQueue.main.async {
            self.rectangleLayer?.removeFromSuperlayer()
            self.rectangleLayer = nil
        }
    }
}
