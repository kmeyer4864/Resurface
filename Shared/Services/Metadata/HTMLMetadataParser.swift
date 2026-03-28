import Foundation

/// Parses HTML content to extract metadata as a fallback when LinkPresentation fails
struct HTMLMetadataParser: Sendable {

    /// Parse HTML string to extract metadata
    /// - Parameters:
    ///   - html: The HTML content to parse
    ///   - baseURL: The base URL for resolving relative URLs
    /// - Returns: Extracted URLMetadata
    static func parse(html: String, baseURL: URL) -> URLMetadata {
        let ogTitle = extractMetaContent(from: html, property: "og:title")
        let ogDescription = extractMetaContent(from: html, property: "og:description")
        let ogImage = extractMetaContent(from: html, property: "og:image")
        let ogSiteName = extractMetaContent(from: html, property: "og:site_name")

        let twitterTitle = extractMetaContent(from: html, name: "twitter:title")
        let twitterDescription = extractMetaContent(from: html, name: "twitter:description")
        let twitterImage = extractMetaContent(from: html, name: "twitter:image")

        let metaDescription = extractMetaContent(from: html, name: "description")
        let metaAuthor = extractMetaContent(from: html, name: "author")

        let htmlTitle = extractTitleTag(from: html)

        // Resolve image URLs
        let imageURLString = ogImage ?? twitterImage
        let imageURL = imageURLString.flatMap { resolveURL($0, baseURL: baseURL) }

        // Construct favicon URL
        let faviconURL = extractFaviconURL(from: html, baseURL: baseURL)
            ?? constructDefaultFaviconURL(from: baseURL)

        // Extract apple-touch-icon if available
        let appleTouchIconURL = extractAppleTouchIconURL(from: html, baseURL: baseURL)

        // Parse publish date if available
        let publishDateString = extractMetaContent(from: html, property: "article:published_time")
            ?? extractMetaContent(from: html, name: "date")
        let publishDate = publishDateString.flatMap { parseDate($0) }

        return URLMetadata(
            title: ogTitle ?? twitterTitle ?? htmlTitle,
            description: ogDescription ?? twitterDescription ?? metaDescription,
            siteName: ogSiteName ?? extractSiteName(from: baseURL),
            author: metaAuthor,
            publishDate: publishDate,
            imageURL: imageURL,
            faviconURL: faviconURL,
            faviconData: nil,
            iconURL: appleTouchIconURL ?? faviconURL
        )
    }

