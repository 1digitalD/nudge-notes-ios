import Foundation
import Photos
import UserNotifications

enum PermissionStatus: String, Equatable {
    case notRequested
    case granted
    case denied

    var description: String {
        switch self {
        case .notRequested:
            return "Not requested"
        case .granted:
            return "Allowed"
        case .denied:
            return "Not now"
        }
    }
}

protocol PermissionManaging {
    func requestPhotoPermission() async -> PermissionStatus
    func requestNotificationPermission() async -> PermissionStatus
}

struct SystemPermissionManager: PermissionManaging {
    private let mockAllGranted: Bool

    init(mockAllGranted: Bool = false) {
        self.mockAllGranted = mockAllGranted
    }

    static func makeDefault() -> SystemPermissionManager {
        SystemPermissionManager(
            mockAllGranted: ProcessInfo.processInfo.arguments.contains("-ui-testing-mock-permissions")
        )
    }

    func requestPhotoPermission() async -> PermissionStatus {
        if mockAllGranted {
            return .granted
        }

        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        switch status {
        case .authorized, .limited:
            return .granted
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notRequested
        @unknown default:
            return .denied
        }
    }

    func requestNotificationPermission() async -> PermissionStatus {
        if mockAllGranted {
            return .granted
        }

        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        return granted ? .granted : .denied
    }
}
