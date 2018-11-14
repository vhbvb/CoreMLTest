NaturalLanguage
--

##### 简介：

使用自然语言框架来执行诸如语言和脚本识别、标记化、引理化、词性标记和命名实体识别等任务。您还可以在Create ML中使用这个框架来训练和部署定制的自然语言模型。

##### 上代码：
```swift
let text = "困死了我要告告了"

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
```

##### 训练和定制

- 准备训练数据，Json格式：
```
[{
"text": "I am really excited, would definitely recommend it highly!",
"label": "Positive"
}, {
"text": "It was OK, something I could live with for now.",
"label": "Neutral"
}, {
"text": "This was terrible, much worse than I expected.",
"label": "Negative"
}]
```

- Playground执行脚本创建自定义模型，注意创建Playground的时候平台选择macOS

```swift
import Cocoa
import CreateML

let trainingData = try MLDataTable(contentsOf: URL(fileURLWithPath: "/Users/max/Desktop/testClassifier.json"))

//https://www.jianshu.com/p/61780bfd67f1
//let params = MLTextClassifier.ModelParameters(algorithm: .maxEnt(revision: 1)) //最大熵
let params = MLTextClassifier.ModelParameters(algorithm: .crf(revision: 1)) //条件随机场

//let model = try MLTextClassifier(trainingData: trainingData, textColumn: "text", labelColumn: "label")
let model = try MLTextClassifier(trainingData: trainingData, textColumn: "text", labelColumn: "label", parameters: params)

try model.write(to: URL(fileURLWithPath: "/Users/max/Desktop/TestClassifier.mlmodel"))


```

- 使用模型

直接把生成的mlmodel拖进xcode


```swift
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
```


- 模型训练细节须知：

我想强调的是在你的传统开发过程中，当你有开发一个应用的想法时，你会设想一个开发流程。你可以把机器学习想象成一种非常相似的工作流程。

从哪里开始，从数据开始，然后你有了数据，你要问几个问题。你必须验证你的训练数据，必须确保你的数据中没有虚假的例子，并且它没有被污染。只有这样做之后，才可以可以检查每个类的有效训练实例数。

假设你的训练是情绪分类模型，你有一千个积极情绪的例子，你有五个消极情绪的例子，这样你不能训练出一个健壮的model来鉴别或区分这两个类。你必须确保每个类别的训练样本是合理平衡的。一旦你的数据没有了上述问题，下一步就是训练。

正如我前面提到的，我们的建议是，您应该运行可用的不同选项（最大熵与条件随机场），并找出什么是好的，但是如何定义什么是好的呢?

您必须对模型进行评估，以确定什么选项适合您的应用程序。当你获得你的训练数据,你为你的数据分组,为验证组,与测试组.你通常使用评估的测试结果优化算法的参数设置,测试参数设置。我们鼓励你这样做，并且还鼓励您做的另一件事是在现有数据集外的数据上进行测试。比如假设您正在建立一个酒店评价模型，您希望将酒店评论分类为不同的评级。用户抛出一个完全超出数据集的数据。也许这与餐馆评论或电影评论有关，你的模特是否足够的灵活性来应付它。

##### 参考链接：

- [Core ML 2有什么新功能](https://www.jianshu.com/p/b6e3cb7338bf)
- [Introducing Natural Language Framework](https://developer.apple.com/videos/play/wwdc2018/713)

- 官方介绍：

I'd like to emphasize is sort of draw[inaudible] between your conventional development process, So when you have an idea for an app, you go through a development cycle. So you can think of machine learning to be a very similar sort of workflow. 

Where do you start,you start with data, and then you have data, you have to ask a couple of questions. You have to validate your training data,
You have to make sure that there are no spurious examples in your data, and it's not tainted. Once you do that , you can inspect the number of training instances per class.
let's say that your training a sentiment classifacation model, and you have a thousand examples for positive sentiment ,you have five example for negative sentiment, you can't train a robust model that can determine or distinguish between those two classes. You have to make sure that the training samples for each of those classes are reasonably balanced. So once you do that with data, the nextstep is training. As I mention before, our recommendation us that you run the different options that are available and figure out what is good , but how do you define what is good.

You have to evaluate the model in order to figure out what suits your application .So next step here int the workflow is evaluation. Evalaution in convention [inaudiable] for machine learning is that when you procure your training data, you split your data into traing inset, into a validation set, adn into a test set, and you typically tune the parameters of the algorithm using the valudation set, and you test in the test set. So we encourange you to do the same thing, apply the same sort of guidelines that you have stood machine learning in good stead for a long time. the other thing that we also encourage you to do is test on out-of-domain data. So when you have a idea for an app, you think of a certain type of data that is going to be ingested by your machine learning model. Now let's say you're building an for hotel review, and you want to classify hotel reviews into different sorts of ratings. and user throws a data that is completely out of domain. Perhaps it's something to do with a restaurant review or a movie review, is your model rebust enough to handle it.
