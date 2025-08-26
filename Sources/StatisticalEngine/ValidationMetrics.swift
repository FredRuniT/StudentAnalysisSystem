import Foundation

public struct ValidationMetrics: Sendable {
    
    public struct ConfusionMatrix: Sendable {
        public let truePositives: Int
        public let falsePositives: Int
        public let trueNegatives: Int
        public let falseNegatives: Int
        
        public var total: Int {
            truePositives + falsePositives + trueNegatives + falseNegatives
        }
        
        public var accuracy: Double {
            Double(truePositives + trueNegatives) / Double(total)
        }
        
        public var precision: Double {
            guard truePositives + falsePositives > 0 else { return 0 }
            return Double(truePositives) / Double(truePositives + falsePositives)
        }
        
        public var recall: Double {
            guard truePositives + falseNegatives > 0 else { return 0 }
            return Double(truePositives) / Double(truePositives + falseNegatives)
        }
        
        public var f1Score: Double {
            guard precision + recall > 0 else { return 0 }
            return 2 * (precision * recall) / (precision + recall)
        }
        
        public var specificity: Double {
            guard trueNegatives + falsePositives > 0 else { return 0 }
            return Double(trueNegatives) / Double(trueNegatives + falsePositives)
        }
        
        public var matthewsCorrelation: Double {
            let numerator = Double(truePositives * trueNegatives - falsePositives * falseNegatives)
            let denominator = sqrt(
                Double((truePositives + falsePositives) *
                       (truePositives + falseNegatives) *
                       (trueNegatives + falsePositives) *
                       (trueNegatives + falseNegatives))
            )
            guard denominator > 0 else { return 0 }
            return numerator / denominator
        }
    }
    
    public struct CrossValidationResult: Sendable {
        public let folds: Int
        public let meanAccuracy: Double
        public let stdAccuracy: Double
        public let meanPrecision: Double
        public let meanRecall: Double
        public let meanF1: Double
        public let foldResults: [FoldResult]
        
        public struct FoldResult: Sendable {
            public let foldIndex: Int
            public let accuracy: Double
            public let precision: Double
            public let recall: Double
            public let f1Score: Double
            public let confusionMatrix: ConfusionMatrix
        }
    }
    
    public static func calculateROCCurve(
        scores: [Double],
        labels: [Bool],
        thresholds: Int = 100
    ) -> (fpr: [Double], tpr: [Double], auc: Double) {
        let minScore = scores.min() ?? 0
        let maxScore = scores.max() ?? 1
        let step = (maxScore - minScore) / Double(thresholds)
        
        var fprValues: [Double] = []
        var tprValues: [Double] = []
        
        for i in 0...thresholds {
            let threshold = minScore + Double(i) * step
            let predictions = scores.map { $0 >= threshold }
            
            var tp = 0, fp = 0, tn = 0, fn = 0
            for (pred, label) in zip(predictions, labels) {
                switch (pred, label) {
                case (true, true): tp += 1
                case (true, false): fp += 1
                case (false, true): fn += 1
                case (false, false): tn += 1
                }
            }
            
            let fpr = Double(fp) / (Double(fp + tn) + 1e-10)
            let tpr = Double(tp) / (Double(tp + fn) + 1e-10)
            
            fprValues.append(fpr)
            tprValues.append(tpr)
        }
        
        // Calculate AUC using trapezoidal rule
        var auc = 0.0
        for i in 1..<fprValues.count {
            auc += (fprValues[i] - fprValues[i-1]) * (tprValues[i] + tprValues[i-1]) / 2
        }
        
        return (fprValues, tprValues, auc)
    }
    
    public static func calculateCohenKappa(
        predictions: [Int],
        actual: [Int]
    ) -> Double {
        guard predictions.count == actual.count else { return 0 }
        
        let n = Double(predictions.count)
        var observed = 0.0
        
        // Calculate observed agreement
        for (pred, act) in zip(predictions, actual) {
            if pred == act { observed += 1 }
        }
        observed /= n
        
        // Calculate expected agreement
        let categories = Set(predictions + actual)
        var expected = 0.0
        
        for category in categories {
            let predCount = Double(predictions.filter { $0 == category }.count)
            let actCount = Double(actual.filter { $0 == category }.count)
            expected += (predCount / n) * (actCount / n)
        }
        
        // Calculate kappa
        guard expected < 1.0 else { return 1.0 }
        return (observed - expected) / (1.0 - expected)
    }
    
    public static func meanAbsoluteError(predictions: [Double], actual: [Double]) -> Double {
        guard predictions.count == actual.count, !predictions.isEmpty else { return 0 }
        
        let errors = zip(predictions, actual).map { abs($0 - $1) }
        return errors.reduce(0, +) / Double(errors.count)
    }
    
    public static func meanSquaredError(predictions: [Double], actual: [Double]) -> Double {
        guard predictions.count == actual.count, !predictions.isEmpty else { return 0 }
        
        let errors = zip(predictions, actual).map { pow($0 - $1, 2) }
        return errors.reduce(0, +) / Double(errors.count)
    }
    
    public static func rootMeanSquaredError(predictions: [Double], actual: [Double]) -> Double {
        return sqrt(meanSquaredError(predictions: predictions, actual: actual))
    }
}