import Foundation

public enum LibrarySyncVersion: Int, Comparable, CustomStringConvertible {
    case v6 = 0
    case v7 = 1 // Genres added
    case v8 = 2 // Directories added
    case v9 = 3 // Artwork ids added
    case v10 = 4 // Podcasts added
    case v11 = 5 // isRecentAdded added to AbstractPlayable
    
    public var description : String {
        switch self {
        case .v6: return "v6"
        case .v7: return "v7"
        case .v8: return "v8"
        case .v9: return "v9"
        case .v10: return "v10"
        case .v11: return "v11"
        }
    }
    public var isNewestVersion: Bool {
        return self == Self.newestVersion
    }
    
    public static let newestVersion: LibrarySyncVersion = .v11
    public static let defaultValue: LibrarySyncVersion = .v6
    
    public static func < (lhs: LibrarySyncVersion, rhs: LibrarySyncVersion) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}