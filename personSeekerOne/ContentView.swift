import SwiftUI

struct ContentView: View {
    @State private var distance: Double?
    @State private var isDetecting: Bool = false
    @State private var countPeople: Int = 0
    
    // MARK: View
    
    var body: some View {
        ZStack {
            makeHumanDetectContainer()

            VStack {
                Spacer()
                HStack {
                    makeDistanceText()
                
                    Spacer()
                    
                    makeTrackingButton()
                }
                .padding(10)
            }
        }
    }
}

// MARK: - Private

private extension ContentView {
    func makeHumanDetectContainer() -> some View {
        HumanDetectViewContainer(isDetecting: $isDetecting, distance: $distance, countPeople: $countPeople)
        .edgesIgnoringSafeArea(.all)
    }
    
    func makeDistanceText() -> some View {
        let text: Text
        
        if let distance {
            text = Text("ContentView.distance(\(distance))")
        } else {
            if isDetecting {
                if countPeople != 0 {
                    if countPeople == 1 {
                        text = Text("ContentView.detectedOne")
                    } else {
                        text = Text("ContentView.detectedN(\(countPeople)")
                    }
                } else {
                    text = Text("ContentView.noDetected")
                }
            } else {
                text = Text("ContentView.pause")
            }
        }
        
        return text
            .font(.headline)
            .padding()
            .background(Color.black.opacity(0.7))
            .cornerRadius(10)
            .foregroundColor(.white)
    }
    
    func makeTrackingButton() -> some View {
        Button(action: {
            toggleDetection()
        }) {
            Image(systemName: isDetecting ? "stop.circle.fill" : "play.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(isDetecting ? .blue : .green)
        }
        .padding(10)
    }
    
    // MARK: Methods
    
    func toggleDetection() {
        isDetecting.toggle()
    }
}

// MARK: - PreviewProvider

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
