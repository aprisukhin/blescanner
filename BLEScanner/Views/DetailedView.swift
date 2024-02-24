import SwiftUI
import CoreBluetooth

struct DetailedView: View {
	@State private var isSecondButtonDisplayed = false
    @State private var batteryLevel: Int = 0
	@State private var range: Int = 0
	@State private var isTimerRunning = false
    
    @State private var commandPowerAll = "$P000000000000000000000000000000000000000000000000&"
    @State private var pulseFilling = "$N06000&"
    @State private var pulseFrequency = "$M00090&"
    @State private var effectChoosing = "$E01&"
    @State private var pulseInfinity = "$W00&"
    @State private var stopWorking = "$S&"
    
    @State var device: DiscoveredPeripheral
    
    @State private var timer: Timer?

    
    var body: some View {
        NavigationStack {
            VStack {
                VStack(alignment: .leading) {
                    Text("Устройство: " + (device.peripheral.name ?? "нет данных"))
                    Text("Состояние подключения: " + "\(String(describing: device.peripheral.state.rawValue))")
                    Text("Аккумулятор: \(Int(self.batteryLevel))%")
                    
                    
                    Button(action: {
                        sendTextToDevice(isSecondButtonDisplayed ? stopWorking : pulseInfinity)
                        
                        if self.isTimerRunning {
                            self.stopTimer()
                        } else {
                            self.startTimer()
                        }
                    }) {
                        if isSecondButtonDisplayed {
                            Text("Стоп")
                                .foregroundColor(.white)
                                .frame(width: 200, height: 50)
                                .background(Color.green)
                                .cornerRadius(25)
                        } else {
                            Text("Старт")
                                .foregroundColor(.white)
                                .frame(width: 200, height: 50)
                                .background(Color.green)
                                .cornerRadius(25)
                        }
                    }
                    .padding()
                }
                .padding()
                
                Spacer()
                
                HStack {
                    Button(action: {
                        if self.range > 0 {
                            self.range -= 5
                        }
                        changeTextToSend()
                        sendTextToDevice(commandPowerAll)
                    }) {
                        Image(systemName: "minus")
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.red)
                            .cornerRadius(30)
                    }
                    
                    Text("\(range)")
                    
                    Button(action: {
                        if self.range < 100 {
                            self.range += 5
                        }
                        changeTextToSend()
                        sendTextToDevice(commandPowerAll)
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.blue)
                            .cornerRadius(30)
                    }
                }
                .padding()
            }
            .onAppear {
                startBatteryTimer()
                BlueToothManager.shared.readBatteryLevel()
                
                sendTextToDevice(commandPowerAll)
                sendTextToDevice(pulseFilling)
                sendTextToDevice(pulseFrequency)
                sendTextToDevice(effectChoosing)
                
                range = 0
            }
            
            .onDisappear {
                timer?.invalidate()
            }
        }
    }
    
    // Send command to device
	private func sendTextToDevice(_ text: String) {
		if let dataToSend = text.data(using: .utf8) {
            BlueToothManager.shared.sendData(dataToSend)
		} else {
			print("Failed to encode string to Data.")
		}
        print(text)
	}
    
    private func sendBatteryInfo(_ text: String) {
        if let dataToSend = text.data(using: .utf8) {
            BlueToothManager.shared.sendData(dataToSend)
        } else {
            print("Failed to encode string to Data.")
        }
        print(text)
    }
    
    func createBatteryStatusString(isCharging: Bool, batteryLevel: Int) -> String {
        var statusString = "$"
        statusString += isCharging ? "B" : "b"
        statusString += String(format: "%03d", batteryLevel)
        statusString += "&"
        
        return statusString
    }
    
    // Change command's text to send
	private func changeTextToSend() {
        var a = "0000"
		if range >= 0, range < 10 {
            // [0, 10)
			a = "00\(range)0"
		} else if range >= 10, range < 100  {
            //[10, 99)
			a = "0\(range)0"
		} else if range == 100 {
            //100
			a = "\(range)0"
		}

		var text = "$P"
		for _ in 0..<12 {
			text += a
		}
		text += "&"
		
		self.commandPowerAll = text
	}
    
    private func startBatteryTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            BlueToothManager.shared.readBatteryLevel()
            self.batteryLevel = BlueToothManager.shared.batteryLevel
            let data = createBatteryStatusString(isCharging: BlueToothManager.shared.isBatteryCharging,
                                                 batteryLevel: BlueToothManager.shared.batteryLevel)
            self.sendBatteryInfo(data)
        }
    }
    
	private func startTimer() {
		isSecondButtonDisplayed = true
		isTimerRunning = true
		
		// Start a timer to change the button text back to "Start" after 10 seconds
		Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { _ in
            stopTimer()
		}
	}
	
	private func stopTimer() {
		isSecondButtonDisplayed = false
		isTimerRunning = false
	}
}
