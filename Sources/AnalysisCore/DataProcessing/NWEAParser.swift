import Foundation

public actor NWEAParser: AssessmentParser {
    
    public func parseComponents(from frame: OptimizedDataFrame) async -> [AssessmentComponent] {
        var components: [AssessmentComponent] = []
        
        guard let msisColumn = frame["MSIS_ID"] ?? frame["MSIS"],
              let gradeColumn = frame["GRADE"],
              let contentColumn = frame["CONTENT_AREA"] else {
            return components
        }
        
        for i in 0..<frame.rowCount {
            guard let msis = msisColumn[i] as? String,
                  let gradeStr = gradeColumn[i] as? String,
                  let content = contentColumn[i] as? String else {
                continue
            }
            
            let grade = parseGrade(gradeStr)
            var scores: [String: Double] = [:]
            
            // Extract Domain scores (D1-D8 with OP, PP, PC variants)
            for domain in 1...8 {
                // Overall Performance
                if let op = frame["D\(domain)OP", i] as? Double {
                    scores["D\(domain)OP"] = op
                }
                // Performance Percentile
                if let pp = frame["D\(domain)PP", i] as? Double {
                    scores["D\(domain)PP"] = pp
                }
                // Percent Correct
                if let pc = frame["D\(domain)PC", i] as? Double {
                    scores["D\(domain)PC"] = pc
                }
            }
            
            // Extract total scores
            if let dtop = frame["DTOP", i] as? Double {
                scores["DTOP"] = dtop
            }
            if let scaleScore = frame["SCALE_SCORE", i] as? Double {
                scores["SCALE_SCORE"] = scaleScore
            }
            
            // Extract writing performance components if present
            for wpc in 1...4 {
                if let wpcScore = frame["FINAL_WPC\(wpc)", i] {
                    scores["WPC\(wpc)"] = parseScore(wpcScore)
                }
            }
            
            // Extract demographics
            let demographics = extractDemographics(from: frame, row: i)
            
            let component = AssessmentComponent(
                studentID: msis,
                year: extractYear(from: frame, row: i),
                grade: grade,
                testType: .nwea,
                subject: normalizeContent(content),
                season: frame["SEASON", i] as? String,
                componentScores: scores,
                demographics: demographics
            )
            
            components.append(component)
        }
        
        return components
    }
    
    public nonisolated func mapToStandardComponents(_ raw: [String: Double]) -> [String: Double] {
        var mapped: [String: Double] = [:]
        
        // Map NWEA domains to standard components
        let mathMappings: [String: String] = [
            "D1OP": "Operations_Algebraic_Thinking",
            "D2OP": "Number_Sense_Operations",
            "D3OP": "Measurement_Data",
            "D4OP": "Geometry"
        ]
        
        let elaMappings: [String: String] = [
            "D5OP": "Literature",
            "D6OP": "Informational_Text",
            "D7OP": "Vocabulary",
            "D8OP": "Language_Usage"
        ]
        
        // Apply appropriate mappings
        for (nweaKey, standardKey) in (mathMappings.merging(elaMappings) { $1 }) {
            if let value = raw[nweaKey] {
                mapped[standardKey] = value
            }
        }
        
        // Keep original values and percentile/percent correct variants
        mapped.merge(raw) { _, original in original }
        
        return mapped
    }
    
    private func parseGrade(_ grade: String) -> Int {
        switch grade {
        case "K": return 0
        case "1"..."12": return Int(grade) ?? 0
        default:
            let numbers = grade.compactMap { $0.isNumber ? Int(String($0)) : nil }
            return numbers.first ?? 0
        }
    }
    
    private func normalizeContent(_ content: String) -> String {
        let upperContent = content.uppercased()
        switch upperContent {
        case "MATHEMATICS": return "MATH"
        case "READING": return "ELA"
        case "LANGUAGE USAGE": return "LANGUAGE"
        case "SCIENCE": return "SCIENCE"
        default: return upperContent
        }
    }
    
    private func parseScore(_ value: Any?) -> Double {
        if let doubleValue = value as? Double {
            return doubleValue
        } else if let stringValue = value as? String {
            // Handle non-numeric codes
            switch stringValue {
            case "BB", "IL", "NL", "OT", "XX": return 0
            default: return Double(stringValue) ?? 0
            }
        }
        return 0
    }
    
    private func extractYear(from frame: OptimizedDataFrame, row: Int) -> Int {
        if let admin = frame["ADMIN", row] as? String {
            // Extract year from administration string
            let components = admin.components(separatedBy: CharacterSet.decimalDigits.inverted)
            for component in components {
                if let year = Int(component), year >= 2020, year <= 2030 {
                    return year
                }
            }
        }
        return 2025 // Default to current
    }
    
    private func extractDemographics(from frame: OptimizedDataFrame, row: Int) -> StudentDemographics {
        StudentDemographics(
            iep: (frame["IEP", row] as? String) == "Y",
            lep: frame["LEP", row] as? String,
            disability: frame["DISABILITY", row] as? Int,
            ethnicity: frame["ETHNIC", row] as? String,
            gender: frame["GENDER", row] as? String,
            economicallyDisadvantaged: nil
        )
    }
}

public protocol AssessmentParser {
    func parseComponents(from frame: OptimizedDataFrame) async -> [AssessmentComponent]
    func mapToStandardComponents(_ raw: [String: Double]) -> [String: Double]
}