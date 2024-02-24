import SwiftUI
import CoreBluetooth

struct MainView: View {
    @ObservedObject private var bluetoothScanner = BluetoothScanner()
    @State private var searchText = ""
    @State private var showAlert = false
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    TextField("Поиск устройств", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button(action: {
                        self.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .opacity(searchText == "" ? 0 : 1)
                }
                .padding()
                .allowsHitTesting(false)
                
                List(bluetoothScanner.discoveredPeripherals.filter {
                    self.searchText.isEmpty ? true : $0.peripheral.name?.lowercased().contains(self.searchText.lowercased()) == true
                }, id: \.peripheral.identifier) { discoveredPeripheral in
                    
                    NavigationLink(destination: discoveredPeripheral.peripheral.state == .connected ? AnyView(DetailedView(device: discoveredPeripheral)) : AnyView(EmptyView())) {
                        
                        ElementDeviceList(discoveredPeripheral: discoveredPeripheral)
                        
                        .onTapGesture {
                            if discoveredPeripheral.peripheral.state != .connected {
                                self.bluetoothScanner.connect(to: discoveredPeripheral.peripheral)
                                
                            } else  {
//                                self.showAlert = true
                            }
                        }
                    }
                }
            }
            .navigationTitle("Список устройств")
            
            .onAppear() {
                bluetoothScanner.startScan()
            }
            
            .onDisappear {
                bluetoothScanner.stopScan()
            }
        }
    }
}

#Preview {
    MainView()
}



