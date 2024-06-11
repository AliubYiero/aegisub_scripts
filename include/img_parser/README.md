# Img Parser

## 说明

[`img_parser`](https://github.com/AliubYiero/aegisub_scripts/tree/master/include/img_parser) 函数库旨在拓展 Aegisub 的图片渲染功能. 

`vsfiltermod` 支持的图片导入 (`\1img`等) 只能传入 `.png` 格式的图片, 并且无法进行图片自适应, 如果字幕绘制的大小超过图片大小, 图片只会重复. 本函数库将解决以下问题. 

**函数库/功能**

| 函数                          | 介绍                                                   | 文档                                      |
| ----------------------------- | ------------------------------------------------------ | ----------------------------------------- |
| `_G.img_parser.to_png`        | 任意类型图片转png                                      | [#](./doc/_G.img_parser.to_png.md)        |
| `_G.img_parser.resize`        | 缩放图片尺寸                                           | [#](./doc/_G.img_parser.resize.md)        |
| `_G.img_parser.get_size`      | 获取图片尺寸信息                                       | [#](./doc/_G.img_parser.get_size.md)      |
| `_G.img_parser.decompose_gif` | 将gif图片切割成静态帧, 并输出静态图片信息              | [#](./doc/_G.img_parser.decompose_gif.md) |
| *`_G.img_parser.exec`*        | *命令行调用* (**底层接口**, 不会 `cmd` 命令行命令慎用) | [#](./doc/_G.img_parser.exec.md)          |



## 使用

> <span style="color:red;">警告</span>: 本函数库下的所有路径均不能包含**中文, 中文标点(包括其它非英文语言字符)**. 
> 这属于 Lua 语言的缺陷, 暂时没有好的解决方法. 

> 具体使用见示例文件夹 [test](./test/) , 示例文件夹中包含一系列的 *.ass* 文件 ( *test/img_\*.ass* ) 和一张 *.jpg* 格式的图片 ( *test/imgs/kaofish.jpg* ) , 每个 *.ass* 文件对应一个函数的使用. 

[安装脚本](#安装)后, 可以在 Aegisub 环境中使用 `img_parser` 系列的函数库. 



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

