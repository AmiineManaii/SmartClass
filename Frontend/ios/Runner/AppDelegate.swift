import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var secureChannel: FlutterMethodChannel?
  private var observesScreenCapture = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "com.smartclass.smartclass/secure_window",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    secureChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(nil)
        return
      }
      switch call.method {
      case "enable":
        self.startScreenCaptureObservation()
        // iOS cannot block screenshots. Only a real capture signal is exposed.
        result([
          "platform": "ios",
          "screenshotBlocked": false,
          "captureDetection": true,
        ])
      case "disable":
        self.stopScreenCaptureObservation()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func startScreenCaptureObservation() {
    guard !observesScreenCapture else { return }
    observesScreenCapture = true
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(screenCaptureDidChange),
      name: UIScreen.capturedDidChangeNotification,
      object: nil
    )
  }

  private func stopScreenCaptureObservation() {
    guard observesScreenCapture else { return }
    observesScreenCapture = false
    NotificationCenter.default.removeObserver(
      self,
      name: UIScreen.capturedDidChangeNotification,
      object: nil
    )
  }

  @objc private func screenCaptureDidChange() {
    secureChannel?.invokeMethod(
      "screenCaptureChanged",
      arguments: UIScreen.main.isCaptured
    )
  }

  deinit {
    stopScreenCaptureObservation()
  }
}
