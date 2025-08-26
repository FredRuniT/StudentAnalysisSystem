//
//  StandardsRepository.swift
//  StudentAnalysisSystem
//
//  Created by Fredrick Burns on 8/26/25.
//

import Foundation
import AnalysisCore

public actor StandardsRepository {
    private var standardsCache: [String: ScaffoldedStandard] = [:]
    private var mappingsCache: [String: ReportingCategoryMapping] = [:]
    private let standardsDirectory: URL
    
    public init(standardsDirectory: URL) {
        self.standardsDirectory = standardsDirectory
    }
    
    public func loadStandards() async throws {
        // Load all scaffolded standards from JSON files
        let standardFiles = try getAllStandardFiles()
        
        for file in standardFiles {
            let data = try Data(contentsOf: file)
            let standard = try JSONDecoder().decode(ScaffoldedStandard.self, from: data)
            standardsCache[standard.standard.id] = standard
        }
        
        // Load RC to standards mappings
        let mappingFiles = try getMappingFiles()
        
        for file in mappingFiles {
            let data = try Data(contentsOf: file)
            let mappings = try JSONDecoder().decode([ReportingCategoryMapping].self, from: data)
            
            for mapping in mappings {
                let key = "\(mapping.testProvider.rawValue)_\(mapping.subject)_\(mapping.grade)_\(mapping.reportingCategory)"
                mappingsCache[key] = mapping
            }
        }
    }
    
    public func getStandardsForComponent(
        component: String,
        grade: String,
        subject: String
    ) async -> [ScaffoldedStandard] {
        // Determine if this is RC or Domain
        let isRC = component.hasPrefix("RC")
        let isDomain = component.hasPrefix("D")
        
        let testProvider: TestProvider = isRC ? .questar : .nwea
        let key = "\(testProvider.rawValue)_\(subject)_\(grade)_\(component)"
        
        guard let mapping = mappingsCache[key] else { return [] }
        
        return mapping.alignedStandards.compactMap { standardsCache[$0] }
    }
    
    public func getScaffoldedStandard(standardId: String) async -> ScaffoldedStandard? {
        return standardsCache[standardId]
    }
    
    public func getPrerequisiteStandards(
        for component: String,
        grade: String
    ) async -> [ScaffoldedStandard] {
        // Get standards from previous grade that build to this component
        let previousGrade = String(Int(grade) ?? 0 - 1)
        
        return standardsCache.values.filter { standard in
            standard.grade == previousGrade &&
            standard.reportingCategory == component
        }
    }
    
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
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(
            at: standardsDirectory.appendingPathComponent("Standards"),
            includingPropertiesForKeys: nil
        )
        return contents.filter { $0.pathExtension == "json" }
    }
    
    private func getMappingFiles() throws -> [URL] {
        let fileManager = FileManager.default
        let blueprintPath = standardsDirectory.appendingPathComponent("MAAP_BluePrints")
        guard fileManager.fileExists(atPath: blueprintPath.path) else {
            return []
        }
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
