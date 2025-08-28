import Foundation

public actor QUESTARParser: AssessmentParser {
    
    public init() {}
    
    public func parseComponents(from frame: OptimizedDataFrame) async -> [AssessmentComponent] {
        var components: [AssessmentComponent] = []
        
        guard let msisColumn = frame["MSIS"],
              let gradeColumn = frame["GRADE"],
              let subjectColumn = frame["SUBJECT"] else {
            return components
        }
        
        for i in 0..<frame.rowCount {
            guard let msis = msisColumn[i] as? String,
                  let gradeStr = gradeColumn[i] as? String,
                  let subject = subjectColumn[i] as? String else {
                continue
            }
            
            let grade = parseGrade(gradeStr)
            var scores: [String: Double] = [:]
            
            // Extract RC scores (RC1OP through RC5OP)
            for rc in 1...5 {
                if let score = frame["RC\(rc)OP", i] {
                    scores["RC\(rc)OP"] = parseScore(score)
                }
            }
            
            // Extract other scores
            if let totalRS = frame["TOT_RS", i] {
                scores["TOT_RS"] = parseScore(totalRS)
            }
            if let scaleScore = frame["SCALE_SCORE", i] {
                scores["SCALE_SCORE"] = parseScore(scaleScore)
            }
            
            // Extract writing dimensions if present
            for dim in 1...4 {
                if let dimScore = frame["FINAL_DIM\(dim)", i] {
                    scores["DIM\(dim)"] = parseScore(dimScore)
                }
            }
            
            // Extract demographics
            let demographics = extractDemographics(from: frame, row: i)
            
            // Extract proficiency level
            let profLevel = frame["PROF_LVL", i] as? String
            
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
    
    public nonisolated func mapToStandardComponents(_ raw: [String: Double]) -> [String: Double] {
        var mapped: [String: Double] = [:]
        
        // Map QUESTAR RCs to standard components
        let mappings: [String: String] = [
            "RC1OP": "Operations_Algebraic_Thinking",
            "RC2OP": "Number_Sense_Operations",
            "RC3OP": "Measurement_Data",
            "RC4OP": "Geometry",
            "RC5OP": "Data_Analysis"
        ]
        
        for (questarKey, standardKey) in mappings {
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
        if let gradeInt = Int(grade), gradeInt >= 3 && gradeInt <= 12 {
            return gradeInt
        }
        
        // Extract number from strings like "Grade 3" or "03" 
        let numbers = grade.compactMap { $0.isNumber ? Int(String($0)) : nil }
        if let gradeNum = numbers.first, gradeNum >= 3 && gradeNum <= 12 {
            return gradeNum
        }
        // Return -1 for invalid grades to filter them out later
        return -1
    }
    
    private func normalizeSubject(_ subject: String) -> String {
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
        if let doubleValue = value as? Double {
            return doubleValue
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
        if let admin = frame["ADMIN", row] as? String {
            // Extract year from administration string like "2023 Spring 3-8"
            let components = admin.components(separatedBy: " ")
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