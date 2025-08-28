import Foundation
import SwiftUI
// This file is a command-line tool for macOS only

#if os(macOS)

// MARK: - Design Token Models
struct DesignTokenFile: Codable {
    let tokens: [String: TokenValue]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        var tokensDict: [String: TokenValue] = [:]
        
        for key in container.allKeys {
            if let colorToken = try? container.decode(ColorToken.self, forKey: key) {
                tokensDict[key.stringValue] = .color(colorToken)
            } else if let typographyToken = try? container.decode(TypographyToken.self, forKey: key) {
                tokensDict[key.stringValue] = .typography(typographyToken)
            } else {
                // Skip unknown token types
                continue
            }
        }
        self.tokens = tokensDict
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        for (key, value) in tokens {
            let codingKey = DynamicCodingKeys(stringValue: key)!
            switch value {
            case .color(let colorToken):
                try container.encode(colorToken, forKey: codingKey)
            case .typography(let typographyToken):
                try container.encode(typographyToken, forKey: codingKey)
            }
        }
    }
}

enum TokenValue: Codable {
    case color(ColorToken)
    case typography(TypographyToken)
}

struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}

// MARK: - Token Type Definitions
struct ColorToken: Codable {
    let type: String
    let value: String
    
    private enum CodingKeys: String, CodingKey {
        case type = "$type"
        case value = "$value"
    }
}

struct TypographyToken: Codable {
    let type: String
    let value: TypographyValue
    
    private enum CodingKeys: String, CodingKey {
        case type = "$type"
        case value = "$value"
    }
}

struct TypographyValue: Codable {
    let fontFamily: String
    let fontSize: String
    let fontWeight: Int
    let letterSpacing: String
    let lineHeight: Double
}

struct ShadowToken: Codable {
    let type: String
    let value: [ShadowValue]
    
    private enum CodingKeys: String, CodingKey {
        case type = "$type"
        case value = "$value"
    }
}

struct ShadowValue: Codable {
    let blur: String
    let color: String
    let offsetX: String
    let offsetY: String
    let spread: String
}

// MARK: - Token Parser
class DesignTokenParser {
    
    // Parse JSON file and generate Swift code
    static func generateSwiftCode(from jsonURL: URL) throws -> String {
        let data = try Data(contentsOf: jsonURL)
        let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        var swiftCode = """
        // Generated from Apple Design Tokens
        // Do not edit directly - this file is auto-generated
        
        
        // MARK: - Apple Design Tokens
        struct AppleDesignTokens {
        
        """
        
        // Parse typography tokens
        if let typography = parseTypography(from: jsonObject) {
            swiftCode += typography
        }
        
        // Parse color tokens
        if let colors = parseColors(from: jsonObject) {
            swiftCode += colors
        }
        
        // Parse material tokens
        if let materials = parseMaterials(from: jsonObject) {
            swiftCode += materials
        }
        
        // Parse dimension tokens (spacing, form layouts, etc.)
        if let dimensions = parseDimensions(from: jsonObject) {
            swiftCode += dimensions
        }
        
        swiftCode += "\n}"
        
        return swiftCode
    }
    
    // MARK: - Typography Parser
    private static func parseTypography(from json: [String: Any]) -> String? {
        var typographyCode = "\n    // MARK: - Typography\n    struct Typography {\n"
        
        // Parse typography tokens (01 LargeTitle, 02 Title1, etc.)
        let typographyKeys = json.keys.filter { $0.matches(of: /^\d{2} \w+$/).count > 0 }
        
        for key in typographyKeys.sorted() {
            guard let typeDict = json[key] as? [String: Any] else { continue }
            
            let swiftName = key
                .replacingOccurrences(of: "^\\d{2} ", with: "", options: .regularExpression)
                .lowercasingFirstLetter()
            
            if let defaultStyle = typeDict["Default"] as? [String: Any],
               let textDict = defaultStyle["text"] as? [String: Any],
               let valueDict = textDict["$value"] as? [String: Any] {
                
                let fontSize = (valueDict["fontSize"] as? String ?? "13px")
                    .replacingOccurrences(of: "px", with: "")
                let fontWeight = valueDict["fontWeight"] as? Int ?? 400
                let lineHeight = valueDict["lineHeight"] as? Double ?? 1.2
                
                typographyCode += """
                
                        struct \(swiftName.capitalizedFirstLetter()) {
                            static let fontSize: CGFloat = \(fontSize)
                            static let fontWeight: Font.Weight = .\(fontWeightToSwift(fontWeight))
                            static let lineHeight: CGFloat = \(lineHeight)
                            
                            static var font: Font {
                                Font.system(size: fontSize, weight: fontWeight, design: .default)
                            }
                        }
                
                """
            }
        }
        
        typographyCode += "    }\n"
        return typographyCode
    }
    
