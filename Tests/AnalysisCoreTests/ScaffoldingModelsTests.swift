import XCTest
@testable import AnalysisCore

@available(iOS 15.0, macOS 12.0, *)
final class ScaffoldingModelsTests: XCTestCase {
    
    // MARK: - Test JSON Data
    
    let sampleScaffoldingJSON = """
    {
        "subject": "Mathematics",
        "grade": "3",
        "domain": "Operations and Algebraic Thinking",
        "reporting_category": "Operations and Algebraic Thinking",
        "standard": {
            "id": "3.OA.1",
            "type": "Grade-Specific",
            "description": "Interpret products of whole numbers"
        },
        "student_performance": {
            "categories": {
                "knowledge": {
                    "label": "A student should know",
                    "items": [
                        "Repeated addition is connected to multiplication.",
                        "Equal groups can be modeled by partitioning rectangles."
                    ]
                },
                "understanding": {
                    "label": "A student should understand",
                    "items": [
                        "Multiplication means 'groups of.'",
                        "Arrays can be used to represent multiplication."
                    ]
                },
                "skills": {
                    "label": "A student should be able to do",
                    "items": [
                        "Find products of whole numbers",
                        "Solve multiplication problems using arrays"
                    ]
                }
            }
        },
        "related_keywords": {
            "terms": ["multiplication", "products", "arrays"]
        }
    }
    """
    
    let sampleArrayJSON = """
    [
        {
            "subject": "Mathematics",
            "grade": "3",
            "strand": "Measurement and Data",
            "reporting_category": "Measurement and Data",
            "standard": {
                "id": "3.MD.5a",
                "type": "Grade-Specific",
                "description": "Recognize area as an attribute"
            },
            "student_performance": {
                "categories": {
                    "knowledge": {
                        "items": ["How to partition rectangles"]
                    },
                    "understanding": {
                        "items": ["Area as two-dimensional space"]
                    },
                    "skills": {
                        "items": ["Cover area with unit squares"]
                    }
                }
            },
            "related_keywords": {
                "terms": ["area", "unit square"]
            }
        }
    ]
    """
    
    // MARK: - Scaffolding Document Tests
    
    func testScaffoldingDocumentDecoding() throws {
        let data = sampleScaffoldingJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let document = try decoder.decode(ScaffoldingDocument.self, from: data)
        
        XCTAssertEqual(document.subject, "Mathematics")
        XCTAssertEqual(document.grade, "3")
        XCTAssertEqual(document.domain, "Operations and Algebraic Thinking")
        XCTAssertEqual(document.reportingCategory, "Operations and Algebraic Thinking")
        XCTAssertEqual(document.standard.id, "3.OA.1")
        XCTAssertEqual(document.id, "3.OA.1") // ID should match standard ID
    }
    
    func testScaffoldingArrayDecoding() throws {
        let data = sampleArrayJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let documents = try decoder.decode([ScaffoldingDocument].self, from: data)
        
        XCTAssertEqual(documents.count, 1)
        XCTAssertEqual(documents[0].standard.id, "3.MD.5a")
        XCTAssertEqual(documents[0].strand, "Measurement and Data")
        XCTAssertNil(documents[0].domain) // Should be nil when only strand is present
    }
    
    func testLearningExpectationsCreation() throws {
        let data = sampleScaffoldingJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        let document = try decoder.decode(ScaffoldingDocument.self, from: data)
        
        let expectations = LearningExpectations(from: document.studentPerformance.categories)
        
        XCTAssertEqual(expectations.knowledge.count, 2)
        XCTAssertEqual(expectations.understanding.count, 2)
        XCTAssertEqual(expectations.skills.count, 2)
        XCTAssertTrue(expectations.knowledge.contains("Repeated addition is connected to multiplication."))
    }
    
    // MARK: - Blueprint Types Tests
    
    func testValidatedCorrelationModel() {
        let correlationData = CorrelationData(
            fromComponent: "Grade_3_MATH_D1OP",
            toComponent: "Grade_5_MATH_D3OP",
            correlation: 0.95,
            fromGrade: 3,
            toGrade: 5,
            subject: "MATH"
        )
        
        let confidenceInterval = ConfidenceInterval(
            lower: 0.92,
            upper: 0.97,
            level: 0.95
        )
        
        let validationMetrics = ValidationMetrics(
            r2Score: 0.90,
            rmse: 0.05,
            mae: 0.03,
            crossValidationScore: 0.88
        )
        
        let validatedModel = ValidatedCorrelationModel(
            base: correlationData,
            sampleSize: 25946,
            confidenceInterval: confidenceInterval,
            pValue: 0.001,
            validationMetrics: validationMetrics
        )
        
        XCTAssertTrue(validatedModel.isStatisticallySignificant)
        XCTAssertEqual(validatedModel.significance, .highlySignificant)
        XCTAssertEqual(validatedModel.base.correlation, 0.95)
    }
    
    func testSignificanceLevels() {
        XCTAssertEqual(SignificanceLevel(pValue: 0.0001), .highlySignificant)
        XCTAssertEqual(SignificanceLevel(pValue: 0.005), .verySignificant)
        XCTAssertEqual(SignificanceLevel(pValue: 0.03), .significant)
        XCTAssertEqual(SignificanceLevel(pValue: 0.06), .notSignificant)
    }
    
