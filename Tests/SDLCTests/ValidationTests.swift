import Testing
@testable import SDLCApp
import Foundation

struct ValidationTests {
    
    // MARK: - Name Validation
    
    @Test func testNameCannotBeEmpty() throws {
        #expect(throws: ValidationError.self) {
            try InputValidator.validateName("", fieldName: "Name")
        }
    }
    
    @Test func testNameCannotBeWhitespaceOnly() throws {
        #expect(throws: ValidationError.self) {
            try InputValidator.validateName("   ", fieldName: "Name")
        }
    }
    
    @Test func testNameExceedsMaxLength() throws {
        let longName = String(repeating: "a", count: 201)
        #expect(throws: ValidationError.self) {
            try InputValidator.validateName(longName, fieldName: "Name")
        }
    }
    
    @Test func testNameAtMaxLengthSucceeds() throws {
        let validName = String(repeating: "a", count: 200)
        try InputValidator.validateName(validName, fieldName: "Name")
    }
    
    @Test func testNameTrimsWhitespace() throws {
        try InputValidator.validateName("  valid name  ", fieldName: "Name")
    }
    
    // MARK: - Description Validation
    
    @Test func testDescriptionExceedsMaxLength() throws {
        let longDesc = String(repeating: "a", count: 5001)
        #expect(throws: ValidationError.self) {
            try InputValidator.validateDescription(longDesc)
        }
    }
    
    @Test func testDescriptionAtMaxLengthSucceeds() throws {
        let validDesc = String(repeating: "a", count: 5000)
        try InputValidator.validateDescription(validDesc)
    }
    
    @Test func testEmptyDescriptionSucceeds() throws {
        try InputValidator.validateDescription("")
    }
    
    @Test func testDescriptionCustomMaxLength() throws {
        let longDesc = String(repeating: "a", count: 101)
        #expect(throws: ValidationError.self) {
            try InputValidator.validateDescription(longDesc, maxLength: 100)
        }
    }
    
    // MARK: - Path Validation
    
    @Test func testPathCannotBeEmpty() throws {
        #expect(throws: ValidationError.self) {
            try InputValidator.validatePath("")
        }
    }
    
    @Test func testPathCannotBeWhitespaceOnly() throws {
        #expect(throws: ValidationError.self) {
            try InputValidator.validatePath("   ")
        }
    }
    
    @Test func testPathMustExist() throws {
        #expect(throws: ValidationError.self) {
            try InputValidator.validatePath("/nonexistent/path/to/nowhere")
        }
    }
    
    @Test func testValidPathSucceeds() throws {
        try InputValidator.validatePath("/tmp")
    }
    
    // MARK: - ValidationError
    
    @Test func testValidationErrorHasMessage() {
        let error = ValidationError("Test error")
        #expect(error.message == "Test error")
        #expect(error.errorDescription == "Test error")
    }
}
