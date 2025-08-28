import AnalysisCore
import Foundation

// MARK: - ILP Plan Type
/// PlanType description
public enum PlanType: String, CaseIterable, Sendable {
    case auto = "auto"
    case remediation = "remediation"
    case enrichment = "enrichment"
}


// MARK: - Simplified Student Model for UI
/// SimplifiedStudent represents...
public struct SimplifiedStudent: Identifiable {
    /// id property
    public let id = UUID()
    /// msis property
    public let msis: String
    /// firstName property
    public let firstName: String
    /// lastName property
    public let lastName: String
    /// grade property
    public let grade: Int
    /// school property
    public let school: String
    /// district property
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
    /// toStudentAssessmentData function description
    public func toStudentAssessmentData() -> StudentAssessmentData {
        /// studentInfo property
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
    /// firstName property
    public var firstName: String {
        /// components property
        let components = studentInfo.name.components(separatedBy: " ")
        return components.first ?? ""
    }
    
    /// lastName property
    public var lastName: String {
        /// components property
        let components = studentInfo.name.components(separatedBy: " ")
        guard components.count > 1 else { return "" }
        return components.dropFirst().joined(separator: " ")
    }
    
    /// msis property
    public var msis: String {
        studentInfo.msis
    }
    
    /// testGrade property
    public var testGrade: Int {
        grade
    }
    
    /// testYear property
    public var testYear: Int {
        year
    }
    
    /// schoolYear property
    public var schoolYear: String {
        "\(year - 1)-\(year)"
    }
    
    /// schoolName property
    public var schoolName: String {
        studentInfo.school
    }
    
    /// districtName property
    public var districtName: String {
        studentInfo.district
    }
    
    // Legacy component support
    /// components property
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