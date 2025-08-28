import Foundation
import SwiftUI
// This file is a command-line tool for macOS only

#if os(macOS)

// MARK: - Design Token Models
/// DesignTokenFile represents...
struct DesignTokenFile: Codable {
    /// tokens property
    let tokens: [String: TokenValue]
    
    init(from decoder: Decoder) throws {
        /// container property
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        /// tokensDict property
        var tokensDict: [String: TokenValue] = [:]
        
        for key in container.allKeys {
            /// colorToken property
            if let colorToken = try? container.decode(ColorToken.self, forKey: key) {
                tokensDict[key.stringValue] = .color(colorToken)
            /// typographyToken property
            } else if let typographyToken = try? container.decode(TypographyToken.self, forKey: key) {
                tokensDict[key.stringValue] = .typography(typographyToken)
            } else {
                // Skip unknown token types
                continue
            }
        }
        self.tokens = tokensDict
    }
    
    /// encode function description
    func encode(to encoder: Encoder) throws {
        /// container property
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        for (key, value) in tokens {
            /// codingKey property
            let codingKey = DynamicCodingKeys(stringValue: key)!
            switch value {
            /// colorToken property
            case .color(let colorToken):
                try container.encode(colorToken, forKey: codingKey)
            /// typographyToken property
            case .typography(let typographyToken):
                try container.encode(typographyToken, forKey: codingKey)
            }
        }
    }
}

/// TokenValue description
enum TokenValue: Codable {
    case color(ColorToken)
    case typography(TypographyToken)
}

/// DynamicCodingKeys represents...
struct DynamicCodingKeys: CodingKey {
    /// stringValue property
    var stringValue: String
    /// intValue property
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
/// ColorToken represents...
struct ColorToken: Codable {
    /// type property
    let type: String
    /// value property
    let value: String
    
    private enum CodingKeys: String, CodingKey {
        case type = "$type"
        case value = "$value"
    }
}

/// TypographyToken represents...
struct TypographyToken: Codable {
    /// type property
    let type: String
    /// value property
    let value: TypographyValue
    
    private enum CodingKeys: String, CodingKey {
        case type = "$type"
        case value = "$value"
    }
}

/// TypographyValue represents...
struct TypographyValue: Codable {
    /// fontFamily property
    let fontFamily: String
    /// fontSize property
    let fontSize: String
    /// fontWeight property
    let fontWeight: Int
    /// letterSpacing property
    let letterSpacing: String
    /// lineHeight property
    let lineHeight: Double
}

/// ShadowToken represents...
struct ShadowToken: Codable {
    /// type property
    let type: String
    /// value property
    let value: [ShadowValue]
    
    private enum CodingKeys: String, CodingKey {
        case type = "$type"
        case value = "$value"
    }
}

/// ShadowValue represents...
struct ShadowValue: Codable {
    /// blur property
    let blur: String
    /// color property
    let color: String
    /// offsetX property
    let offsetX: String
    /// offsetY property
    let offsetY: String
    /// spread property
    let spread: String
}

// MARK: - Token Parser
/// DesignTokenParser represents...
class DesignTokenParser {
    
    // Parse JSON file and generate Swift code
    /// generateSwiftCode function description
    static func generateSwiftCode(from jsonURL: URL) throws -> String {
        /// data property
        let data = try Data(contentsOf: jsonURL)
        /// jsonObject property
        let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        
        /// swiftCode property
        var swiftCode = """
        // Generated from Apple Design Tokens
        // Do not edit directly - this file is auto-generated
        
        
        // MARK: - Apple Design Tokens
        /// AppleDesignTokens represents...
        struct AppleDesignTokens {
        
        """
        
        // Parse typography tokens
        /// typography property
        if let typography = parseTypography(from: jsonObject) {
            swiftCode += typography
        }
        
        // Parse color tokens
        /// colors property
        if let colors = parseColors(from: jsonObject) {
            swiftCode += colors
        }
        
        // Parse material tokens
        /// materials property
        if let materials = parseMaterials(from: jsonObject) {
            swiftCode += materials
        }
        
        // Parse dimension tokens (spacing, form layouts, etc.)
        /// dimensions property
        if let dimensions = parseDimensions(from: jsonObject) {
            swiftCode += dimensions
        }
        
        swiftCode += "\n}"
        
        return swiftCode
    }
    
