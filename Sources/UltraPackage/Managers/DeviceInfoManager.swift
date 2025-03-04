import UIKit
import CoreLocation
import ProgressHUD

final class DeviceInfoManager: NSObject, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager
    private var currentLocation: CLLocation?
    
    override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    func collectDeviceInformation() -> [String: Any] {
        return [
            "deviceInformation": getDeviceInformation(),
            "browserEnvironment": getBrowserEnvironment(),
            "hardwareAndSystemResources": getHardwareAndSystemResources(),
            "environmentContext": getEnvironmentContext(),
            "indicators": getIndicators()
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
            "touchPoints": getMaxTouchPoints()
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
        if let location = currentLocation ?? locationManager.location {
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
        print("📍 Updated Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        print("🚀 Location Authorization Changed: \(status.rawValue)")
        
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            ProgressHUD.error("Location permission denied. Please enable it in Settings.")
        @unknown default:
            break
        }
    }
    
    private func getIndicators() -> [String: Any] {
        return [
            "headless": [],
            "emulator": detectEmulatorIndicators()
        ]
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
        case .portrait, .portraitUpsideDown:
            return "portrait"
        case .landscapeLeft, .landscapeRight:
            return "landscape"
        default:
            return "unknown"
        }
    }
    
    private func getMaxTouchPoints() -> Int {
        return 5 // Commonly assumed value for iOS
    }
}
