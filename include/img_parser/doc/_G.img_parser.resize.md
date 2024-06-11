

# 重置图片大小

## `_G.img_parser.resize`

`_G.img_parser.resize` 函数接收4个参数, 返回一个字符串: 

> 按尺寸缩放图片: 

```lua
_G.img_parser.resize(filepath, re_width, re_height, resize_way): re_filepath
```

> 按百分比缩放图片

```lua
_G.img_parser.resize(filepath, re_percent): re_filepath
```



**说明**

`_G.img_parser.resize` 通过 `ImageMagick` 将原始图片 (`filepath`)  , 根据传入的尺寸参数: `re_width` 和 `re_height` , 重新输出新的尺寸的图片 (在原始图片所在的目录下) , 然后返回对应图片的路径. 
(如果图片不是 `.png` 格式将被转换成 `.png` 格式的图片)

> 在运行时, 会一直闪过黑框, 这是 `ImageMagick` 在运行, 属于正常情况. 

> 本函数的本质是输出一张符合要求的**新图片**, 然后将路径指向新的图片. 



**参数1**

- `filepath`: **字符串**参数. 原始图片的路径 (**路径中不能存在中文**) .

- `re_width`: **数字**参数. 重新输出的图片的宽度. 
- `re_height`: **数字**参数. 重新输出的图片的高度. 
- `resize_way`: *可选**字符串**参数*. 接受两个字符串值: `'focus'` 和 `'keep'`. 如果不填或者不是这两个字符串, 默认为 `'focus'`

> - `'focus'`: 硬重置. 
>   强制重置大小为 $(re\_width \times re\_height)$.
> - `'keep'`: 软重置. 
>   保持图片长宽高(以最大的长度进行缩放). 
>   比如, 如果 `re_width` 大于 `re_height`, 则重新输出的大小为: $(re\_width \times re\_width \cdot \frac{width}{height})$



**参数2**

- `filepath`: **字符串**参数. 原始图片的路径 (**路径中不能存在中文**) .

- `re_percent`: **数字**参数. 重新输出的图片相对于图片的**缩放百分比**. 



**返回值**

- `re_filepath`: **字符串**返回值. 表示转换后的**图片路径**. 



**示例**

> 假定当前ass文件的路径为: `'D:/subtitle/img_resize.ass'`
> 假定有一张图片的储存路径为: `'./imgs/kaofish.jpg'`, 其尺寸为 *1280x1280* .

```lua
-- 按尺寸缩放 (强制缩放图片为 50x60 )
re_filepath = _G.img_parser.resize('./imgs/kaofish.jpg', 50, 60)
print(re_filepath)
-- -> 'D:\subtitle\imgs\kaofish(50x60!).png'
-- 重置后的图片的实际尺寸为 50x60
```

```lua
-- 按尺寸缩放 (软缩放图片为 1920x1080 )
re_filepath = _G.img_parser.resize('./imgs/kaofish.jpg', 1920, 1080)
print(re_filepath)
-- -> 'D:\subtitle\imgs\kaofish(1920x1080^).png'
-- 重置后的图片的实际尺寸为 1080x1080 
```

```lua
-- 按百分比缩放 (缩小为原来的 50% )
re_filepath = _G.img_parser.resize('./imgs/kaofish.jpg', 50)
print(re_filepath)
-- -> 'D:\subtitle\imgs\kaofish(50%).png'
-- 重置后的图片的实际尺寸为 640x640
```

