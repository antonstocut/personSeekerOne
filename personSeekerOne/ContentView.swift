import SwiftUI

struct ContentView: View {
    @State private var distance: String = "Calculating..."
    @State private var isTracking: Bool = false

    var body: some View {
        ZStack {
            ARViewContainer(completion: { result in
                switch result {
                case .success(let distance):
                    self.distance = String(format: "%.2f meters", distance)
                case .failure(let error):
                    self.distance = "Error: \(error.localizedDescription)"
                }
            })
            .aspectRatio(16/9, contentMode: .fit)
            .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
                HStack {
                    Text("Distance to detected person: \(distance)")
                        .font(.headline)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        toggleTracking()
                    }) {
                        Image(systemName: isTracking ? "stop.circle.fill" : "play.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(isTracking ? .blue : .green)
                    }
                    .padding(10)
                }
                .padding(10)
            }
        }
    }

    func toggleTracking() {
        isTracking.toggle()
        if isTracking {
            Coordinator.shared.startLogging()
        } else {
            Coordinator.shared.stopLogging()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
