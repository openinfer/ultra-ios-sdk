import UIKit
import CoreLocation
import ProgressHUD
import CoreMotion
import AVFoundation
import ARKit
import Toaster

protocol DeviceInfoManagerDelegate: AnyObject {
    func permissionsRequestUpdated()
}

final class DeviceInfoManager: NSObject, CLLocationManagerDelegate {
    
    weak var delegate: DeviceInfoManagerDelegate?
    
    private var locationManager: CLLocationManager?
    private var currentLocation: CLLocation?
    
    private let motionManager = CMMotionManager()
    private let altimeter = CMAltimeter()

    private var accelerometerData: String = "N|A"
    private var gyroscopeData: String = "N|A"
    private var magnetometerData: String = "N|A"
    private var cameraLunchTime: String = ""
    private var deviceMotionData: [String: Any] = [:]
    private var barometerAltimeterData: [String: Any] = [:]
    private var microphoneData: [String: Any] = [:]
    
    private var motionPermissionHandled = false
    private var microphonePermissionHandled = false
    private var locationPermissionHandled = false

    func start(with cameraLunchTime: String) {
        locationManager = CLLocationManager()
        fetchAccelerometerData()
        fetchGyroscopeUpdates()
        fetchMagnetometerUpdates()
        fetchDeviceMotionUpdates()
        fetchBarometerAltimeterUpdates()
        
        getMicrophoneInfo()
        
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
        
        self.cameraLunchTime = cameraLunchTime
        
        if CryptonetManager.shared.isPermissionAccepted() == false {
            CryptonetManager.shared.askPermissionImplemented()
        }
    }
    
    func collectDeviceInformation() -> [String: Any] {
        return [
            "deviceInformation": getDeviceInformation(),
            "browserEnvironment": getBrowserEnvironment(),
            "hardwareAndSystemResources": getHardwareAndSystemResources(),
            "environmentContext": getEnvironmentContext(),
            "indicators": getIndicators(),
            "cameraVerification": getCameraLunchSettings()
        ]
    }
    
    private func getDeviceInformation() -> [String: Any] {
        let screen = UIScreen.main.bounds
        let device = UIDevice.current
        return [
            "userAgent": getUserAgent(),
            "deviceType": device.model,
            "screenDimensions": [
                "width": Int(screen.width),
                "height": Int(screen.height)
            ],
            "orientation": getOrientation(),
            "touchPoints": getMaxTouchPoints(),
            "accelerometer": accelerometerData,
            "gyroscope": gyroscopeData,
            "magnetometer": magnetometerData,
            "deviceMotion": deviceMotionData,
            "barometerAltimeter": barometerAltimeterData,
            "proximity": getProximityState(),
            "cameras": getCamerasData(),
            "microphones": microphoneData,
            "lidar": getLiDARData(),
            "trueDepth": getTrueDepthData()
        ]
    }
    
    private func getBrowserEnvironment() -> [String: Any] {
        return [
            "platform": UIDevice.current.systemName
        ]
    }
    
    private func getHardwareAndSystemResources() -> [String: Any] {
        return [
            "batteryStatus": getBatteryStatus()
        ]
    }
    
    private func getBatteryStatus() -> [String: Any] {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return [
            "batteryLevel": Int(UIDevice.current.batteryLevel * 100),
            "isCharging": UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
        ]
    }
    
    private func getEnvironmentContext() -> [String: Any] {
        return [
            "locale": [
                "language": Locale.current.identifier
            ],
            "location": getCurrentLocation(),
            "timezone": [
                "offset": TimeZone.current.secondsFromGMT() / 3600,
                "timezone": TimeZone.current.identifier
            ]
        ]
    }
    
