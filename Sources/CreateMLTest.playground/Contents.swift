import Cocoa
import CreateMLUI
import CreateML


let trainingData = try MLDataTable(contentsOf: URL(fileURLWithPath: "/Users/max/Desktop/testClassifier.json"))

//https://www.jianshu.com/p/61780bfd67f1
//let params = MLTextClassifier.ModelParameters(algorithm: .maxEnt(revision: 1)) //最大熵
let params = MLTextClassifier.ModelParameters(algorithm: .crf(revision: 1)) //条件随机场

//let classifier = try MLTextClassifier(trainingData: trainingData, textColumn: "text", labelColumn: "label")
let classifier = try MLTextClassifier(trainingData: trainingData, textColumn: "text", labelColumn: "label", parameters: params)

let trainingAccuracy = 1.0 - classifier.trainingMetrics.classificationError
let validationAccuracy = 1.0 - classifier.validationMetrics.classificationError

let evaluationMetrics = classifier.evaluation(on: trainingData)
let evaluationAccuracy = 1.0 - evaluationMetrics.classificationError

try classifier.write(to: URL(fileURLWithPath: "/Users/max/Desktop/TestClassifier.mlmodel"))


//let buidler = MLImageClassifierBuilder()
//buidler.showInLiveView()



