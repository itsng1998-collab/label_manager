import Cocoa
import FlutterMacOS

public class FortuneSheetPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "fortune_sheet/fonts",
      binaryMessenger: registrar.messenger
    )
    let instance = FortuneSheetPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "listFontFamilies" {
      result(NSFontManager.shared.availableFontFamilies.sorted {
        $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
      })
    } else {
      result(FlutterMethodNotImplemented)
    }
  }
}
