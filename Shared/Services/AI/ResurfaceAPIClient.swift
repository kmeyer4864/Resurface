import Foundation

/// HTTP client for communicating with the Resurface AI backend
actor ResurfaceAPIClient {
    /// Shared instance
    static let shared = ResurfaceAPIClient()

    /// Backend URL - Update this after deploying your Cloudflare Worker
    /// Format: https://resurface-ai.YOUR_SUBDOMAIN.workers.dev
    private let baseURL: URL

    /// Request timeout
    private let timeout: TimeInterval = 30.0

    /// Maximum retries for transient failures
    private let maxRetries = 3

    private init() {
        self.baseURL = URL(string: "https://resurface-ai.keenanmeyer25.workers.dev")!
    }

    /// Analyze content using the AI backend
    /// - Parameter request: The analysis request
    /// - Returns: AI analysis response
    /// - Throws: AIAnalysisError on failure
    func analyzeContent(_ request: AIAnalysisRequest) async throws -> AIAnalysisResponse {
        let url = baseURL.appendingPathComponent("analyze")

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = timeout
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(Bundle.main.bundleIdentifier ?? "com.resurface", forHTTPHeaderField: "X-App-Bundle-Id")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw AIAnalysisError.decodingError(error)
        }

        return try await performRequestWithRetry(urlRequest)
    }

    /// Check if the backend is healthy
    func healthCheck() async -> Bool {
        let url = baseURL.appendingPathComponent("health")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10.0

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    // MARK: - Private

    private func performRequestWithRetry(_ request: URLRequest) async throws -> AIAnalysisResponse {
        var lastError: AIAnalysisError = .networkUnavailable

        for attempt in 0..<maxRetries {
            do {
                return try await performRequest(request)
            } catch let error as AIAnalysisError {
                lastError = error

                guard error.isRetryable else {
                    throw error
                }

                // Exponential backoff
                let delay = pow(2.0, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        throw lastError
    }

    private func performRequest(_ request: URLRequest) async throws -> AIAnalysisResponse {
        let (data, response): (Data, URLResponse)

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .timedOut:
                throw AIAnalysisError.timeout
            case .notConnectedToInternet, .networkConnectionLost:
                throw AIAnalysisError.networkUnavailable
            default:
                throw AIAnalysisError.networkUnavailable
            }
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIAnalysisError.invalidResponse
        }

        // Handle rate limiting
        if httpResponse.statusCode == 429 {
            let retryAfter = Double(httpResponse.value(forHTTPHeaderField: "Retry-After") ?? "60") ?? 60
            throw AIAnalysisError.rateLimited(retryAfter: retryAfter)
        }

        // Handle errors
        if httpResponse.statusCode >= 400 {
            if let errorResponse = try? JSONDecoder().decode(AIErrorResponse.self, from: data) {
                throw AIAnalysisError.serverError(httpResponse.statusCode, errorResponse.error)
            }
            throw AIAnalysisError.serverError(httpResponse.statusCode, "Unknown error")
        }

        // Decode successful response
        do {
            return try JSONDecoder().decode(AIAnalysisResponse.self, from: data)
        } catch {
            throw AIAnalysisError.decodingError(error)
        }
    }
}
