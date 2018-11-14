import Cocoa
import CreateML

let trainingData = try MLDataTable(contentsOf: URL(fileURLWithPath: "/Users/max/Desktop/testClassifier.json"))

//https://www.jianshu.com/p/61780bfd67f1
//let params = MLTextClassifier.ModelParameters(algorithm: .maxEnt(revision: 1)) //最大熵
let params = MLTextClassifier.ModelParameters(algorithm: .crf(revision: 1)) //条件随机场

//let model = try MLTextClassifier(trainingData: trainingData, textColumn: "text", labelColumn: "label")
let model = try MLTextClassifier(trainingData: trainingData, textColumn: "text", labelColumn: "label", parameters: params)

try model.write(to: URL(fileURLWithPath: "/Users/max/Desktop/TestClassifier.mlmodel"))




