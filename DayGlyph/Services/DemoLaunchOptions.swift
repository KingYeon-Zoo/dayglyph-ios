import Foundation

/// 仅供本地演示脚本使用的启动参数。
///
/// 普通 App 启动不携带这些参数，因此不会改变真实用户的数据或首启流程。
struct DemoLaunchOptions {
    static let seedArgument = "--dayglyph-demo-seed"
    static let skipOnboardingArgument = "--dayglyph-skip-onboarding"

    let seedsDemoData: Bool
    let skipsOnboarding: Bool

    init(arguments: [String]) {
        let arguments = Set(arguments)
        seedsDemoData = arguments.contains(Self.seedArgument)
        skipsOnboarding = arguments.contains(Self.skipOnboardingArgument)
    }
}
