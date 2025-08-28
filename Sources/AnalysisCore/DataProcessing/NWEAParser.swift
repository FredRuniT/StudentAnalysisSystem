import Foundation

public actor NWEAParser: AssessmentParser {
    
    public init() {}
    
    /// parseComponents function description
    public func parseComponents(from frame: OptimizedDataFrame) async -> [AssessmentComponent] {
        /// components property
        var components: [AssessmentComponent] = []
        
        /// msisColumn property
        guard let msisColumn = frame["MSIS_ID"] ?? frame["MSIS"],
              /// gradeColumn property
              let gradeColumn = frame["GRADE"],
              /// contentColumn property
              let contentColumn = frame["CONTENT_AREA"] ?? frame["SUBJECT"] else {
            return components
        }
        
        for i in 0..<frame.rowCount {
            /// msis property
            guard let msis = msisColumn[i] as? String,
                  /// gradeStr property
                  let gradeStr = gradeColumn[i] as? String,
                  /// content property
                  let content = contentColumn[i] as? String else {
                continue
            }
            
            /// grade property
            let grade = parseGrade(gradeStr)
            /// scores property
            var scores: [String: Double] = [:]
            
            // Extract Domain scores (D1-D8 with OP, PP, PC variants)
            for domain in 1...8 {
                // Overall Performance
                /// op property
                if let op = frame["D\(domain)OP", i] {
                    scores["D\(domain)OP"] = parseScore(op)
                }
                // Performance Percentile
                /// pp property
                if let pp = frame["D\(domain)PP", i] {
                    scores["D\(domain)PP"] = parseScore(pp)
                }
                // Percent Correct
                /// pc property
                if let pc = frame["D\(domain)PC", i] {
                    scores["D\(domain)PC"] = parseScore(pc)
                }
            }
            
            // Extract total scores
            /// dtop property
            if let dtop = frame["DTOP", i] {
                scores["DTOP"] = parseScore(dtop)
            }
            /// scaleScore property
            if let scaleScore = frame["SCALE_SCORE", i] {
                scores["SCALE_SCORE"] = parseScore(scaleScore)
            }
            
            // Extract proficiency level
            /// profLevel property
            let profLevel = frame["PROF_LVL", i] as? String
            
            // Extract writing performance components if present
            for wpc in 1...4 {
                /// wpcScore property
                if let wpcScore = frame["FINAL_WPC\(wpc)", i] {
                    scores["WPC\(wpc)"] = parseScore(wpcScore)
                }
            }
            
            // Extract demographics
            /// demographics property
            let demographics = extractDemographics(from: frame, row: i)
            
            /// component property
            let component = AssessmentComponent(
                studentID: msis,
                year: extractYear(from: frame, row: i),
                grade: grade,
                testType: .nwea,
                subject: normalizeContent(content),
                season: frame["SEASON", i] as? String,
                componentScores: scores,
                demographics: demographics,
                proficiencyLevel: profLevel
            )
            
            components.append(component)
        }
        
        return components
    }
    
    /// mapToStandardComponents function description
    public nonisolated func mapToStandardComponents(_ raw: [String: Double]) -> [String: Double] {
        /// mapped property
        var mapped: [String: Double] = [:]
        
        // Map NWEA domains to standard components
        /// mathMappings property
        let mathMappings: [String: String] = [
            "D1OP": "Operations_Algebraic_Thinking",
            "D2OP": "Number_Sense_Operations",
            "D3OP": "Measurement_Data",
            "D4OP": "Geometry"
        ]
        
        /// elaMappings property
        let elaMappings: [String: String] = [
            "D5OP": "Literature",
            "D6OP": "Informational_Text",
            "D7OP": "Vocabulary",
            "D8OP": "Language_Usage"
        ]
        
        // Apply appropriate mappings
        for (nweaKey, standardKey) in (mathMappings.merging(elaMappings) { $1 }) {
            /// value property
            if let value = raw[nweaKey] {
                mapped[standardKey] = value
            }
        }
        
        // Keep original values and percentile/percent correct variants
        mapped.merge(raw) { _, original in original }
        
        return mapped
    }
    
    private func parseGrade(_ grade: String) -> Int {
        // MAAP is grades 3-12 only
        /// gradeInt property
        if let gradeInt = Int(grade), gradeInt >= 3 && gradeInt <= 12 {
            return gradeInt
        }
        
        // Extract number from strings and validate MAAP range (3-12)
        /// numbers property
        let numbers = grade.compactMap { $0.isNumber ? Int(String($0)) : nil }
        /// gradeNum property
        if let gradeNum = numbers.first, gradeNum >= 3 && gradeNum <= 12 {
            return gradeNum
        }
        // Return -1 for invalid grades to filter them out later
        return -1
    }
    
    private func normalizeContent(_ content: String) -> String {
        /// upperContent property
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
        /// doubleValue property
        if let doubleValue = value as? Double {
            return doubleValue
        /// stringValue property
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
        /// admin property
        if let admin = frame["ADMIN", row] as? String {
            // Extract year from administration string
            /// components property
            let components = admin.components(separatedBy: CharacterSet.decimalDigits.inverted)
            for component in components {
                /// year property
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
    /// parseComponents function description
    func parseComponents(from frame: OptimizedDataFrame) async -> [AssessmentComponent]
    /// mapToStandardComponents function description
    func mapToStandardComponents(_ raw: [String: Double]) -> [String: Double]
}