    func testLearningObjectiveCreation() {
        let expectations = LearningExpectations(
            knowledge: ["Know multiplication facts"],
            understanding: ["Understand groups of"],
            skills: ["Solve word problems"]
        )
        
        let objective = LearningObjective(
            standard: "3.OA.1",
            description: "Master multiplication concepts",
            expectations: expectations,
            focusArea: .understanding,
            studentLevel: .basic
        )
        
        XCTAssertEqual(objective.standardId, "3.OA.1")
        XCTAssertEqual(objective.targetLevel, .passing)
        XCTAssertEqual(objective.focusArea, .understanding)
        XCTAssertEqual(objective.activities.count, 3)
        XCTAssertEqual(objective.timeEstimate, "8-10 weeks")
    }
    
    func testPredictedOutcome() {
        let outcome = PredictedOutcome(
            component: "Grade_5_MATH_D3OP",
            futureGrade: 5,
            correlationStrength: 0.95,
            probability: 0.92,
            timeframe: "Next school year",
            preventionStrategy: "Focus on Grade 3 Operations"
        )
        
        XCTAssertEqual(outcome.impact, .critical)
        XCTAssertEqual(outcome.correlationStrength, 0.95)
    }
    
    func testMilestoneCreation() {
        let objectives = [
            LearningObjective(
                standardId: "3.OA.1",
                description: "Multiplication",
                targetLevel: .passing,
                focusArea: .understanding,
                activities: ["Practice"],
                timeEstimate: "4 weeks",
                assessmentCriteria: ["80% accuracy"]
            )
        ]
        
        let milestone = Milestone.nineWeekMilestone(
            weekNumber: 9,
            phase: .immediate,
            startDate: Date(),
            objectives: objectives
        )
        
        XCTAssertEqual(milestone.reportCardPeriod, 2)
        XCTAssertEqual(milestone.phase, .immediate)
        XCTAssertEqual(milestone.evaluationType, .reportCard)
        XCTAssertEqual(milestone.expectedProgress, 0.25)
    }
    
    func testProgressEvaluation() {
        let milestoneId = UUID()
        let evaluation = ProgressEvaluation(
            milestoneId: milestoneId,
            evaluationDate: Date(),
            evaluator: "Ms. Smith",
            evaluatorRole: .teacher,
            scores: ["D1OP": 75.0, "D3NBT": 82.0],
            overallProgress: 0.78,
            currentLevel: .passing,
            notes: "Showing good progress",
            attachments: ["worksheet1.pdf"],
            nextSteps: ["Continue multiplication practice"]
        )
        
        XCTAssertEqual(evaluation.evaluatorRole, .teacher)
        XCTAssertEqual(evaluation.scores["D1OP"], 75.0)
        XCTAssertEqual(evaluation.currentLevel, .passing)
    }
    
    // MARK: - Repository Tests
    
    func testScaffoldingRepository() async throws {
        let repository = ScaffoldingRepository()
        
        // Create test documents
        let data = sampleScaffoldingJSON.data(using: .utf8)!
        let decoder = JSONDecoder()
        let document = try decoder.decode(ScaffoldingDocument.self, from: data)
        
        // Store document
        await repository.store(document: document)
        
        // Test retrieval
        let retrieved = await repository.getDocument(standardId: "3.OA.1")
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.standard.id, "3.OA.1")
        
        // Test grade/subject query
        let gradeDocuments = await repository.getDocuments(grade: "3", subject: "Mathematics")
        XCTAssertEqual(gradeDocuments.count, 1)
        
        // Test learning expectations
        let expectations = await repository.getLearningExpectations(standardId: "3.OA.1")
        XCTAssertNotNil(expectations)
        XCTAssertEqual(expectations?.knowledge.count, 2)
        
        // Test keyword search
        let searchResults = await repository.searchByKeywords(["multiplication"], grade: "3")
        XCTAssertEqual(searchResults.count, 1)
        
        // Test document count
        let count = await repository.getDocumentCount()
        XCTAssertEqual(count, 1)
    }
    
    func testStandardProgression() async throws {
        let repository = ScaffoldingRepository()
        
        // This would normally load from real files
        // For testing, we'd need to mock or load test data
        let progression = await repository.getProgression(
            from: 3,
            to: 5,
            domain: "Operations and Algebraic Thinking",
            subject: "Mathematics"
        )
        
        // Would be nil without loaded data
        XCTAssertNil(progression)
    }
    
    // MARK: - Helper Extension Tests
    
    func testProficiencyLevelExtensions() {
        XCTAssertEqual(ProficiencyLevel.minimal.next(), .basic)
        XCTAssertEqual(ProficiencyLevel.basic.next(), .passing)
        XCTAssertEqual(ProficiencyLevel.passing.next(), .proficient)
        XCTAssertEqual(ProficiencyLevel.proficient.next(), .advanced)
        XCTAssertEqual(ProficiencyLevel.advanced.next(), .advanced)
        
        XCTAssertEqual(ProficiencyLevel.minimal.timeToNext(), "10-12 weeks")
        XCTAssertEqual(ProficiencyLevel.basic.timeToNext(), "8-10 weeks")
        XCTAssertEqual(ProficiencyLevel.passing.timeToNext(), "6-8 weeks")
    }
}