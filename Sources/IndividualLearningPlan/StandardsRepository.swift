import AnalysisCore
import Foundation
//
//  StandardsRepository.swift
//  StudentAnalysisSystem
//
//  Created by Fredrick Burns on 8/26/25.
//


public actor StandardsRepository {
    private var standardsCache: [String: ScaffoldedStandard] = [:]
    private var mappingsCache: [String: ReportingCategoryMapping] = [:]
    private let standardsDirectory: URL
    
    public init(standardsDirectory: URL) {
        self.standardsDirectory = standardsDirectory
    }
    
    /// loadStandards function description
    public func loadStandards() async throws {
        // Load all scaffolded standards from JSON files
        /// standardFiles property
        let standardFiles = try getAllStandardFiles()
        
        for file in standardFiles {
            /// data property
            let data = try Data(contentsOf: file)
            /// standard property
            let standard = try JSONDecoder().decode(ScaffoldedStandard.self, from: data)
            standardsCache[standard.standard.id] = standard
        }
        
        // Load RC to standards mappings
        /// mappingFiles property
        let mappingFiles = try getMappingFiles()
        
        for file in mappingFiles {
            /// data property
            let data = try Data(contentsOf: file)
            /// mappings property
            let mappings = try JSONDecoder().decode([ReportingCategoryMapping].self, from: data)
            
            for mapping in mappings {
                /// key property
                let key = "\(mapping.testProvider.rawValue)_\(mapping.subject)_\(mapping.grade)_\(mapping.reportingCategory)"
                mappingsCache[key] = mapping
            }
        }
    }
    
    /// getStandardsForComponent function description
    public func getStandardsForComponent(
        component: String,
        grade: String,
        subject: String
    ) async -> [ScaffoldedStandard] {
        // Determine if this is RC (QUESTAR) or Domain (NWEA)
        /// isRC property
        let isRC = component.hasPrefix("RC")
        
        /// testProvider property
        let testProvider: TestProvider = isRC ? .questar : .nwea
        /// key property
        let key = "\(testProvider.rawValue)_\(subject)_\(grade)_\(component)"
        
        /// mapping property
        guard let mapping = mappingsCache[key] else { return [] }
        
        return mapping.alignedStandards.compactMap { standardsCache[$0] }
    }
    
    /// getScaffoldedStandard function description
    public func getScaffoldedStandard(standardId: String) async -> ScaffoldedStandard? {
        return standardsCache[standardId]
    }
    
    /// getPrerequisiteStandards function description
    public func getPrerequisiteStandards(
        for component: String,
        grade: String
    ) async -> [ScaffoldedStandard] {
        // Get standards from previous grade that build to this component
        /// previousGrade property
        let previousGrade = String(Int(grade) ?? 0 - 1)
        
        return standardsCache.values.filter { standard in
            standard.grade == previousGrade &&
            standard.reportingCategory == component
        }
    }
    
    /// getEnrichmentStandards function description
    public func getEnrichmentStandards(
        baseComponent: String,
        targetComponent: String,
        grade: String
    ) async -> [ScaffoldedStandard] {
        // Find standards that bridge between components
        return standardsCache.values.filter { standard in
            standard.grade == grade &&
            isRelatedToComponents(standard, base: baseComponent, target: targetComponent)
        }
    }
    
    // Helper functions
    private func getAllStandardFiles() throws -> [URL] {
        /// fileManager property
        let fileManager = FileManager.default
        /// contents property
        let contents = try fileManager.contentsOfDirectory(
            at: standardsDirectory.appendingPathComponent("Standards"),
            includingPropertiesForKeys: nil
        )
        return contents.filter { $0.pathExtension == "json" }
    }
    
    private func getMappingFiles() throws -> [URL] {
        /// fileManager property
        let fileManager = FileManager.default
        /// blueprintPath property
        let blueprintPath = standardsDirectory.appendingPathComponent("MAAP_BluePrints")
        guard fileManager.fileExists(atPath: blueprintPath.path) else {
            return []
        }
        /// contents property
        let contents = try fileManager.contentsOfDirectory(
            at: blueprintPath,
            includingPropertiesForKeys: nil
        )
        return contents.filter { $0.pathExtension == "json" }
    }
    
    private func isRelatedToComponents(
        _ standard: ScaffoldedStandard,
        base: String,
        target: String
    ) -> Bool {
        // Simple check - can be enhanced with more sophisticated logic
        return standard.reportingCategory == base || 
               standard.reportingCategory == target
    }
}
