import Flutter
import UIKit
import Firebase
import FirebaseMessaging
import CoreLocation
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Initialize Google Maps API Key FIRST
    GMSServices.provideAPIKey("AIzaSyC4oO2oBMNzhEhLCmD2i9Ts9ljplYpsCVg")
    print("Google Maps SDK initialized with key: AIzaSyC4oO2oBMNzhEhLCmD2i9Ts9ljplYpsCVg")
    
    // Configure Firebase
    FirebaseApp.configure()
    
    // Set messaging delegate
    Messaging.messaging().delegate = self
    
    // Request authorization for notifications
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    UNUserNotificationCenter.current().requestAuthorization(
      options: authOptions,
      completionHandler: { granted, error in
        print("Notification permission granted: \(granted)")
        if let error = error {
          print("Notification permission error: \(error)")
        }
        
        // Register for remote notifications after permission is granted
        DispatchQueue.main.async {
          application.registerForRemoteNotifications()
        }
      }
    )
    
    // Request location permission early
    _requestLocationPermission()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Request location permission
  private func _requestLocationPermission() {
    let locationManager = CLLocationManager()
    locationManager.requestWhenInUseAuthorization()
  }
  
  // Handle APNS token registration - MUST use override
  override func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    
    print("APNS device token received: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
    
    // Set the APNS token for Firebase
    Messaging.messaging().apnsToken = deviceToken
    
    // Also try to get the FCM token immediately after APNS token is set
    Messaging.messaging().token { token, error in
      if let error = error {
        print("Error getting FCM token: \(error)")
      } else if let token = token {
        print("FCM token obtained: \(token)")
      }
    }
  }
  
  // Handle APNS registration failure - MUST use override
  override func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    print("Failed to register for remote notifications: \(error)")
  }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("Firebase registration token: \(String(describing: fcmToken))")
  }
}