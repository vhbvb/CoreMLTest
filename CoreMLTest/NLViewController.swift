//
//  NLViewController.swift
//  CoreMLTest
//
//  Created by Max on 2018/11/12.
//  Copyright © 2018 Ever. All rights reserved.
//

import UIKit
import NaturalLanguage

class NLViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        title = "NaturalLanguage"
        if #available(iOS 12.0, *) {
//            self.languageRecognnizerTest()
            customML()
        } else {
            // Fallback on earlier versions
        }
    }
    
    
    @available(iOS 12.0, *)
    func languageRecognnizerTest()
    {
        let text = "困死了我要告告了, 我好伤心 !!!"
        
        let rec = NLLanguageRecognizer()
        
        rec.processString(text)
        
        let lang = rec.dominantLanguage
        let hy = rec.languageHypotheses(withMaximum: 2).map { (key,value) -> (String,Double) in
            (key.rawValue,value)
        }
        
        print("\(lang?.rawValue ?? ""),\nhy:\(hy)")
        
        let tokenizer = NLTokenizer(unit: .word)
        
        tokenizer.string = text
        
        let tokenArray = tokenizer.tokens(for: text.startIndex..<text.endIndex)
        
        for obj in tokenArray {
            print("\n tokenArray:\(text[obj])")
        }
        
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        let tags = tagger.tags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType)
        
        for obj in tags
        {
            print("\ntags:\(String(describing: obj.0?.rawValue)), text:\(text[obj.1])")
        }
    }
    
    @available(iOS 12.0, *)
    func customML()
    {
        //        //CostomModel 官网视频这么写的
        //        if let modelPath = Bundle.main.url(forResource: "testClassifier", withExtension: "mlmodel") {
        //            let model = try? NLModel(contentsOf: modelPath);
        //            let output = model?.predictedLabel(for: text);
        //            print("CostomModel:\(output)")
        //        }
        let text = "it's terrible, much worse than I expected. I am very excited, would definitely recommend it highly! It was OK, something I could live with for now."
        let testClassifier = TestClassifier()
        let output = try? testClassifier.prediction(text: text)
        print("CostomModel:\(output?.label ?? "")")
        
        let scheme = NLTagScheme("MyTagScheme")
        let tagger = NLTagger(tagSchemes: [scheme])
        
        if  let model = try? NLModel(mlModel: testClassifier.model) {
            
            tagger.setModels([model], forTagScheme: scheme)
            tagger.string = text
            let tags = tagger.tags(in: text.startIndex..<text.endIndex, unit: .sentence, scheme: scheme, options: []).map { (arg) -> (String?,String) in
                
                let tm = text[arg.1];
                return (arg.0?.rawValue,String(tm))
            }
            
            print("Customtags:\(tags)")
        }

    }
}

