import SwiftUI

struct ElementDeviceList: View {
    @State var discoveredPeripheral: DiscoveredPeripheral
        
    var body: some View {
        HStack {
            Text(discoveredPeripheral.peripheral.name ?? "Неизвестное устройство")
                .font(.headline)
            
            Spacer()
            
            Button(action: {
                print("button tapped")
            }) {
                switch discoveredPeripheral.peripheral.state {
                    case .connected:
                        Text("")
                        .hidden()
                    case .connecting:
                        ConnectionProgress(isLoading: discoveredPeripheral.peripheral.state == .connecting)
                    default:
                        Text("Подключится")
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .frame(height: 40)
                            .background(discoveredPeripheral.peripheral.state == .connected ? Color.blue : Color.green)
                            .cornerRadius(20)
                }
            }
        }
        .frame(height: 60)
    }
}

struct ConnectionProgress: View {
    @State var isLoading = false
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(Color.green, lineWidth: 2)
            .frame(width: 25, height: 25)
            .rotationEffect(Angle(degrees: isLoading ? 360 : 0))
            .animation(.linear
                        .repeatForever(autoreverses: false), value: isLoading)
            .onAppear {
                isLoading = true
            }
    }
}
