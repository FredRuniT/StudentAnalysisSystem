import Foundation
import AnalysisCore

@main
struct TestParser {
    static func main() async {
        print("Testing parser...")
        
        let testFile = URL(fileURLWithPath: "/Users/fredrickburns/Code_Repositories/StudentAnalysisSystem/Data/MAAP_Test_Data/2025_SPRING_3-8_EOC_2520.csv")
        
        do {
            let fileReader = FileReader()
            print("Reading file...")
            let dataFrame = try await fileReader.readAssessmentFile(from: testFile)
            print("File read. Rows: \(dataFrame.rowCount)")
            
            // Just check first few rows
            if let msisCol = dataFrame["MSIS"],
               let d1opCol = dataFrame["D1OP"],
               let scaleCol = dataFrame["SCALE_SCORE"] {
                
                for i in 0..<min(5, dataFrame.rowCount) {
                    let msis = msisCol[i]
                    let d1op = d1opCol[i]
                    let scale = scaleCol[i]
                    print("Row \(i): MSIS=\(msis ?? "nil"), D1OP=\(d1op ?? "nil"), SCALE=\(scale ?? "nil")")
                }
            }
            
            // Now test parser
            print("\nTesting NWEA parser...")
            let parser = NWEAParser()
            let components = await parser.parseComponents(from: dataFrame)
            print("Parsed \(components.count) components")
            
            // Check first component
            if let first = components.first {
                let scores = await first.getAllScores()
                print("First component scores: \(scores)")
            }
            
        } catch {
            print("Error: \(error)")
        }
    }
}