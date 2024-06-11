# 输出图片尺寸信息

## `_G.img_parser.get_size`

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

> 假定有一张图片的储存路径为: `'./imgs/kaofish.jpg'`, 其尺寸为 *1280x1280* .

```lua
width, height = _G.img_parser.get_size('./imgs/kaofish.jpg')
print(width, height)
-- -> 1280 1280
```

