[toc]
<br/>
<br/>

NaturalLanguage
--

使用自然语言框架来执行诸如语言和脚本识别、标记化、引理化、词性标记和命名实体识别等任务。您还可以在Create ML中使用这个框架来训练和部署定制的自然语言模型。

**代码：**
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
<br/>

CreateML
--

Create ML利用照片和Siri等Apple产品内置的机器学习基础架构。这意味着您的图像分类和自然语言模型更小，训练时间更短。

主要类别：
- 图像分类(MLImageClassifier)
- 自然语言处理（NL）
- 表格数据(MLDataTable)


#### 1. TextClassifier(文本识别)

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

//let classifier = try MLTextClassifier(trainingData: trainingData, textColumn: "text", labelColumn: "label")
let classifier = try MLTextClassifier(trainingData: trainingData, textColumn: "text", labelColumn: "label", parameters: params)

let trainingAccuracy = 1.0 - classifier.trainingMetrics.classificationError
let validationAccuracy = 1.0 - classifier.validationMetrics.classificationError

let evaluationMetrics = classifier.evaluation(on: trainingData)
let evaluationAccuracy = 1.0 - evaluationMetrics.classificationError

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
    
    您必须对模型进行评估，以确定什么选项适合您的应用程序。当你获得你的训练数据,你为你的数据分组,为验证组,与测试组.你通常使用评估的测试结果优化算法的参数设置,测试参数设置。我们鼓励你这样做，并且还鼓励您做的另一件事是在现有数据集外的数据上进行测试。比如假设您正在建立一个酒店评价模型，您希望将酒店评论分类为不同的评级。用户抛出一个完全超出数据集的数据。也许这与餐馆评论或电影评论有关，你的模型是否足够的灵活性来应付它。
    
#### 2. ImageClassifier (图片分类)


```
import CreateMLUI

let buidler = MLImageClassifierBuilder()
buidler.showInLiveView()

```

点击xcode 的双环即可出现model操作界面。直接把准备好的训练集拖进model即可开始训练，训练完可以看到准确度等信息，满意了可以导出mlmodel,使用方法同上text的classifier model.

CoreMLTool
--

- 主页：https://pypi.org/project/coremltools/
- 简介：帮助开发者简单的将机器学习(ML)模型集成到xcode中，将包括深度神经网络(卷积神经网络和递归神经网络)、带boost的树集成和广义线性模型 转换为一种公共文件格式(.mlmodel)，这种格式的模型可以通过Xcode直接集成到应用程序中。
- 功能简介:

    - 转换模型格式
    - 通过api可以通过mlmodel文件格式解释model
    - 通过mlmodel进行预测
- 安装：

    ```
    pip install -U coremltools
    ```

- 关于量化

    在iOS 11中，Core ML模型存储在32位模型中。借助iOS 12，Apple让我们能够将模型存储在16位甚至8位模型中
    
    *如果你不熟悉什么是量化，这里有一个非常好的类比。说你要从你家到超市。第一次，你可能走一条路。第二次，您将尝试找到一条通往超市的较短路径，因为您已经了解了进入市场的方式。第三次，您将采用更短的路线，因为您已了解前两条路径。每次去市场的时候，你会继续服用一个较短的路径，你学习一段时间！知道哪条路线的知识称为权重。因此，最准确的路径是权重最大的路径！*

   **脚本：**

```python
    import coremltools
    
    from coremltools.models.neural_network.quantization_utils import *
    
    model = coremltools.models.MLModel('/Users/max/Desktop/v3/Inceptionv3.mlmodel')
    
    lin_quant_model = quantize_weights(model,  16,  "linear")
    # lin_quant_model  =  quantize_weights(model,  16,  "kmeans")
    # lin_quant_model = quantize_weights(model,  8,  "kmeans")
    
    lin_quant_model.save('/Users/max/Desktop/v3/QuantizedInceptionv3.mlmodel')
    
    # pip install Pillow 比较2个model的精度
    compare_models(model,lin_quant_model,'/Users/max/Downloads/sampleimages')
```

    
结果比较显示100％，这意味着它与我们的模型匹配100％。但是大小 小了一半，我们可以继续降低模型量化位数，8位或者4位，观察精度变化与体积变化

