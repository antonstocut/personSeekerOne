import ARKit
import RealityKit

final class HumanDetectViewController: UIViewController {
    typealias DetectHandler = (_ distance: Double?) -> Void
    
    var onDetect: DetectHandler?
    
    private(set) var isDetecting: Bool = false
    
    // MARK: Private Properties
    
    /// The last known view's size
    private var viewSize: CGSize = .zero
    
    private let detectHumanQueue = DispatchQueue(label: "HumanDetectViewController.detectHumanQueue", qos: .userInteractive)
    
    // MARK: View
    
    private lazy var rootView = HumanDetectView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
    
    // MARK: Lifecycle
    
    override func loadView() {
        view = rootView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rootView.session.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Store last known view's size to use it on background queue
        viewSize = rootView.frame.size
    }
    
    // MARK: Methods
    
    func startDetection() {
        guard !isDetecting else { return }
        
        let configuration = ARWorldTrackingConfiguration()
        
        if ARBodyTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            configuration.frameSemantics.insert(.personSegmentationWithDepth)
        }
        
        rootView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        isDetecting = true
    }
    
    func pauseDetection() {
        guard isDetecting else { return }
        
        rootView.session.pause()
        
        isDetecting = false
    }
}

// MARK: - ARSessionDelegate

extension HumanDetectViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        performDetectHumanRequest(cvPixelBuffer: frame.capturedImage)
    }
}

// MARK: - Private

private extension HumanDetectViewController {
    // MARK: Human Distance
    
    func calculateHumanDistance(boundingBox: CGRect) {
        let center = CGPoint(x: boundingBox.midX, y: boundingBox.midY)
        
        guard let result = rootView.hitTest(center, types: .featurePoint).first else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.onDetect?(result.distance)
        }
    }
    
    // MARK: Human Detection
    
    func detectHumanRequest(completion: @escaping (_ result: Result<[VNHumanObservation], Error>) -> Void) -> VNDetectHumanRectanglesRequest {
        VNDetectHumanRectanglesRequest { request, error in
            if let error = error {
                completion(.failure(error))
            } else {
                let results = request.results as? [VNHumanObservation]
                completion(.success(results ?? []))
            }
        }
    }
    
    func performDetectHumanRequest(cvPixelBuffer: CVPixelBuffer) {
        detectHumanQueue.async { [weak self] in
            guard let self else { return }
            
            // Prepare human detection request
            let request = detectHumanRequest { [weak self] result in
                guard let self else { return }
                
                switch result {
                case .success(let observations):
                    guard let firstHuman = observations.first else {
                        hideRectangle()
                        return
                    }
                    
                    // Transform Y coordinate and normalize the dimensions of the processed image, with the origin at the image's lower-left corner.
                    let viewSize = viewSize
                    let humanBox = firstHuman.boundingBox
                    
                    let boundingBox = CGRect(
                        x: humanBox.minX * viewSize.width,
                        y: (1 - humanBox.maxY) * viewSize.height,
                        width: humanBox.width * viewSize.width,
                        height: humanBox.height * viewSize.height
                    )
                    
                    // Show rectangle near detected human
                    showRectangle(boundingBox: boundingBox)
                    
                    // Calculate the distance to detected human
                    calculateHumanDistance(boundingBox: boundingBox)
                    
                case .failure(let error):
                    print("Detect human request error occurred: \(error)")
                    hideRectangle()
                }
            }
            
            // Perform the request
            do {
                let handler = VNImageRequestHandler(cvPixelBuffer: cvPixelBuffer, orientation: .up, options: [:])
                try handler.perform([request])
            } catch {
                print("Detect human error occurred: \(error)")
                hideRectangle()
            }
        }
    }
    
    
    // MARK: Rectangle
    
    func showRectangle(boundingBox: CGRect) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            // Show rectangle on the view
            rootView.showRectangle(rect: boundingBox)
        }
    }
    
    func hideRectangle() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            // Hide rectangle from the view
            rootView.hideRectangle()
            
            // Notify about hiding rectangle
            onDetect?(nil)
        }
    }
}
