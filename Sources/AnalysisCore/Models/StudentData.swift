import Foundation

/// StudentLongitudinalData represents...
public struct StudentLongitudinalData: Sendable {
    /// msis property
    public let msis: String
    /// assessments property
    public let assessments: [AssessmentRecord]
    /// demographics property
    public let demographics: StudentDemographics?
    
    public init(msis: String, assessments: [AssessmentRecord], demographics: StudentDemographics? = nil) {
        self.msis = msis
        self.assessments = assessments.sorted { $0.year < $1.year || ($0.year == $1.year && $0.grade < $1.grade) }
        self.demographics = demographics
    }
    
    /// AssessmentRecord represents...
    public struct AssessmentRecord: Sendable {
        /// year property
        public let year: Int
        /// grade property
        public let grade: Int
        /// season property
        public let season: String?
        /// subject property
        public let subject: String
        /// testProvider property
        public let testProvider: TestProvider
        /// componentScores property
        public let componentScores: [String: Double]
        /// overallScore property
        public let overallScore: Double?
        /// proficiencyLevel property
        public let proficiencyLevel: String?
        /// pass property
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
        
        /// hasCompleteData property
        public var hasCompleteData: Bool {
            !componentScores.isEmpty && overallScore != nil
        }
    }
    
    /// getAssessments function description
    public func getAssessments(for grade: Int) -> [AssessmentRecord] {
        assessments.filter { $0.grade == grade }
    }
    
    /// getAssessments function description
    public func getAssessments(for subject: String) -> [AssessmentRecord] {
        assessments.filter { $0.subject.uppercased() == subject.uppercased() }
    }
    
    /// hasMultiYearData function description
    public func hasMultiYearData(in subject: String) -> Bool {
        /// subjectYears property
        let subjectYears = Set(assessments.filter { 
            $0.subject.uppercased() == subject.uppercased() 
        }.map { $0.year })
        return subjectYears.count >= 2
    }
}

/// StudentAssessmentData represents...
public struct StudentAssessmentData: Sendable {
    /// studentInfo property
    public let studentInfo: StudentInfo
    /// year property
    public let year: Int
    /// grade property
    public let grade: Int
    /// assessments property
    public let assessments: [SubjectAssessment]
    
    public init(studentInfo: StudentInfo, year: Int, grade: Int, assessments: [SubjectAssessment]) {
        self.studentInfo = studentInfo
        self.year = year
        self.grade = grade
        self.assessments = assessments
    }
    
    /// StudentInfo represents...
    public struct StudentInfo: Sendable {
        /// msis property
        public let msis: String
        /// name property
        public let name: String
        /// school property
        public let school: String
        /// district property
        public let district: String
        
        public init(msis: String, name: String, school: String, district: String) {
            self.msis = msis
            self.name = name
            self.school = school
            self.district = district
        }
    }
    
    /// SubjectAssessment represents...
    public struct SubjectAssessment: Sendable {
        /// subject property
        public let subject: String
        /// testProvider property
        public let testProvider: TestProvider
        /// componentScores property
        public let componentScores: [String: Double]
        /// overallScore property
        public let overallScore: Double
        /// proficiencyLevel property
        public let proficiencyLevel: String
        
        public init(subject: String, testProvider: TestProvider, componentScores: [String: Double], overallScore: Double, proficiencyLevel: String) {
            self.subject = subject
            self.testProvider = testProvider
            self.componentScores = componentScores
            self.overallScore = overallScore
            self.proficiencyLevel = proficiencyLevel
        }
    }
    
    /// componentScores property
    public var componentScores: [String: Double] {
        assessments.flatMap { assessment in
            assessment.componentScores.map { (key, value) in
                ("\(assessment.subject)_\(key)", value)
            }
        }.reduce(into: [:]) { $0[$1.0] = $1.1 }
    }
}

/// StudentSingleYearData represents...
public struct StudentSingleYearData: Sendable {
    /// msis property
    public let msis: String
    /// year property
    public let year: Int
    /// grade property
    public let grade: Int
    /// assessmentData property
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
    
    /// getComponentScore function description
    public func getComponentScore(_ component: String) -> Double? {
        assessmentData[component]
    }
}