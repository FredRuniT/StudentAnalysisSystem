//
//  StandardsRepository.swift
//  StudentAnalysisSystem
//
//  Created by Fredrick Burns on 8/26/25.
//

import Foundation

public actor StandardsRepository {
    private var standardsCache: [String: ScaffoldedStandard] = [:]
    private var mappingsCache: [String: ReportingCategoryMapping] = [:]
    private let fileLoader: StandardsFileLoader
    
    public init(standardsDirectory: URL) {
        self.fileLoader = StandardsFileLoader(directory: standardsDirectory)
    }
    
    public func loadStandards() async throws {
        // Load all scaffolded standards from JSON files
        let standardFiles = try fileLoader.getAllStandardFiles()
        
        for file in standardFiles {
            let data = try Data(contentsOf: file)
            let standard = try JSONDecoder().decode(ScaffoldedStandard.self, from: data)
            standardsCache[standard.standard.id] = standard
        }
        
        // Load RC to standards mappings
        let mappingFiles = try fileLoader.getMappingFiles()
        
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
            standard.reportingCategory == getReportingCategory(for: component)
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
}
