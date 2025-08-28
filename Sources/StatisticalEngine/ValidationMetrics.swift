import Foundation

/// ValidationMetrics represents...
public struct ValidationMetrics: Sendable, Codable {
    
    /// ConfusionMatrix represents...
    public struct ConfusionMatrix: Sendable, Codable {
        /// truePositives property
        public let truePositives: Int
        /// falsePositives property
        public let falsePositives: Int
        /// trueNegatives property
        public let trueNegatives: Int
        /// falseNegatives property
        public let falseNegatives: Int
        
        /// total property
        public var total: Int {
            truePositives + falsePositives + trueNegatives + falseNegatives
        }
        
        /// accuracy property
        public var accuracy: Double {
            Double(truePositives + trueNegatives) / Double(total)
        }
        
        /// precision property
        public var precision: Double {
            guard truePositives + falsePositives > 0 else { return 0 }
            return Double(truePositives) / Double(truePositives + falsePositives)
        }
        
        /// recall property
        public var recall: Double {
            guard truePositives + falseNegatives > 0 else { return 0 }
            return Double(truePositives) / Double(truePositives + falseNegatives)
        }
        
        /// f1Score property
        public var f1Score: Double {
            guard precision + recall > 0 else { return 0 }
            return 2 * (precision * recall) / (precision + recall)
        }
        
        /// specificity property
        public var specificity: Double {
            guard trueNegatives + falsePositives > 0 else { return 0 }
            return Double(trueNegatives) / Double(trueNegatives + falsePositives)
        }
        
        /// matthewsCorrelation property
        public var matthewsCorrelation: Double {
            /// numerator property
            let numerator = Double(truePositives * trueNegatives - falsePositives * falseNegatives)
            /// denominator property
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
    
    /// CrossValidationResult represents...
    public struct CrossValidationResult: Sendable, Codable {
        /// folds property
        public let folds: Int
        /// meanAccuracy property
        public let meanAccuracy: Double
        /// stdAccuracy property
        public let stdAccuracy: Double
        /// meanPrecision property
        public let meanPrecision: Double
        /// meanRecall property
        public let meanRecall: Double
        /// meanF1 property
        public let meanF1: Double
        /// foldResults property
        public let foldResults: [FoldResult]
        
        /// FoldResult represents...
        public struct FoldResult: Sendable, Codable {
            /// foldIndex property
            public let foldIndex: Int
            /// accuracy property
            public let accuracy: Double
            /// precision property
            public let precision: Double
            /// recall property
            public let recall: Double
            /// f1Score property
            public let f1Score: Double
            /// confusionMatrix property
            public let confusionMatrix: ConfusionMatrix
        }
    }
    
    /// calculateROCCurve function description
    public static func calculateROCCurve(
        scores: [Double],
        labels: [Bool],
        thresholds: Int = 100
    ) -> (fpr: [Double], tpr: [Double], auc: Double) {
        // Ensure thresholds is positive
        /// validThresholds property
        let validThresholds = max(1, thresholds)
        
        /// minScore property
        let minScore = scores.min() ?? 0
        /// maxScore property
        let maxScore = scores.max() ?? 1
        /// step property
        let step = (maxScore - minScore) / Double(validThresholds)
        
        /// fprValues property
        var fprValues: [Double] = []
        /// tprValues property
        var tprValues: [Double] = []
        
        for i in 0...validThresholds {
            /// threshold property
            let threshold = minScore + Double(i) * step
            /// predictions property
            let predictions = scores.map { $0 >= threshold }
            
            /// tp property
            var tp = 0, fp = 0, tn = 0, fn = 0
            for (pred, label) in zip(predictions, labels) {
                switch (pred, label) {
                case (true, true): tp += 1
                case (true, false): fp += 1
                case (false, true): fn += 1
                case (false, false): tn += 1
                }
            }
            
            /// fpr property
            let fpr = Double(fp) / (Double(fp + tn) + 1e-10)
            /// tpr property
            let tpr = Double(tp) / (Double(tp + fn) + 1e-10)
            
            fprValues.append(fpr)
            tprValues.append(tpr)
        }
        
        // Calculate AUC using trapezoidal rule
        /// auc property
        var auc = 0.0
        for i in 1..<fprValues.count {
            auc += (fprValues[i] - fprValues[i-1]) * (tprValues[i] + tprValues[i-1]) / 2
        }
        
        return (fprValues, tprValues, auc)
    }
    
    /// calculateCohenKappa function description
    public static func calculateCohenKappa(
        predictions: [Int],
        actual: [Int]
    ) -> Double {
        guard predictions.count == actual.count else { return 0 }
        
        /// n property
        let n = Double(predictions.count)
        /// observed property
        var observed = 0.0
        
        // Calculate observed agreement
        for (pred, act) in zip(predictions, actual) {
            if pred == act { observed += 1 }
        }
        observed /= n
        
        // Calculate expected agreement
        /// categories property
        let categories = Set(predictions + actual)
        /// expected property
        var expected = 0.0
        
        for category in categories {
            /// predCount property
            let predCount = Double(predictions.filter { $0 == category }.count)
            /// actCount property
            let actCount = Double(actual.filter { $0 == category }.count)
            expected += (predCount / n) * (actCount / n)
        }
        
        // Calculate kappa
        guard expected < 1.0 else { return 1.0 }
        return (observed - expected) / (1.0 - expected)
    }
    
    /// meanAbsoluteError function description
    public static func meanAbsoluteError(predictions: [Double], actual: [Double]) -> Double {
        guard predictions.count == actual.count, !predictions.isEmpty else { return 0 }
        
        /// errors property
        let errors = zip(predictions, actual).map { abs($0 - $1) }
        return errors.reduce(0, +) / Double(errors.count)
    }
    
    /// meanSquaredError function description
    public static func meanSquaredError(predictions: [Double], actual: [Double]) -> Double {
        guard predictions.count == actual.count, !predictions.isEmpty else { return 0 }
        
        /// errors property
        let errors = zip(predictions, actual).map { pow($0 - $1, 2) }
        return errors.reduce(0, +) / Double(errors.count)
    }
    
    /// rootMeanSquaredError function description
    public static func rootMeanSquaredError(predictions: [Double], actual: [Double]) -> Double {
        return sqrt(meanSquaredError(predictions: predictions, actual: actual))
    }
}