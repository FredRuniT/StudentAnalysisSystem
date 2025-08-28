import AnalysisCore
import Foundation
//
//  StandardsMapping.swift
//  StudentAnalysisSystem
//
//  Created by Fredrick Burns on 8/26/25.
//


/// ScaffoldedStandard represents...
public struct ScaffoldedStandard: Codable, Sendable {
    /// subject property
    public let subject: String
    /// grade property
    public let grade: String
    /// strand property
    public let strand: String
    /// standard property
    public let standard: StandardInfo
    /// reportingCategory property
    public let reportingCategory: String
    /// studentPerformance property
    public let studentPerformance: StudentPerformanceCategories
    /// relatedKeywords property
    public let relatedKeywords: Keywords?
    
    /// StandardInfo represents...
    public struct StandardInfo: Codable, Sendable {
        /// id property
        public let id: String  // e.g., "6.OA.1", "RL.4.1"
        /// type property
        public let type: String // "Grade-Specific" or "College and Career Readiness Anchor"
        /// description property
        public let description: String
    }
    
    /// StudentPerformanceCategories represents...
    public struct StudentPerformanceCategories: Codable, Sendable {
        /// categories property
        public let categories: Categories
        
        /// Categories represents...
        public struct Categories: Codable, Sendable {
            /// knowledge property
            public let knowledge: PerformanceItems
            /// understanding property
            public let understanding: PerformanceItems
            /// skills property
            public let skills: PerformanceItems
        }
        
        /// PerformanceItems represents...
        public struct PerformanceItems: Codable, Sendable {
            /// items property
            public let items: [String]
        }
    }
    
    /// Keywords represents...
    public struct Keywords: Codable, Sendable {
        /// terms property
        public let terms: [String]
    }
}

/// ReportingCategoryMapping represents...
public struct ReportingCategoryMapping: Codable, Sendable {
    /// testProvider property
    public let testProvider: TestProvider
    /// subject property
    public let subject: String
    /// grade property
    public let grade: String
    /// reportingCategory property
    public let reportingCategory: String // RC1, RC2, D1, D2, etc.
    /// description property
    public let description: String
    /// alignedStandards property
    public let alignedStandards: [String] // Standard IDs that map to this RC
    /// domainMapping property
    public let domainMapping: String? // For cross-provider mapping
}
