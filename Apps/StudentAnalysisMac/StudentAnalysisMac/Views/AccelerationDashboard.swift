//
//  AccelerationDashboard.swift
//  StudentAnalysisSystem
//
//  Created by Fredrick Burns on 8/26/25.
//

// Add to Apps/StudentAnalysisMac/Views/AccelerationDashboard.swift

import SwiftUI
import Charts

struct AccelerationDashboard: View {
    @State private var candidates: [AccelerationCandidate] = []
    @State private var selectedCandidate: AccelerationCandidate?
    
    var body: some View {
        NavigationSplitView {
            // Candidate list
            List(candidates) { candidate in
                AccelerationCandidateRow(candidate: candidate)
                    .onTapGesture {
                        selectedCandidate = candidate
                    }
            }
        } detail: {
            if let selected = selectedCandidate {
                AccelerationDetailView(candidate: selected)
            } else {
                Text("Select a candidate to view details")
            }
        }
    }
}

struct AccelerationDetailView: View {
    let candidate: AccelerationCandidate
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Mastery Overview
                MasteryChart(components: candidate.profile.masteredComponents)
                
                // Predicted Strengths
                PredictionVisualization(predictions: candidate.profile.predictedStrengths)
                
                // Pathway Options
                PathwaySelector(pathways: candidate.pathways)
                
                // Generate Plan Button
                Button("Generate Enrichment Plan") {
                    Task {
                        await generatePlan()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
}
