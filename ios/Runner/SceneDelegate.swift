import Flutter
import UIKit
import GoogleMaps

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    GMSServices.provideAPIKey("AIzaSyD9qpVoecA0DQzfoeVKSiBD2VPz4xa_frk")
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }
}
