import Foundation
import AnalysisCore

// MARK: - ILP Plan Type
public enum PlanType: String, CaseIterable, Sendable {
    case auto = "auto"
    case remediation = "remediation"
    case enrichment = "enrichment"
}


// MARK: - Simplified Student Model for UI
public struct SimplifiedStudent: Identifiable {
    public let id = UUID()
    public let msis: String
    public let firstName: String
    public let lastName: String
    public let grade: Int
    public let school: String
    public let district: String
    
    public init(msis: String, firstName: String, lastName: String, grade: Int, school: String, district: String) {
        self.msis = msis
        self.firstName = firstName
        self.lastName = lastName
        self.grade = grade
        self.school = school
        self.district = district
    }
    
    // Convert to StudentAssessmentData format
    public func toStudentAssessmentData() -> StudentAssessmentData {
        let studentInfo = StudentAssessmentData.StudentInfo(
            msis: msis,
            name: "\(firstName) \(lastName)",
            school: school,
            district: district
        )
        
        return StudentAssessmentData(
            studentInfo: studentInfo,
            year: 2025,
            grade: grade,
            assessments: []
        )
    }
}

// MARK: - Helper Extensions
extension StudentAssessmentData {
    // Helper properties for UI
    public var firstName: String {
        let components = studentInfo.name.components(separatedBy: " ")
        return components.first ?? ""
    }
    
    public var lastName: String {
        let components = studentInfo.name.components(separatedBy: " ")
        guard components.count > 1 else { return "" }
        return components.dropFirst().joined(separator: " ")
    }
    
    public var msis: String {
        studentInfo.msis
    }
    
    public var testGrade: Int {
        grade
    }
    
    public var testYear: Int {
        year
    }
    
    public var schoolYear: String {
        "\(year - 1)-\(year)"
    }
    
    public var schoolName: String {
        studentInfo.school
    }
    
    public var districtName: String {
        studentInfo.district
    }
    
    // Legacy component support
    public var components: [AssessmentComponent] {
        assessments.flatMap { assessment in
            assessment.componentScores.map { key, value in
                AssessmentComponent(
                    studentID: msis,
                    year: year,
                    grade: grade,
                    testType: assessment.testProvider,
                    subject: assessment.subject,
                    componentScores: [key: value]
                )
            }
        }
    }
}