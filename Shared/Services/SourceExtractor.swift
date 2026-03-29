import Foundation

/// Extracts readable source names and icons from URLs
struct SourceExtractor {

    /// Known source mappings with display name and SF Symbol icon
    struct SourceInfo: Equatable {
        let name: String
        let icon: String
        let color: String  // Hex color for the source

        static let unknown = SourceInfo(name: "Web", icon: "globe", color: "#8E8E93")
    }

    /// Map of domain patterns to source info
    private static let knownSources: [(pattern: String, info: SourceInfo)] = [
        // Social Media
        ("instagram.com", SourceInfo(name: "Instagram", icon: "camera", color: "#E4405F")),
        ("tiktok.com", SourceInfo(name: "TikTok", icon: "play.square.stack", color: "#000000")),
        ("twitter.com", SourceInfo(name: "X", icon: "at", color: "#1DA1F2")),
        ("x.com", SourceInfo(name: "X", icon: "at", color: "#1DA1F2")),
        ("facebook.com", SourceInfo(name: "Facebook", icon: "person.2", color: "#1877F2")),
        ("linkedin.com", SourceInfo(name: "LinkedIn", icon: "briefcase", color: "#0A66C2")),
        ("threads.net", SourceInfo(name: "Threads", icon: "at", color: "#000000")),
        ("reddit.com", SourceInfo(name: "Reddit", icon: "bubble.left.and.bubble.right", color: "#FF4500")),
        ("pinterest.com", SourceInfo(name: "Pinterest", icon: "pin", color: "#E60023")),

        // Video
        ("youtube.com", SourceInfo(name: "YouTube", icon: "play.rectangle", color: "#FF0000")),
        ("youtu.be", SourceInfo(name: "YouTube", icon: "play.rectangle", color: "#FF0000")),
        ("vimeo.com", SourceInfo(name: "Vimeo", icon: "play.rectangle", color: "#1AB7EA")),
        ("twitch.tv", SourceInfo(name: "Twitch", icon: "play.tv", color: "#9146FF")),

        // News & Media
        ("medium.com", SourceInfo(name: "Medium", icon: "doc.text", color: "#000000")),
        ("substack.com", SourceInfo(name: "Substack", icon: "envelope.open", color: "#FF6719")),
        ("nytimes.com", SourceInfo(name: "NY Times", icon: "newspaper", color: "#000000")),
        ("washingtonpost.com", SourceInfo(name: "WaPo", icon: "newspaper", color: "#000000")),
        ("theguardian.com", SourceInfo(name: "Guardian", icon: "newspaper", color: "#052962")),
        ("bbc.com", SourceInfo(name: "BBC", icon: "newspaper", color: "#BB1919")),
        ("bbc.co.uk", SourceInfo(name: "BBC", icon: "newspaper", color: "#BB1919")),
        ("cnn.com", SourceInfo(name: "CNN", icon: "newspaper", color: "#CC0000")),

        // Tech
        ("github.com", SourceInfo(name: "GitHub", icon: "chevron.left.forwardslash.chevron.right", color: "#181717")),
        ("stackoverflow.com", SourceInfo(name: "Stack Overflow", icon: "questionmark.circle", color: "#F48024")),
        ("hackernews.com", SourceInfo(name: "Hacker News", icon: "y.square", color: "#FF6600")),
        ("news.ycombinator.com", SourceInfo(name: "Hacker News", icon: "y.square", color: "#FF6600")),
        ("dev.to", SourceInfo(name: "DEV", icon: "doc.text", color: "#0A0A0A")),
        ("producthunt.com", SourceInfo(name: "Product Hunt", icon: "target", color: "#DA552F")),

        // Shopping
        ("amazon.com", SourceInfo(name: "Amazon", icon: "cart", color: "#FF9900")),
        ("amazon.co.uk", SourceInfo(name: "Amazon", icon: "cart", color: "#FF9900")),
        ("etsy.com", SourceInfo(name: "Etsy", icon: "bag", color: "#F56400")),
        ("ebay.com", SourceInfo(name: "eBay", icon: "cart", color: "#E53238")),
        ("shopify.com", SourceInfo(name: "Shopify", icon: "bag", color: "#7AB55C")),

        // Productivity
        ("notion.so", SourceInfo(name: "Notion", icon: "doc.text", color: "#000000")),
        ("docs.google.com", SourceInfo(name: "Google Docs", icon: "doc.text", color: "#4285F4")),
        ("drive.google.com", SourceInfo(name: "Google Drive", icon: "folder", color: "#4285F4")),
        ("dropbox.com", SourceInfo(name: "Dropbox", icon: "cloud", color: "#0061FF")),
        ("figma.com", SourceInfo(name: "Figma", icon: "paintbrush", color: "#F24E1E")),

        // Food & Recipes
        ("allrecipes.com", SourceInfo(name: "AllRecipes", icon: "fork.knife", color: "#E95C38")),
        ("epicurious.com", SourceInfo(name: "Epicurious", icon: "fork.knife", color: "#000000")),
        ("bonappetit.com", SourceInfo(name: "Bon Appetit", icon: "fork.knife", color: "#000000")),
        ("seriouseats.com", SourceInfo(name: "Serious Eats", icon: "fork.knife", color: "#1E1E1E")),
        ("food52.com", SourceInfo(name: "Food52", icon: "fork.knife", color: "#ED7C31")),

        // Apple
        ("apple.com", SourceInfo(name: "Apple", icon: "apple.logo", color: "#000000")),
        ("developer.apple.com", SourceInfo(name: "Apple Dev", icon: "hammer", color: "#147EFB")),

        // Messaging
        ("slack.com", SourceInfo(name: "Slack", icon: "number", color: "#4A154B")),
        ("discord.com", SourceInfo(name: "Discord", icon: "message", color: "#5865F2")),

        // Travel
        ("airbnb.com", SourceInfo(name: "Airbnb", icon: "house", color: "#FF5A5F")),
        ("booking.com", SourceInfo(name: "Booking", icon: "bed.double", color: "#003580")),
        ("tripadvisor.com", SourceInfo(name: "TripAdvisor", icon: "map", color: "#00AF87")),

        // Podcasts
        ("podcasts.apple.com", SourceInfo(name: "Podcasts", icon: "mic", color: "#9933FF")),
        ("spotify.com", SourceInfo(name: "Spotify", icon: "waveform", color: "#1DB954")),
        ("open.spotify.com", SourceInfo(name: "Spotify", icon: "waveform", color: "#1DB954")),
    ]

