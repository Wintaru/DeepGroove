import OSLog

final class LogUtility: Sendable {
    private let logger: Logger

    init(subsystem: String = Bundle.main.bundleIdentifier ?? "com.jdonner.deepgroove",
         category: String = "General") {
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    func info(_ message: String) { logger.info("\(message)") }
    func debug(_ message: String) { logger.debug("\(message)") }
    func warning(_ message: String) { logger.warning("\(message)") }
    func error(_ message: String) { logger.error("\(message)") }

    func forCategory(_ category: String) -> LogUtility {
        LogUtility(
            subsystem: Bundle.main.bundleIdentifier ?? "com.jdonner.deepgroove",
            category: category
        )
    }
}