    // MARK: - Color Parser
    private static func parseColors(from json: [String: Any]) -> String? {
        var colorCode = "\n    // MARK: - Colors\n    struct Colors {\n"
        
        // Parse System Colors
        if let systemColors = json["System Colors"] as? [String: Any],
           let lightColors = systemColors["Light"] as? [String: Any] {
            
            colorCode += "\n        // MARK: - System Colors\n        struct System {\n"
            
            for (key, value) in lightColors {
                if let colorDict = value as? [String: Any],
                   let colorValue = colorDict["$value"] as? String {
                    
                    let swiftName = key
                        .replacingOccurrences(of: "^\\d+ ", with: "", options: .regularExpression)
                        .lowercasingFirstLetter()
                    
                    colorCode += """
                            static let \(swiftName) = Color(hex: "\(colorValue)")
                    
                    """
                }
            }
            colorCode += "        }\n"
        }
        
        // Parse Label Colors
        if let labelColors = json["Label Colors"] as? [String: Any],
           let lightLabels = labelColors["Light"] as? [String: Any] {
            
            colorCode += "\n        // MARK: - Label Colors\n        struct Labels {\n"
            
            for (key, value) in lightLabels {
                if let colorDict = value as? [String: Any],
                   let colorValue = colorDict["$value"] as? String {
                    
                    let swiftName = key
                        .replacingOccurrences(of: "^\\d+ ", with: "", options: .regularExpression)
                        .replacingOccurrences(of: " ", with: "")
                        .lowercasingFirstLetter()
                    
                    colorCode += """
                            static let \(swiftName) = Color(hex: "\(colorValue)")
                    
                    """
                }
            }
            colorCode += "        }\n"
        }
        
        // Parse Fill Colors
        if let fills = json["Fills"] as? [String: Any],
           let lightFills = fills["Light"] as? [String: Any] {
            
            colorCode += "\n        // MARK: - Fill Colors\n        struct Fills {\n"
            
            for (key, value) in lightFills {
                if let colorDict = value as? [String: Any],
                   let colorValue = colorDict["$value"] as? String {
                    
                    let swiftName = key
                        .replacingOccurrences(of: "^\\d+ ", with: "", options: .regularExpression)
                        .replacingOccurrences(of: " ", with: "")
                        .lowercasingFirstLetter()
                    
                    colorCode += """
                            static let \(swiftName) = Color(hex: "\(colorValue)")
                    
                    """
                }
            }
            colorCode += "        }\n"
        }
        
        colorCode += "    }\n"
        return colorCode
    }
    
    // MARK: - Materials Parser
    private static func parseMaterials(from json: [String: Any]) -> String? {
        var materialCode = "\n    // MARK: - Materials\n    struct Materials {\n"
        
        if let materials = json["-Light"] as? [String: Any],
           let materialsDict = materials["Materials"] as? [String: Any] {
            
            for (key, value) in materialsDict {
                if let fillsArray = value as? [String: Any],
                   let fills = fillsArray["fills"] as? [[String: Any]],
                   let firstFill = fills.first,
                   let colorValue = firstFill["$value"] as? String {
                    
                    let swiftName = key
                        .replacingOccurrences(of: " ", with: "")
                        .lowercasingFirstLetter()
                    
                    materialCode += """
                            static let \(swiftName) = Color(hex: "\(colorValue)")
                    
                    """
                }
            }
        }
        
        materialCode += "    }\n"
        return materialCode
    }
    
    // MARK: - Dimensions Parser
    private static func parseDimensions(from json: [String: Any]) -> String? {
        var dimensionCode = "\n    // MARK: - Dimensions\n    struct Dimensions {\n"
        
        // Parse Form Layout tokens
        if let formLayout = json["Form Layout"] as? [String: Any] {
            dimensionCode += "\n        // MARK: - Form Layout\n        struct FormLayout {\n"
            
            for (key, value) in formLayout {
                if let dimensionDict = value as? [String: Any],
                   let dimensionValue = dimensionDict["$value"] as? String {
                    
                    let swiftName = key
                        .replacingOccurrences(of: " ", with: "")
                        .lowercasingFirstLetter()
                    
                    let numericValue = dimensionValue.replacingOccurrences(of: "px", with: "")
                    
                    dimensionCode += """
                            static let \(swiftName): CGFloat = \(numericValue)
                    
                    """
                }
            }
            dimensionCode += "        }\n"
        }
        
        dimensionCode += "    }\n"
        return dimensionCode
    }
    
    // MARK: - Helper Functions
    private static func fontWeightToSwift(_ weight: Int) -> String {
        switch weight {
        case 100: return "ultraLight"
        case 200: return "thin"
        case 300: return "light"
        case 400: return "regular"
        case 500: return "medium"
        case 600: return "semibold"
        case 700: return "bold"
        case 800: return "heavy"
        case 900: return "black"
        default: return "regular"
        }
    }
}

// MARK: - String Extensions
extension String {
    func lowercasingFirstLetter() -> String {
        return prefix(1).lowercased() + dropFirst()
    }
    
    func capitalizedFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst()
    }
}


// MARK: - Code Generation Script
// Usage: Run this in a build phase script
/*
let parser = DesignTokenParser()
let jsonURL = URL(fileURLWithPath: "path/to/apple-macos-ui-library.tokens.json")
let generatedCode = try parser.generateSwiftCode(from: jsonURL)
try generatedCode.write(to: URL(fileURLWithPath: "path/to/AppleDesignTokens.swift"), atomically: true, encoding: .utf8)
*/

#else
// iOS stub - this file is not used on iOS
struct DesignTokenParser {}

#endif // os(macOS)