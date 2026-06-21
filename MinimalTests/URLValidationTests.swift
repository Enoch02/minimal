import Testing
@testable import Minimal

struct URLValidationTests {
    @Test func validURL() async throws {
        #expect(validateURL("https://example.com") == .valid)
        #expect(validateURL("http://sub.domain.co.uk/path") == .valid)
    }

    @Test func emptyURL() async throws {
        #expect(validateURL("") == .empty)
    }

    @Test func missingScheme() async throws {
        #expect(validateURL("example.com") == .invalidScheme(nil))
    }

    @Test func unsupportedScheme() async throws {
        #expect(validateURL("ftp://example.com") == .invalidScheme("ftp"))
    }

    @Test func missingHost() async throws {
        #expect(validateURL("https://") == .missingHost)
    }

    @Test func invalidHost() async throws {
        #expect(validateURL("https://invalidhost") == .invalidHost("invalidhost"))
    }

    @Test func invalidPath() async throws {
        #expect(validateURL("https://example.com/pa th") == .invalidPath("/pa th"))
    }
}
