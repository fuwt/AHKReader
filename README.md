![](https://github.com/fuwt/AHKReader/blob/main/Static/img/logo.png?raw=true)

AHKReader 是用 Autohotkey 开发的一款阅读器，可根据自定义规则（ CSS 选择器）收集指定网站的指定文章。

# 配置文件
配置文件为主目录中的 AHKReader.ini 文件。

## [main]
source: 选择需要启动的源，用逗号分隔。

## [xxx]
这里的 xxx 即源的名称。

**url**： *需要采集的网站地址。*

**title**： *源在 AHKReader 中显示的名称。*

**Selector**: *选择器。在 chrome 开发者工具中可直接复制。**注意：这里要写一个集合的选择器，需要删掉 nth-child 之类的语句。***

**script**：（*可选）脚本名称。部分网站的连接可能不是 `<a>` 元素，可以用JavaScript 自行生成连接，脚本已自动创建 ahkReaderContainer 容器，将生成的 `<a>` 元素放入容器即可。支持使用 jQuery，脚本存放目录在主目录的 `Static\js`。**使用script后，Selector 失效。***

**method**: *请求方法。支持 `ie` 和 `xmlhttp` , 默认为 `xmlhttp` ，较节省性能。*

#### script 示例(中纪委网站)
``` javascript
elements = $("body > section > table:nth-child(3) > tbody > tr > td > div > div > ul > li > dt");
elements.each(function(){
  var a = document.createElement("a");
  var title = $(this).children("a").text();
  var href = "http://www.ccdi.gov.cn/fgk/" + $(this).children("form").attr("action");
  a.setAttribute("href", href);
  a.setAttribute("headers", "Referer:http://www.ccdi.gov.cn/fgk/index");
  a.innerText = title;
  ahkReaderContainer.appendChild(a);
});
```



更新记录：

2021-04-23：首次上传

2021-04-24：优化样式，新增静态获取方式