    private func getCurrentLocation() -> [String: Any] {
        if let location = currentLocation ?? locationManager?.location {
            return [
                "latitude": location.coordinate.latitude,
                "longitude": location.coordinate.longitude
            ]
        } else {
            return [
                "latitude": "No Data",
                "longitude": "No Data"
            ]
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
//        print("📍 Updated Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        print("🚀 Location Authorization Changed: \(status.rawValue)")
        
        locationPermissionHandled = true
        
        switch status {
        case .notDetermined:
            locationManager?.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager?.startUpdatingLocation()
        case .denied, .restricted:
            Toast(text: "Location permission denied. Please enable it in Settings.", duration: Delay.short).show()
        @unknown default:
            break
        }
        
        checkAllPermissionsHandled()
    }
    
    private func getIndicators() -> [String: Any] {
        return [
            "headless": [],
            "emulator": detectEmulatorIndicators()
        ]
    }
    
    private func getCameraLunchSettings() -> [String: Any] {
        return [
            "initializationTime": 400,
            "lunchTime": self.cameraLunchTime
        ]
    }
    
    private func fetchAccelerometerData() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: .main) { (data, error) in
                if let data = data {
                    // print("Acceleration X: \(data.acceleration.x), Y: \(data.acceleration.y), Z: \(data.acceleration.z)")
                    self.accelerometerData = "X: \(data.acceleration.x), Y: \(data.acceleration.y), Z: \(data.acceleration.z)"
                } else if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
            }
        } else {
            print("Accelerometer is not available on this device.")
        }
    }
    
    private func fetchGyroscopeUpdates() {
        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = 0.1
            motionManager.startGyroUpdates(to: .main) { (data, error) in
                if let data = data {
                    self.gyroscopeData = "X: \(data.rotationRate.x), Y: \(data.rotationRate.y), Z: \(data.rotationRate.z)"
                } else if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func fetchMagnetometerUpdates() {
        if motionManager.isMagnetometerAvailable {
            motionManager.magnetometerUpdateInterval = 0.1
            motionManager.startMagnetometerUpdates(to: .main) { (data, error) in
                if let data = data {
                    self.magnetometerData = "X: \(data.magneticField.x), Y: \(data.magneticField.y), Z: \(data.magneticField.z)"
                } else if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func fetchDeviceMotionUpdates() {
        if motionManager.isDeviceMotionAvailable {
            let status = CMMotionActivityManager.authorizationStatus()
            switch status {
            case .authorized:
                motionPermissionHandled = true
                motionManager.deviceMotionUpdateInterval = 0.1
                motionManager.startDeviceMotionUpdates(to: .main) { (motion, error) in
                    if let motion = motion {
                        let roll = motion.attitude.roll
                        let pitch = motion.attitude.pitch
                        let yaw = motion.attitude.yaw

                        let rotationX = motion.rotationRate.x
                        let rotationY = motion.rotationRate.y
                        let rotationZ = motion.rotationRate.z

                        let accelX = motion.userAcceleration.x
                        let accelY = motion.userAcceleration.y
                        let accelZ = motion.userAcceleration.z

                        let gravityX = motion.gravity.x
                        let gravityY = motion.gravity.y
                        let gravityZ = motion.gravity.z
                        
                        self.deviceMotionData = [
                            "roll": "\(roll), Pitch: \(pitch), Yaw: \(yaw)",
                            "rotationRate": "X:\(rotationX), Y:\(rotationY), Z:\(rotationZ)",
                            "userAcceleration": "X:\(accelX), Y:\(accelY), Z:\(accelZ)",
                            "gravity": "X:\(gravityX), Y:\(gravityY), Z:\(gravityZ)"
                        ]
                    } else if let error = error {
                        print("Error getting device motion data: \(error.localizedDescription)")
                    }
                }
            case .denied, .restricted:
                motionPermissionHandled = true
            case .notDetermined:
                motionPermissionHandled = true
            @unknown default:
                motionPermissionHandled = true
            }
        } else {
            motionPermissionHandled = true
        }
        checkAllPermissionsHandled()
    }
    
    private func fetchBarometerAltimeterUpdates() {
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.startRelativeAltitudeUpdates(to: .main) { (data, error) in
                if let data = data {
                    let altitude = data.relativeAltitude.doubleValue
                    let pressure = data.pressure.doubleValue

                    self.barometerAltimeterData = [
                        "altitude": "\(altitude) meters",
                        "pressure": "\(pressure) kPa"
                    ]
                } else if let error = error {
                    print("Error getting barometer data: \(error.localizedDescription)")
                }
            }
        } else {
            print("Altimeter is not available on this device.")
        }
    }
    
    private func detectEmulatorIndicators() -> [[String: Any]] {
        var indicators: [[String: Any]] = []
        
        if isRunningOnEmulator() {
            indicators.append([
                "suspicious": true,
                "value": "iOS Simulator",
                "message": "Running on an iOS Simulator"
            ])
        }
        
        return indicators
    }
    
    private func getProximityState() -> Bool {
        UIDevice.current.isProximityMonitoringEnabled = true
        return UIDevice.current.proximityState
    }
    
    private func getCamerasData() -> [String: [String: String]] {
        var devicesData: [String: [String: String]] = [:]
        
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInTelephotoCamera, .builtInTrueDepthCamera],
                                                              mediaType: .video,
                                                              position: .unspecified).devices
        for device in devices {
            var deviceData: [String: String] = [:]

            deviceData["position"] = device.position == .front ? "Front" : "Back"
            deviceData["type"] = device.deviceType.rawValue

            if device.hasMediaType(.video) {
                deviceData["supportsVideo"] = "YES"
            }

            deviceData["activeFormat"] = "\(device.activeFormat)"
            
            if #available(iOS 16.0, *) {
                let maxDimensions = device.activeFormat.supportedMaxPhotoDimensions
                if let maxResolution = maxDimensions.first {
                    deviceData["maxPhotoResolution"] = "\(maxResolution.width) x \(maxResolution.height)"
                }
            } else {
                let resolution = device.activeFormat.highResolutionStillImageDimensions
                deviceData["maxPhotoResolution"] = "\(resolution.width) x \(resolution.height)"
            }
            
            devicesData[device.localizedName] = deviceData
        }
        
        return devicesData
    }
    
    private func getMicrophoneInfo() {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] allowed in
                DispatchQueue.main.async {
                    self?.microphonePermissionHandled = true
                    self?.handleMicrophonePermission(allowed: allowed)
                    self?.checkAllPermissionsHandled()
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
                DispatchQueue.main.async {
                    self?.microphonePermissionHandled = true
                    self?.handleMicrophonePermission(allowed: allowed)
                    self?.checkAllPermissionsHandled()
                }
            }
        }
    }

    private func handleMicrophonePermission(allowed: Bool) {
        if allowed {
            do {
                let audioSession = AVAudioSession.sharedInstance()
                
                let availableInputs = audioSession.availableInputs
                
                if let microphone = availableInputs?.first(where: { $0.portType == .builtInMic }) {
                    var temp: [String: String] = [:]
                    
                    temp["Microphone Name"] = microphone.portName
                    temp["Microphone Type"] = "\(microphone.portType.rawValue)"
                    temp["Sample Rate"] = "\(audioSession.sampleRate) Hz"
                    
                    if let numberOfChannels = microphone.channels?.count {
                        temp["Number of Input Channels"] = "\(numberOfChannels)"
                    }

                    if let dataSource = microphone.selectedDataSource {
                        temp["Microphone Data Source"] = "\(dataSource.description)"
                    } else {
                        temp["Microphone Data Source"] = "No selected data source"
                    }
                    
                    DispatchQueue.main.async {
                        self.microphoneData["data"] = temp
                    }
                } else {
                    DispatchQueue.main.async {
                        self.microphoneData["data"] = "Built-in microphone not found."
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                self.microphoneData["data"] = "Permission denied to use the microphone."
            }
        }
    }
    
    private func getLiDARData() -> String {
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            return "LiDAR is available on this device."
        } else {
            return "LiDAR is not available on this device."
        }
    }
    
    private func getTrueDepthData() -> String {
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTrueDepthCamera],
                                                           mediaType: .video,
                                                           position: .front).devices
        if !devices.isEmpty {
            return "TrueDepth camera is available on this device."
        } else {
            return "TrueDepth camera is not available on this device."
        }
    }

    private func isRunningOnEmulator() -> Bool {
    #if targetEnvironment(simulator)
        return true
    #else
        return false
    #endif
    }
    
    private func getUserAgent() -> String {
        return "Mozilla/5.0 (iPhone; CPU iPhone OS \(UIDevice.current.systemVersion) like Mac OS X) AppleWebKit/537.36 (KHTML, like Gecko) Safari"
    }
    
    private func getOrientation() -> String {
        let orientation = UIDevice.current.orientation
        switch orientation {
        case .unknown:
            return "unknown"
        case .portrait:
            return "portrait"
        case .portraitUpsideDown:
            return "portraitUpsideDown"
        case .landscapeLeft:
            return "landscapeLeft"
        case .landscapeRight:
            return "landscapeRight"
        case .faceUp:
            return "faceUp"
        case .faceDown:
            return "faceDown"
        @unknown default:
            return "unknown"
        }
    }
    
    private func getMaxTouchPoints() -> Int {
        return 5
    }
    
    private func checkAllPermissionsHandled() {
        if motionPermissionHandled && microphonePermissionHandled && locationPermissionHandled {
            delegate?.permissionsRequestUpdated()
        }
    }
}
