import Foundation

public actor QUESTARParser: AssessmentParser {
    
    public init() {}
    
    /// parseComponents function description
    public func parseComponents(from frame: OptimizedDataFrame) async -> [AssessmentComponent] {
        /// components property
        var components: [AssessmentComponent] = []
        
        /// msisColumn property
        guard let msisColumn = frame["MSIS"],
              /// gradeColumn property
              let gradeColumn = frame["GRADE"],
              /// subjectColumn property
              let subjectColumn = frame["SUBJECT"] else {
            return components
        }
        
        for i in 0..<frame.rowCount {
            /// msis property
            guard let msis = msisColumn[i] as? String,
                  /// gradeStr property
                  let gradeStr = gradeColumn[i] as? String,
                  /// subject property
                  let subject = subjectColumn[i] as? String else {
                continue
            }
            
            /// grade property
            let grade = parseGrade(gradeStr)
            /// scores property
            var scores: [String: Double] = [:]
            
            // Extract RC scores (RC1OP through RC5OP)
            for rc in 1...5 {
                /// score property
                if let score = frame["RC\(rc)OP", i] {
                    scores["RC\(rc)OP"] = parseScore(score)
                }
            }
            
            // Extract other scores
            /// totalRS property
            if let totalRS = frame["TOT_RS", i] {
                scores["TOT_RS"] = parseScore(totalRS)
            }
            /// scaleScore property
            if let scaleScore = frame["SCALE_SCORE", i] {
                scores["SCALE_SCORE"] = parseScore(scaleScore)
            }
            
            // Extract writing dimensions if present
            for dim in 1...4 {
                /// dimScore property
                if let dimScore = frame["FINAL_DIM\(dim)", i] {
                    scores["DIM\(dim)"] = parseScore(dimScore)
                }
            }
            
            // Extract demographics
            /// demographics property
            let demographics = extractDemographics(from: frame, row: i)
            
            // Extract proficiency level
            /// profLevel property
            let profLevel = frame["PROF_LVL", i] as? String
            
            /// component property
            let component = AssessmentComponent(
                studentID: msis,
                year: extractYear(from: frame, row: i),
                grade: grade,
                testType: .questar,
                subject: normalizeSubject(subject),
                season: frame["TERM", i] as? String,
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
        
        // Map QUESTAR RCs to standard components
        /// mappings property
        let mappings: [String: String] = [
            "RC1OP": "Operations_Algebraic_Thinking",
            "RC2OP": "Number_Sense_Operations",
            "RC3OP": "Measurement_Data",
            "RC4OP": "Geometry",
            "RC5OP": "Data_Analysis"
        ]
        
        for (questarKey, standardKey) in mappings {
            /// value property
            if let value = raw[questarKey] {
                mapped[standardKey] = value
            }
        }
        
        // Keep original values too
        mapped.merge(raw) { _, original in original }
        
        return mapped
    }
    
    private func parseGrade(_ grade: String) -> Int {
        // MAAP is grades 3-12 only
        /// gradeInt property
        if let gradeInt = Int(grade), gradeInt >= 3 && gradeInt <= 12 {
            return gradeInt
        }
        
        // Extract number from strings like "Grade 3" or "03" 
        /// numbers property
        let numbers = grade.compactMap { $0.isNumber ? Int(String($0)) : nil }
        /// gradeNum property
        if let gradeNum = numbers.first, gradeNum >= 3 && gradeNum <= 12 {
            return gradeNum
        }
        // Return -1 for invalid grades to filter them out later
        return -1
    }
    
    private func normalizeSubject(_ subject: String) -> String {
        /// upperSubject property
        let upperSubject = subject.uppercased()
        switch upperSubject {
        case "MATH", "MATHEMATICS": return "MATH"
        case "ELA", "ENGLISH": return "ELA"
        case "ALGEBRA I", "ALGEBRA_I": return "ALGEBRA_I"
        case "ENGLISH II", "ENGLISH_II": return "ENGLISH_II"
        default: return upperSubject
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
            case "BB", "IL", "NL", "OT", "XX", "CP": return 0
            default: return Double(stringValue) ?? 0
            }
        }
        return 0
    }
    
    private func extractYear(from frame: OptimizedDataFrame, row: Int) -> Int {
        /// admin property
        if let admin = frame["ADMIN", row] as? String {
            // Extract year from administration string like "2023 Spring 3-8"
            /// components property
            let components = admin.components(separatedBy: " ")
            /// yearStr property
            if let yearStr = components.first, let year = Int(yearStr) {
                return year
            }
        }
        return 2023 // Default
    }
    
    private func extractDemographics(from frame: OptimizedDataFrame, row: Int) -> StudentDemographics {
        StudentDemographics(
            iep: (frame["IEP", row] as? String) == "Y",
            lep: frame["LEP", row] as? String,
            disability: frame["DISABILITY", row] as? Int,
            ethnicity: frame["ETHNIC", row] as? String,
            gender: frame["GENDER", row] as? String,
            economicallyDisadvantaged: nil // Not in QUESTAR data
        )
    }
}