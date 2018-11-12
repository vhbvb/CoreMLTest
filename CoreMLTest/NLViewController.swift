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
            self.languageRecognnizerTest()
        } else {
            // Fallback on earlier versions
        }
    }
    
    
    @available(iOS 12.0, *)
    func languageRecognnizerTest()
    {
        let text = "困死了我要告告了, 哎, 法克life !!!"
        
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
            print("\ntags:\(obj.0?.rawValue), text:\(text[obj.1])")
        }
    }
}
