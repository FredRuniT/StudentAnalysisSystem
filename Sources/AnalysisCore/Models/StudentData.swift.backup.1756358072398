import Foundation

public struct StudentLongitudinalData: Sendable {
    public let msis: String
    public let assessments: [AssessmentRecord]
    public let demographics: StudentDemographics?
    
    public init(msis: String, assessments: [AssessmentRecord], demographics: StudentDemographics? = nil) {
        self.msis = msis
        self.assessments = assessments.sorted { $0.year < $1.year || ($0.year == $1.year && $0.grade < $1.grade) }
        self.demographics = demographics
    }
    
    public struct AssessmentRecord: Sendable {
        public let year: Int
        public let grade: Int
        public let season: String?
        public let subject: String
        public let testProvider: TestProvider
        public let componentScores: [String: Double]
        public let overallScore: Double?
        public let proficiencyLevel: String?
        public let pass: Bool?
        
        public init(year: Int, grade: Int, season: String?, subject: String, testProvider: TestProvider,
                    componentScores: [String: Double], overallScore: Double?, proficiencyLevel: String?, pass: Bool?) {
            self.year = year
            self.grade = grade
            self.season = season
            self.subject = subject
            self.testProvider = testProvider
            self.componentScores = componentScores
            self.overallScore = overallScore
            self.proficiencyLevel = proficiencyLevel
            self.pass = pass
        }
        
        public var hasCompleteData: Bool {
            !componentScores.isEmpty && overallScore != nil
        }
    }
    
    public func getAssessments(for grade: Int) -> [AssessmentRecord] {
        assessments.filter { $0.grade == grade }
    }
    
    public func getAssessments(for subject: String) -> [AssessmentRecord] {
        assessments.filter { $0.subject.uppercased() == subject.uppercased() }
    }
    
    public func hasMultiYearData(in subject: String) -> Bool {
        let subjectYears = Set(assessments.filter { 
            $0.subject.uppercased() == subject.uppercased() 
        }.map { $0.year })
        return subjectYears.count >= 2
    }
}

public struct StudentAssessmentData: Sendable {
    public let studentInfo: StudentInfo
    public let year: Int
    public let grade: Int
    public let assessments: [SubjectAssessment]
    
    public init(studentInfo: StudentInfo, year: Int, grade: Int, assessments: [SubjectAssessment]) {
        self.studentInfo = studentInfo
        self.year = year
        self.grade = grade
        self.assessments = assessments
    }
    
    public struct StudentInfo: Sendable {
        public let msis: String
        public let name: String
        public let school: String
        public let district: String
        
        public init(msis: String, name: String, school: String, district: String) {
            self.msis = msis
            self.name = name
            self.school = school
            self.district = district
        }
    }
    
    public struct SubjectAssessment: Sendable {
        public let subject: String
        public let testProvider: TestProvider
        public let componentScores: [String: Double]
        public let overallScore: Double
        public let proficiencyLevel: String
        
        public init(subject: String, testProvider: TestProvider, componentScores: [String: Double], overallScore: Double, proficiencyLevel: String) {
            self.subject = subject
            self.testProvider = testProvider
            self.componentScores = componentScores
            self.overallScore = overallScore
            self.proficiencyLevel = proficiencyLevel
        }
    }
    
    public var componentScores: [String: Double] {
        assessments.flatMap { assessment in
            assessment.componentScores.map { (key, value) in
                ("\(assessment.subject)_\(key)", value)
            }
        }.reduce(into: [:]) { $0[$1.0] = $1.1 }
    }
}

public struct StudentSingleYearData: Sendable {
    public let msis: String
    public let year: Int
    public let grade: Int
    public let assessmentData: [String: Double]
    
    public init(
        msis: String,
        year: Int,
        grade: Int,
        assessmentData: [String: Double]
    ) {
        self.msis = msis
        self.year = year
        self.grade = grade
        self.assessmentData = assessmentData
    }
    
    public func getComponentScore(_ component: String) -> Double? {
        assessmentData[component]
    }
}