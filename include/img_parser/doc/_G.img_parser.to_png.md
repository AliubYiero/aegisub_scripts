# 图片转化成png格式

## `_G.img_parser.to_png`

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

