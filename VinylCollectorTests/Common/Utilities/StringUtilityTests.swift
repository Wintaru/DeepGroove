import Testing
@testable import VinylCollector

@Suite("StringUtility")
struct StringUtilityTests {

    let utility = StringUtility()

    @Test func extractJSON_plainJSON() {
        let result = utility.extractJSON(from: #"{"artist":"Pink Floyd"}"#)
        #expect(result == #"{"artist":"Pink Floyd"}"#)
    }

    @Test func extractJSON_markdownFenced() {
        let input = "```json\n{\"artist\":\"Pink Floyd\"}\n```"
        let result = utility.extractJSON(from: input)
        #expect(result == "{\"artist\":\"Pink Floyd\"}")
    }

    @Test func extractJSON_leadingText() {
        let input = #"Here is the result: {"artist":"Pink Floyd"}"#
        let result = utility.extractJSON(from: input)
        #expect(result == #"{"artist":"Pink Floyd"}"#)
    }

    @Test func extractJSON_noJSON_returnsNil() {
        let result = utility.extractJSON(from: "just plain text with no braces")
        #expect(result == nil)
    }

    @Test func extractJSON_emptyString_returnsNil() {
        let result = utility.extractJSON(from: "")
        #expect(result == nil)
    }
}
