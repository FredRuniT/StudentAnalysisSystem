//
//  StandardsMapping.swift
//  StudentAnalysisSystem
//
//  Created by Fredrick Burns on 8/26/25.
//

import Foundation

public struct ScaffoldedStandard: Codable, Sendable {
    public let subject: String
    public let grade: String
    public let strand: String
    public let standard: StandardInfo
    public let reportingCategory: String
    public let studentPerformance: StudentPerformanceCategories
    public let relatedKeywords: Keywords?
    
    public struct StandardInfo: Codable, Sendable {
        public let id: String  // e.g., "6.OA.1", "RL.4.1"
        public let type: String // "Grade-Specific" or "College and Career Readiness Anchor"
        public let description: String
    }
    
    public struct StudentPerformanceCategories: Codable, Sendable {
        public let categories: Categories
        
        public struct Categories: Codable, Sendable {
            public let knowledge: PerformanceItems
            public let understanding: PerformanceItems
            public let skills: PerformanceItems
        }
        
        public struct PerformanceItems: Codable, Sendable {
            public let items: [String]
        }
    }
    
    public struct Keywords: Codable, Sendable {
        public let terms: [String]
    }
}

public struct ReportingCategoryMapping: Codable, Sendable {
    public let testProvider: TestProvider
    public let subject: String
    public let grade: String
    public let reportingCategory: String // RC1, RC2, D1, D2, etc.
    public let description: String
    public let alignedStandards: [String] // Standard IDs that map to this RC
    public let domainMapping: String? // For cross-provider mapping
}