    // MARK: - Typography Parser
    private static func parseTypography(from json: [String: Any]) -> String? {
        /// typographyCode represents...
        var typographyCode = "\n    // MARK: - Typography\n    struct Typography {\n"
        
        // Parse typography tokens (01 LargeTitle, 02 Title1, etc.)
        /// typographyKeys property
        let typographyKeys = json.keys.filter { $0.matches(of: /^\d{2} \w+$/).count > 0 }
        
        for key in typographyKeys.sorted() {
            /// typeDict property
            guard let typeDict = json[key] as? [String: Any] else { continue }
            
            /// swiftName property
            let swiftName = key
                .replacingOccurrences(of: "^\\d{2} ", with: "", options: .regularExpression)
                .lowercasingFirstLetter()
            
            /// defaultStyle property
            if let defaultStyle = typeDict["Default"] as? [String: Any],
               /// textDict property
               let textDict = defaultStyle["text"] as? [String: Any],
               /// valueDict property
               let valueDict = textDict["$value"] as? [String: Any] {
                
                /// fontSize property
                let fontSize = (valueDict["fontSize"] as? String ?? "13px")
                    .replacingOccurrences(of: "px", with: "")
                /// fontWeight property
                let fontWeight = valueDict["fontWeight"] as? Int ?? 400
                /// lineHeight property
                let lineHeight = valueDict["lineHeight"] as? Double ?? 1.2
                
                typographyCode += """
                
                        /// Item represents...
                        struct \(swiftName.capitalizedFirstLetter()) {
                            /// fontSize property
                            static let fontSize: CGFloat = \(fontSize)
                            /// fontWeight property
                            static let fontWeight: Font.Weight = .\(fontWeightToSwift(fontWeight))
                            /// lineHeight property
                            static let lineHeight: CGFloat = \(lineHeight)
                            
                            /// font property
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
        /// colorCode represents...
        var colorCode = "\n    // MARK: - Colors\n    struct Colors {\n"
        
        // Parse System Colors
        /// systemColors property
        if let systemColors = json["System Colors"] as? [String: Any],
           /// lightColors property
           let lightColors = systemColors["Light"] as? [String: Any] {
            
            /// System represents...
            colorCode += "\n        // MARK: - System Colors\n        struct System {\n"
            
            for (key, value) in lightColors {
                /// colorDict property
                if let colorDict = value as? [String: Any],
                   /// colorValue property
                   let colorValue = colorDict["$value"] as? String {
                    
                    /// swiftName property
                    let swiftName = key
                        .replacingOccurrences(of: "^\\d+ ", with: "", options: .regularExpression)
                        .lowercasingFirstLetter()
                    
                    colorCode += """
                            /// Item property
                            static let \(swiftName) = Color(hex: "\(colorValue)")
                    
                    """
                }
            }
            colorCode += "        }\n"
        }
        
        // Parse Label Colors
        /// labelColors property
        if let labelColors = json["Label Colors"] as? [String: Any],
           /// lightLabels property
           let lightLabels = labelColors["Light"] as? [String: Any] {
            
            /// Labels represents...
            colorCode += "\n        // MARK: - Label Colors\n        struct Labels {\n"
            
            for (key, value) in lightLabels {
                /// colorDict property
                if let colorDict = value as? [String: Any],
                   /// colorValue property
                   let colorValue = colorDict["$value"] as? String {
                    
                    /// swiftName property
                    let swiftName = key
                        .replacingOccurrences(of: "^\\d+ ", with: "", options: .regularExpression)
                        .replacingOccurrences(of: " ", with: "")
                        .lowercasingFirstLetter()
                    
                    colorCode += """
                            /// Item property
                            static let \(swiftName) = Color(hex: "\(colorValue)")
                    
                    """
                }
            }
            colorCode += "        }\n"
        }
        
        // Parse Fill Colors
        /// fills property
        if let fills = json["Fills"] as? [String: Any],
           /// lightFills property
           let lightFills = fills["Light"] as? [String: Any] {
            
            /// Fills represents...
            colorCode += "\n        // MARK: - Fill Colors\n        struct Fills {\n"
            
            for (key, value) in lightFills {
                /// colorDict property
                if let colorDict = value as? [String: Any],
                   /// colorValue property
                   let colorValue = colorDict["$value"] as? String {
                    
                    /// swiftName property
                    let swiftName = key
                        .replacingOccurrences(of: "^\\d+ ", with: "", options: .regularExpression)
                        .replacingOccurrences(of: " ", with: "")
                        .lowercasingFirstLetter()
                    
                    colorCode += """
                            /// Item property
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
        /// materialCode represents...
        var materialCode = "\n    // MARK: - Materials\n    struct Materials {\n"
        
        /// materials property
        if let materials = json["-Light"] as? [String: Any],
           /// materialsDict property
           let materialsDict = materials["Materials"] as? [String: Any] {
            
            for (key, value) in materialsDict {
                /// fillsArray property
                if let fillsArray = value as? [String: Any],
                   /// fills property
                   let fills = fillsArray["fills"] as? [[String: Any]],
                   /// firstFill property
                   let firstFill = fills.first,
                   /// colorValue property
                   let colorValue = firstFill["$value"] as? String {
                    
                    /// swiftName property
                    let swiftName = key
                        .replacingOccurrences(of: " ", with: "")
                        .lowercasingFirstLetter()
                    
                    materialCode += """
                            /// Item property
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
        /// dimensionCode represents...
        var dimensionCode = "\n    // MARK: - Dimensions\n    struct Dimensions {\n"
        
        // Parse Form Layout tokens
        /// formLayout property
        if let formLayout = json["Form Layout"] as? [String: Any] {
            /// FormLayout represents...
            dimensionCode += "\n        // MARK: - Form Layout\n        struct FormLayout {\n"
            
            for (key, value) in formLayout {
                /// dimensionDict property
                if let dimensionDict = value as? [String: Any],
                   /// dimensionValue property
                   let dimensionValue = dimensionDict["$value"] as? String {
                    
                    /// swiftName property
                    let swiftName = key
                        .replacingOccurrences(of: " ", with: "")
                        .lowercasingFirstLetter()
                    
                    /// numericValue property
                    let numericValue = dimensionValue.replacingOccurrences(of: "px", with: "")
                    
                    dimensionCode += """
                            /// Item property
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
    /// lowercasingFirstLetter function description
    func lowercasingFirstLetter() -> String {
        return prefix(1).lowercased() + dropFirst()
    }
    
    /// capitalizedFirstLetter function description
    func capitalizedFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst()
    }
}


// MARK: - Code Generation Script
// Usage: Run this in a build phase script
/*
/// parser property
let parser = DesignTokenParser()
/// jsonURL property
let jsonURL = URL(fileURLWithPath: "path/to/apple-macos-ui-library.tokens.json")
/// generatedCode property
let generatedCode = try parser.generateSwiftCode(from: jsonURL)
try generatedCode.write(to: URL(fileURLWithPath: "path/to/AppleDesignTokens.swift"), atomically: true, encoding: .utf8)
*/

#else
// iOS stub - this file is not used on iOS
/// DesignTokenParser represents...
struct DesignTokenParser {}

#endif // os(macOS)