![image](https://upload-images.jianshu.io/upload_images/910914-d02988ccca46dbe8.jpg)

<br/>
<br/>

Turi Create
--
#### 官方简介：

Turi Create简化了自定义机器学习模型的开发。你可以很简单的添加行为建议，对象检测，图像分类，图像相似度或活动分类到你的应用。而且你不必是一个机器学习专家

- 易于使用: 关注任务本身而不是算法
- 可视化: 内建的，流式可视化来探索你的数据
- 灵活: 支持文本、图像、音频、视频和传感器数据
- 快速和可扩展: 可以在一台机器上就可以处理大型数据集
- 准备部署: 可以模型导出为Core ML格式，以便在iOS、macOS、watchOS和tvOS应用程序中使用

**开源地址：**
https://github.com/apple/turicreate

#### 安装：

```
pip install -U turicreate
```

苹果官方推荐用virtualenv创建python2.7环境（一般macOS默认即为2.7的环境，所以一般不需要此步骤）：

```
pip install virtualenv
virtualenv venv
source ~/venv/bin/activate
pip install -U turicreate
```

#### 示例：

官网示例: https://developer.apple.com/videos/play/wwdc2018/712/ (说的是object detection)

创建一个图片分类器示例：

**准备数据：**
- SexClassifierSource/train 用于训练
- SexClassifierSource/test 用于测试

**脚本：**

```python

import turicreate as tc
# 加载训练集
images  = tc.image_analysis.load_images("/Users/max/Desktop/CoreMLWorkSpace/SexClassifierSource/train")
# 添加标签
images["label"] = list(map(lambda x:x.split("/")[-2], images["path"]))
# 保存数据集
images.save("/Users/max/Desktop/CoreMLWorkSpace/tmp/sex.sframe")
# 创建训练模型 第一次运行会下载一些东西
model = tc.image_classifier.create(images, target="label")
# 同样的方式加载测试集
testImages = tc.image_analysis.load_images("/Users/max/Desktop/CoreMLWorkSpace/SexClassifierSource/test")
testImages["label"] = [x.split("/")[-2] for x in testImages["path"]]
# 通过测试集评价
model.evaluate(testImages)

#查看 错误集
predictions = model.predict(testImages)
wrong = testImages[testImages["label"] != predictions]
wrong.explore()

#导出mlmodel
model.export_coreml("/Users/max/Desktop/CoreMLWorkSpace/tmp/turiCreatedSexClassifier.mlmodel")
```

**说明：**

不同的场景只是 数据集的格式差异，比如object detection 需要的label和coordinate， 其他基本操作基本相同（见wwdc视频）

**支持的任务类型：**

| ML Task                 | Description                      |
|:------------------------:|:--------------------------------:|
| [Recommender](https://apple.github.io/turicreate/docs/userguide/recommender/)             | Personalize choices for users    |
| [Image Classification](https://apple.github.io/turicreate/docs/userguide/image_classifier/)    | Label images                     |
| [Object Detection](https://apple.github.io/turicreate/docs/userguide/object_detection/)        | Recognize objects within images  |
| [Style Transfer](https://apple.github.io/turicreate/docs/userguide/style_transfer/)        | Stylize images |
| [Activity Classification](https://apple.github.io/turicreate/docs/userguide/activity_classifier/) | Detect an activity using sensors |
| [Image Similarity](https://apple.github.io/turicreate/docs/userguide/image_similarity/)        | Find similar images              |
| [Classifiers](https://apple.github.io/turicreate/docs/userguide/supervised-learning/classifier.html)             | Predict a label           |
| [Regression](https://apple.github.io/turicreate/docs/userguide/supervised-learning/regression.html)              | Predict numeric values           |
| [Clustering](https://apple.github.io/turicreate/docs/userguide/clustering/)              | Group similar datapoints together|
| [Text Classifier](https://apple.github.io/turicreate/docs/userguide/text_classifier/)         | Analyze sentiment of messages    |


<br/>

参考链接：
--

- [WWDC: A Guide to Turi Create](https://developer.apple.com/videos/play/wwdc2018/712/)
- [turiCreate功能：图片识别](https://www.jianshu.com/p/49f8dc5f2f47)
- [Core ML 2有什么新功能](https://www.jianshu.com/p/b6e3cb7338bf)
- [Introducing Natural Language Framework](https://developer.apple.com/videos/play/wwdc2018/713)