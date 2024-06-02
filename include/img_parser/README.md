# Img Parser

## 说明

[`img_parser`](https://github.com/AliubYiero/aegisub_scripts/tree/master/include/img_parser) 函数库旨在拓展 Aegisub 的图片渲染功能. 

`vsfiltermod` 支持的图片导入 (`\1img`等) 只能传入 `.png` 格式的图片, 并且无法进行图片自适应, 如果字幕绘制的大小超过图片大小, 图片只会重复. 本函数库将解决以下问题. 



## 使用

> <span style="color:red;">警告</span>: 本函数库下的所有路径均不能包含**中文, 中文标点(包括其它非英文语言字符)**. 
> 这属于 Lua 语言的缺陷, 暂时没有好的解决方法. 

> 具体使用见示例文件夹 [test](./test/) , 示例文件夹中包含一系列的 *.ass* 文件 ( *test/img_\*.ass* ) 和一张 *.jpg* 格式的图片 ( *test/imgs/kaofish.jpg* ) , 每个 *.ass* 文件对应一个函数的使用. 

[安装脚本](#安装)后, 可以在 Aegisub 环境中使用 `img_parser` 系列的函数库. 



### 重置图片大小: `_G.img_parser.resize`

`_G.img_parser.resize` 函数接收4个参数, 3个必须参数和1个可选参数, 返回一个字符串: 

```lua
_G.img_parser.resize(filepath, re_width, re_height, resize_way): re_filepath
```

**说明**

`_G.img_parser.resize` 通过 `ImageMagick` 将原始图片 (`filepath`)  , 根据传入的尺寸参数: `re_width` 和 `re_height` , 重新输出新的尺寸的图片 (在原始图片所在的目录下) , 然后返回对应图片的路径. 
(如果图片不是 `.png` 格式将被转换成 `.png` 格式的图片)

> 在运行时, 会一直闪过黑框, 这是 `ImageMagick` 在运行, 属于正常情况. 

> 本函数的本质是输出一张符合要求的**新图片**, 然后将路径指向新的图片. 



**参数**

- `filepath`: **字符串**参数. 原始图片的路径 (**路径中不能存在中文**) .

- `re_width`: **数字**参数. 重新输出的图片的宽度. 
- `re_height`: **数字**参数. 重新输出的图片的高度. 
- `resize_way`: *可选**字符串**参数*. 接受两个字符串值: `'focus'` 和 `'keep'`. 如果不填或者不是这两个字符串, 默认为 `'focus'`

> - `'focus'`: 
>   强制重置大小为 $(re\_width \times re\_height)$.
> - `'keep'`: 
>   保持图片长宽高(以最大的长度进行缩放). 
>   比如, 如果 `re_width` 大于 `re_height`, 则重新输出的大小为: $(re\_width \times re\_width \cdot \frac{width}{height})$



**返回值**

- `re_filepath`: **字符串**返回值. 表示转换后的**图片路径**. 



**示例**

> 假定当前ass文件的路径为: `'D:/subtitle/img_to_png.ass'`
> 假定有一张图片的储存路径为: `'./imgs/kaofish.jpg'`

```lua
re_filepath = _G.img_parser.resize('./imgs/kaofish.jpg', 50, 50)
print(re_filepath)
-- -> 'D:\subtitle\imgs\kaofish(50x50!).png'
```



### 图片转化成png格式: `_G.img_parser.to_png`

`_G.img_parser.to_png` 函数接收1个参数, 返回一个字符串: 

```lua
_G.img_parser.to_png(filepath): re_filepath
```

**说明**

`_G.img_parser.to_png` 能够将原始图片 (`filepath`) 通过 `ImageMagick` 转化成 `.png` 格式的图片, 使其能够正常被输出. 

> 在运行时, 会一直闪过黑框, 这是 `ImageMagick` 在运行, 属于正常情况. 

> 本函数的本质是输出一张符合要求的**新图片**, 然后将路径指向新的图片. 



**参数**

- `filepath`: **字符串**参数. 原始图片的路径 (**路径中不能存在中文**) .



**返回值**

- `re_filepath`: **字符串**返回值. 表示转换后的**图片路径**. 



**示例**

> 假定当前ass文件的路径为: `'D:/subtitle/img_to_png.ass'`
> 假定有一张图片的储存路径为: `'./imgs/kaofish.jpg'`

```lua
re_filepath = _G.img_parser.to_png('./imgs/kaofish.jpg')
print(re_filepath)
-- -> 'D:\subtitle\imgs\kaofish.png'
```





### 输出图片信息: `_G.img_parser.get_size`

`_G.img_parser.get_size` 函数接收1个**字符串**参数, 有两个返回值: `width` 和 `height` , 表示图片的宽高.  

```lua
_G.img_parser.get_size(filepath): width, height
```

**说明**

`_G.img_parser.get_size` 将通过 `ImageMagick` 解析原始图片 (`filepath`) 的尺寸信息, 输出其宽度和高度. 

> 在运行时, 会一直闪过黑框, 这是 `ImageMagick` 在运行, 属于正常情况. 



**参数**

- `filepath`: **字符串**参数. 原始图片的路径 (**路径中不能存在中文**) .



**返回值**

- `width`: **字符串**返回值. 表示图片的**宽度**.
- `height`: **字符串**返回值. 表示图片的**高度**.



**示例**

> 假定有一张图片的储存路径为: `'./imgs/kaofish.jpg'` , 尺寸为 宽720 x 高1080 .

```lua
width, height = _G.img_parser.get_size('./imgs/kaofish.jpg')
print(width, height)
-- -> 720 1080
```



### 暴露出命令行接口: `_G.img_parser.exec`

> 本函数等同于 [`os.execute`](https://www.runoob.com/manual/lua53doc/manual.html#pdf-os.execute) / [`io.popen`](https://www.runoob.com/manual/lua53doc/manual.html#pdf-io.popen) 使用前请确保对**命令行指令调用**有一定的理解. 

`_G.img_parser.exec` 函数接受一个**字符串**参数, 返回一个**字符串**返回值: 

```lua
_G.img_parser.exec(command): result
```



**说明**

> 调用本函数等同于执行以下命令: 

```lua
result = io.popen(command):read('a')
```



**参数**

- `command`: 命令行指令



**返回值**

- `result`: 字符串, 输入命令行指令后的返回值. 



## 安装

1. 电脑安装 [ImageMagick](https://imagemagick.org/) .
2. Aegisub 使用滤镜 `vsfiltermod` , 确保可以使用 `\1img()` 特效标签.
3. 将 [`img_parser.lua`](./img_parser.lua) 文件移动到 Aegisub 目录下 ***[automation/include]*** 目录下.
4. 在 ***[automation/include/utils-auto4.lua]*** 文件中添加环境.



### 安装 ImageMagick

1. 进入链接 [ImageMagick Download (Window)](https://imagemagick.org/script/download.php#windows) 
2. 点击下载最新的安装包 (Window) : `ImageMagick-x.x.x-xx-Q16-HDRI-x64-dll.exe`

> 作者测试使用的版本是 [ImageMagick-7.1.1-33-Q16-HDRI-x64-dll.exe](https://imagemagick.org/archive/binaries/ImageMagick-7.1.1-33-Q16-HDRI-x64-dll.exe)

3. 下载完安装包后双击运行安装
4. 安装完成后, 按照下面步骤验证是否安装成功:
   1. 按下键盘 **[Window + R]** , 弹出 **运行框**
   2. 在 **运行框** 中输入命令 `cmd` , 点击 **确定** , 弹出 **命令提示框** 
   3. 在弹出的命令提示框中输入命令: `magick -version`, 如果提示出版本信息而不是报错, 则说明安装成功. 

> 将提示类似于以下的信息: 

```bat
Version: ImageMagick 7.1.1-33 Q16-HDRI x64 057259c:20240525 https://imagemagick.org
Copyright: (C) 1999 ImageMagick Studio LLC
License: https://imagemagick.org/script/license.php
Features: Channel-masks(64-bit) Cipher DPC HDRI Modules OpenCL OpenMP(2.0)
Delegates (built-in): bzlib cairo flif freetype gslib heic jng jp2 jpeg jxl lcms lqr lzma openexr pangocairo png ps raqm raw rsvg tiff webp xml zip zlib
Compiler: Visual Studio 2022 (193933523)
```



### 在 ***[automation/include/utils-auto4.lua]*** 文件中添加环境.

1. 打开文件 ***[automation/include/utils-auto4.lua]*** , 往下找到包含下面内容的行: 

```lua
util = require 'aegisub.util'
```

2. 在找到的这一行下面添加信息: 

```lua
util = require 'aegisub.util'
-- 添加下面这一行
img_parser = require( 'img_parser' )
```