    /// Fetch and parse HTML from a URL
    /// - Parameter url: The URL to fetch
    /// - Returns: Extracted URLMetadata
    static func fetch(url: URL) async throws -> URLMetadata {
        guard url.scheme == "http" || url.scheme == "https" else {
            throw MetadataError.unsupportedScheme
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw MetadataError.fetchFailed(NSError(domain: "HTTPError", code: (response as? HTTPURLResponse)?.statusCode ?? 0))
            }

            guard let html = String(data: data, encoding: .utf8)
                    ?? String(data: data, encoding: .isoLatin1) else {
                throw MetadataError.parsingFailed
            }

            return parse(html: html, baseURL: url)
        } catch let error as MetadataError {
            throw error
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                switch nsError.code {
                case NSURLErrorTimedOut:
                    throw MetadataError.timeout
                case NSURLErrorNotConnectedToInternet,
                     NSURLErrorNetworkConnectionLost:
                    throw MetadataError.networkUnavailable
                default:
                    throw MetadataError.fetchFailed(error)
                }
            }
            throw MetadataError.fetchFailed(error)
        }
    }

    // MARK: - Private Helpers

    /// Extract meta content by property attribute (for Open Graph)
    private static func extractMetaContent(from html: String, property: String) -> String? {
        // Match: <meta property="og:title" content="...">
        let patterns = [
            "<meta[^>]+property=[\"']\(property)[\"'][^>]+content=[\"']([^\"']+)[\"']",
            "<meta[^>]+content=[\"']([^\"']+)[\"'][^>]+property=[\"']\(property)[\"']"
        ]

        for pattern in patterns {
            if let match = html.range(of: pattern, options: .regularExpression, range: nil, locale: nil) {
                let matchString = String(html[match])
                if let contentMatch = matchString.range(of: "content=[\"']([^\"']+)[\"']", options: .regularExpression) {
                    let content = String(matchString[contentMatch])
                    // Extract value between quotes
                    if let start = content.firstIndex(of: "\"") ?? content.firstIndex(of: "'"),
                       let end = content.lastIndex(of: "\"") ?? content.lastIndex(of: "'"),
                       start < end {
                        let value = String(content[content.index(after: start)..<end])
                        return decodeHTMLEntities(value)
                    }
                }
            }
        }
        return nil
    }

    /// Extract meta content by name attribute
    private static func extractMetaContent(from html: String, name: String) -> String? {
        let patterns = [
            "<meta[^>]+name=[\"']\(name)[\"'][^>]+content=[\"']([^\"']+)[\"']",
            "<meta[^>]+content=[\"']([^\"']+)[\"'][^>]+name=[\"']\(name)[\"']"
        ]

        for pattern in patterns {
            if let match = html.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let matchString = String(html[match])
                if let contentMatch = matchString.range(of: "content=[\"']([^\"']+)[\"']", options: .regularExpression) {
                    let content = String(matchString[contentMatch])
                    if let start = content.firstIndex(of: "\"") ?? content.firstIndex(of: "'"),
                       let end = content.lastIndex(of: "\"") ?? content.lastIndex(of: "'"),
                       start < end {
                        let value = String(content[content.index(after: start)..<end])
                        return decodeHTMLEntities(value)
                    }
                }
            }
        }
        return nil
    }

    /// Extract content of <title> tag
    private static func extractTitleTag(from html: String) -> String? {
        let pattern = "<title[^>]*>([^<]+)</title>"
        if let match = html.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
            let matchString = String(html[match])
            if let start = matchString.firstIndex(of: ">"),
               let end = matchString.range(of: "</title>", options: .caseInsensitive)?.lowerBound {
                let value = String(matchString[matchString.index(after: start)..<end])
                return decodeHTMLEntities(value.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
        return nil
    }

    /// Extract favicon URL from link tags
    private static func extractFaviconURL(from html: String, baseURL: URL) -> URL? {
        // Look for: <link rel="icon" href="..."> or <link rel="shortcut icon" href="...">
        let patterns = [
            "<link[^>]+rel=[\"'](?:shortcut )?icon[\"'][^>]+href=[\"']([^\"']+)[\"']",
            "<link[^>]+href=[\"']([^\"']+)[\"'][^>]+rel=[\"'](?:shortcut )?icon[\"']"
        ]

        for pattern in patterns {
            if let match = html.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let matchString = String(html[match])
                if let hrefMatch = matchString.range(of: "href=[\"']([^\"']+)[\"']", options: .regularExpression) {
                    let href = String(matchString[hrefMatch])
                    if let start = href.firstIndex(of: "\"") ?? href.firstIndex(of: "'"),
                       let end = href.lastIndex(of: "\"") ?? href.lastIndex(of: "'"),
                       start < end {
                        let urlString = String(href[href.index(after: start)..<end])
                        return resolveURL(urlString, baseURL: baseURL)
                    }
                }
            }
        }
        return nil
    }

    /// Extract apple-touch-icon URL from link tags
    private static func extractAppleTouchIconURL(from html: String, baseURL: URL) -> URL? {
        let pattern = "<link[^>]+rel=[\"']apple-touch-icon[^\"']*[\"'][^>]+href=[\"']([^\"']+)[\"']"

        if let match = html.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
            let matchString = String(html[match])
            if let hrefMatch = matchString.range(of: "href=[\"']([^\"']+)[\"']", options: .regularExpression) {
                let href = String(matchString[hrefMatch])
                if let start = href.firstIndex(of: "\"") ?? href.firstIndex(of: "'"),
                   let end = href.lastIndex(of: "\"") ?? href.lastIndex(of: "'"),
                   start < end {
                    let urlString = String(href[href.index(after: start)..<end])
                    return resolveURL(urlString, baseURL: baseURL)
                }
            }
        }
        return nil
    }

    /// Construct default favicon URL
    private static func constructDefaultFaviconURL(from url: URL) -> URL? {
        guard let scheme = url.scheme, let host = url.host else { return nil }
        return URL(string: "\(scheme)://\(host)/favicon.ico")
    }

    /// Resolve a potentially relative URL against a base URL
    private static func resolveURL(_ urlString: String, baseURL: URL) -> URL? {
        // If already absolute, return as-is
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            return URL(string: urlString)
        }

        // Handle protocol-relative URLs
        if urlString.hasPrefix("//") {
            return URL(string: "\(baseURL.scheme ?? "https"):\(urlString)")
        }

        // Resolve relative URL
        return URL(string: urlString, relativeTo: baseURL)?.absoluteURL
    }

    /// Extract site name from URL
    private static func extractSiteName(from url: URL) -> String? {
        guard let host = url.host else { return nil }
        var siteName = host
        if siteName.hasPrefix("www.") {
            siteName = String(siteName.dropFirst(4))
        }
        let components = siteName.split(separator: ".")
        if let firstComponent = components.first {
            return String(firstComponent).capitalized
        }
        return nil
    }

    /// Parse ISO 8601 date string
    private static func parseDate(_ dateString: String) -> Date? {
        let formatters = [
            ISO8601DateFormatter(),
        ]

        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }

        // Try common date formats
        let dateFormatter = DateFormatter()
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd",
            "MMMM d, yyyy"
        ]

        for format in formats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
        }

        return nil
    }

    /// Decode common HTML entities
    private static func decodeHTMLEntities(_ string: String) -> String {
        var result = string
        let entities = [
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&#39;", "'"),
            ("&apos;", "'"),
            ("&nbsp;", " "),
            ("&#x27;", "'"),
            ("&#x2F;", "/"),
            ("&#34;", "\""),
        ]

        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }

        return result
    }
}
