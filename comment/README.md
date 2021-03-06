# code comment

一些关于插件的小杂谈，写插件的时候遇到的一些有趣的问题会写一写

## actor_to_style

###### 1. 输入相关

aegisub显示乱码的字符，使用 `unicode.chars()` 遍历到的码点属于负数，依此来判断导入文本是否为UTF-8编码




## clips_printer

###### 1. 绘图指令`p`

当一行字幕使用了`p`标签（绘图指令）时，这行字幕会被整体视为特效区去渲染图形。最显著的特征就是，`karaskel.lua`的`line.text_stripped`返回的文本是空字符串`""`，同时其所有位置信息（除去基础定位点定位）需要手动在绘图代码中抓取。



`p`标签也挺有意思的，都知道`\p1\an7`表示的是绘图的$(0,0)$点，那么其它的对齐方式又是以什么样的形式表现坐标的呢？

上面我也说了，`p`标签会注销掉所有的位置信息，那么其实只要得出pos点表示的是图形上的哪一个坐标就能得知其它坐标的位置。

但是，如果去求pos点其实是一个无序的坐标，我们应该回到原始的消息，绘图$(0,0)$点在哪？

`an7`就在pos点上，其它的对齐方式会和`an7`相对。比如`an7`在`an5`的左上角，那么`an5`的$(0,0)$点就在pos点的左上角，具体的偏移量则是(< $\frac{1}{2}图形宽度$ >, < $\frac{1}{2}图形高度$ >)，同理`an7`在`an9`的左方，则$(0,0)$点的偏移量将是(< -$图形宽度$ >, $0$)。

另一个很有趣的点，虽然Aeg是按照这个规则来偏移的，但是它偏移的量不是固定的，极有可能会出现偏差1个像素的情况，这很大程度上取决Aeg或者说是VSfilter的取整算法。（我换了好几种取整算法就是和Aeg的算出来的有偏差，就很怪，不知道他具体是怎么算的）



###### 2. `clip`标签的bug

`clip`标签很有趣的一点是，它存在很多bug。比如：

1. 当一个`t`标签例存在两个`clip`，它其实不是同步展开的。在`t`结束后显示的其实只有后一个`clip`标签，前面的`clip`标签会被当做`t`的一个中间态去演变。很野蛮。
2. 如果两行轴存在时间重叠，且存在`clip`标签。选中一行，如果另一行存在`\t(\clip)`标签，另一行可能消失。更野蛮了。



###### 3. karaskel相关字幕行信息

文本宽度(`line.width`)和高度(`line.height`)不包括边框厚度和阴影距离

###### 4. 对话框相关

`aegisub.debug.out()`并不包含终止指令，它只是一个GUI输出窗口，`error()`才包含终止指令，或者组合`aegisub.debug.out(); aegisub.cancel()`







## multi_bord

###### 1. 对话框相关`aegisub.dialog.display()`

对话框`floatedit`选项，也就是对话框的浮点对话框，会莫名其妙的输出额外的浮点数字。即用户输入`2.1`会输出`.1 2.1`，很怪啊很怪啊。建议直接用`edit`对话框再通过debug进行输入限制。



一样是`aegisub.dialog.display()`，对话框函数的`buttom`，需要全部选项都遍历到，否则将会忽略选项直接按照运行顺序运行下去，而不会进入选项中。如果只遍历了一个选项，即`if buttom == "Cancel" then aegisub.cancel() end ...`，即使选择了`Cancel`选项也不会进入到这个`if`分支中取消脚本。

###### 2. 字幕对象`(subs, select_lines)`

`select_lines`其实是一个记录了选中行行编号的数表，它本身不记录行数据，这是一个比较容易被忽略的点，虽然很经常用到。所以我们需要用`for _, i do ipirs(select_lines) do l = subs[i] end` 遍历`select_lines`，用`for i, v do ipirs(subs) do l = subs[i] end`遍历`subs`。

那么相应的，`select_lines`也可以用**数值型for**`（for i=1, #n do end）`去遍历。

而使用数值型for有什么作用呢？可以通过这样一个内置的迭代器去迭代循环数`i`，从而辅助计算。比如`multi_bord`的插入行就是通过数值型for去执行的。它也能用来重复行。

```lua
n = 1
for i=1, #sel do
  k = sel[i]+(i-1)*n
  l = subs[k]
  for i=2,n do subs.insert(k, l) end
end
```