    /// Extract source info from a URL
    static func extract(from url: URL?) -> SourceInfo {
        guard let url = url,
              let host = url.host?.lowercased() else {
            return .unknown
        }

        // Remove www. prefix
        let cleanHost = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host

        // Check known sources
        for (pattern, info) in knownSources {
            if cleanHost == pattern || cleanHost.hasSuffix(".\(pattern)") {
                return info
            }
        }

        // Extract domain name as fallback
        let domainName = extractDomainName(from: cleanHost)
        return SourceInfo(name: domainName, icon: "globe", color: "#8E8E93")
    }

    /// Extract source info from source app identifier
    static func extract(fromApp sourceApp: String?) -> SourceInfo? {
        guard let app = sourceApp?.lowercased() else { return nil }

        // Map bundle identifiers to sources
        let appMappings: [String: SourceInfo] = [
            "instagram": SourceInfo(name: "Instagram", icon: "camera", color: "#E4405F"),
            "com.burbn.instagram": SourceInfo(name: "Instagram", icon: "camera", color: "#E4405F"),
            "tiktok": SourceInfo(name: "TikTok", icon: "play.square.stack", color: "#000000"),
            "com.zhiliaoapp.musically": SourceInfo(name: "TikTok", icon: "play.square.stack", color: "#000000"),
            "twitter": SourceInfo(name: "X", icon: "at", color: "#1DA1F2"),
            "com.atebits.tweetie2": SourceInfo(name: "X", icon: "at", color: "#1DA1F2"),
            "safari": SourceInfo(name: "Safari", icon: "safari", color: "#006CFF"),
            "com.apple.mobilesafari": SourceInfo(name: "Safari", icon: "safari", color: "#006CFF"),
            "chrome": SourceInfo(name: "Chrome", icon: "globe", color: "#4285F4"),
            "com.google.chrome.ios": SourceInfo(name: "Chrome", icon: "globe", color: "#4285F4"),
            "youtube": SourceInfo(name: "YouTube", icon: "play.rectangle", color: "#FF0000"),
            "com.google.ios.youtube": SourceInfo(name: "YouTube", icon: "play.rectangle", color: "#FF0000"),
            "reddit": SourceInfo(name: "Reddit", icon: "bubble.left.and.bubble.right", color: "#FF4500"),
            "com.reddit.reddit": SourceInfo(name: "Reddit", icon: "bubble.left.and.bubble.right", color: "#FF4500"),
        ]

        for (pattern, info) in appMappings {
            if app.contains(pattern) {
                return info
            }
        }

        return nil
    }

    /// Get the best source info considering both URL and source app
    static func bestSource(url: URL?, sourceApp: String?) -> SourceInfo {
        // Prefer app source if available and specific
        if let appSource = extract(fromApp: sourceApp), appSource.name != "Safari" {
            return appSource
        }

        // Fall back to URL extraction
        return extract(from: url)
    }

    /// Extract a clean domain name for display
    private static func extractDomainName(from host: String) -> String {
        // Get the main domain (e.g., "example" from "subdomain.example.com")
        let parts = host.split(separator: ".")

        if parts.count >= 2 {
            // Take second to last part (main domain name)
            let domainPart = String(parts[parts.count - 2])
            // Capitalize first letter
            return domainPart.prefix(1).uppercased() + domainPart.dropFirst()
        }

        return host.prefix(1).uppercased() + host.dropFirst()
    }

    /// Get all unique sources from a collection of items (for filter population)
    static func uniqueSources(from items: [BookmarkItem]) -> [SourceInfo] {
        var seen = Set<String>()
        var sources: [SourceInfo] = []

        for item in items {
            let source = bestSource(url: item.sourceURL, sourceApp: item.sourceApp)
            if !seen.contains(source.name) {
                seen.insert(source.name)
                sources.append(source)
            }
        }

        return sources.sorted { $0.name < $1.name }
    }
}
