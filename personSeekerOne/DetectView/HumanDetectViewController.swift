import ARKit
import RealityKit

final class HumanDetectViewController: UIViewController {
    typealias DetectHandler = (_ distance: Double? ) -> Void
    typealias CountHandler = (_ countPeople: Int ) -> Void
    
    var onDetect: DetectHandler?
    var onCount: CountHandler?

    private(set) var isDetecting: Bool = false
    
    // MARK: Private Properties
    
    /// The last known view's size
    private var viewSize: CGSize = .zero
    
    private let distanceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
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
    
    func calculateHumanDistance(boundingBox: CGRect) -> Double? {
        let center = CGPoint(x: boundingBox.midX, y: boundingBox.midY)
        
        guard let result = rootView.hitTest(center, types: .featurePoint).first else {
            return nil
        }
        
        return result.distance
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
                    // Better way hide all then show new rectangles
                    hideAllRectangle()
                                        
                    // Add new rectangles
                    observations.forEach { human in
                        // Calculate new frame
                        self.calculateDistanceAndShowRectangle(human: human)
                    }
                    // Count people
                    let count = observations.count
                    self.onCount?(count)
                    
                    
                case .failure(let error):
                    print("Detect human request error occurred: \(error)")
                    hideAllRectangle()
                }
            }
            
            // Perform the request
            do {
                let handler = VNImageRequestHandler(cvPixelBuffer: cvPixelBuffer, orientation: .up, options: [:])
                try handler.perform([request])
            } catch {
                print("Detect human error occurred: \(error)")
                hideAllRectangle()
            }
        }
    }
    
    
    // MARK: Rectangle
    
    func showRectangle(configuration: HumanDetectView.RectangleConfiguration) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            // Show rectangle on the view
            rootView.showRectangle(configuration: configuration)
        }
    }
    
    func calculateDistanceAndShowRectangle(human: VNHumanObservation) {
        // Transform Y coordinate and normalize the dimensions of the processed image, with the origin at the image's lower-left corner.
        let viewSize = viewSize
        let humanBox = human.boundingBox
        
        let boundingBox = CGRect(
            x: humanBox.minX * viewSize.width,
            y: (1 - humanBox.maxY) * viewSize.height,
            width: humanBox.width * viewSize.width,
            height: humanBox.height * viewSize.height
        )
        
        // Calculate the distance to detected human
        let distanceText = calculateHumanDistance(boundingBox: boundingBox)
            .map { NSNumber(value: $0) }
            .flatMap { distanceFormatter.string(from: $0) }
        
        // Prepare configuration
        let configuration = HumanDetectView.RectangleConfiguration(uuid: human.uuid, rect: boundingBox, text: distanceText)
        
        // Show rectangle near detected human
        showRectangle(configuration: configuration)
    }
    
    func hideRectangle(uuid: UUID) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            // Hide rectangle from the view
            rootView.hideRectangle(uuid: uuid)
            
            // Notify about hiding rectangle
            onDetect?(nil)
        }
    }
    
    func hideAllRectangle() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            // Hide all rectangles from the view
            rootView.hideAllRectangles()
        }
    }
}
