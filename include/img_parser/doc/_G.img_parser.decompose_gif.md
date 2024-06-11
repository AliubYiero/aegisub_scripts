# 分解 Gif 图片

## `_G.img_parser.decompose_gif`

`_G.img_parser.decompose_gif` 函数接收4个**字符串**参数, 有1个**表**返回值: 

> **分解 Gif 图片**并**获取信息**: 

```lua
_G.img_parser.decompose_gif(filepath): gif_msg_tbl
```

> 分解 Gif 图片并按**尺寸**缩放图片: 

```lua
_G.img_parser.decompose_gif(filepath, re_width, re_height, re_way): gif_msg_tbl
```

> 分解 Gif 图片并按**百分比**缩放图片: 

```lua
_G.img_parser.decompose_gif(filepath, re_percent): gif_msg_tbl
```



**说明**

`_G.img_parser.decompose_gif` 将通过 `ImageMagick` 将原始 Gif 图片 (`filepath`) 拆分成多张静态图片 (`.png` 格式), 并存在在一个文件夹中, 并输出一个包含 Gif 信息的表. 

> 在运行时, 会一直闪过黑框, 这是 `ImageMagick` 在运行, 属于正常情况, 并且由于 Gif 存在多张图片, 转换尺寸的耗时会延长. 



**参数1**

- `filepath`: **字符串**参数. 原始图片的路径 (**路径中不能存在中文**) .

- `re_width`: **数字**参数. 重新输出的图片的**宽度**. 

- `re_height`: **数字**参数. 重新输出的图片的**高度**. 

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

- `gif_msg_tbl`: 一个数值型表: 

  > `gif_info`: 保存分解出来的 Gif 中每张图片的表, 拥有以下属性
  >
  > > - `index`: 当前图片位于 Gif 中的第几帧**索引**. (从0开始)
  > > - `width`: 当前图片的**宽度**. 
  > > - `height`: 当前图片的**高度**. 
  > > - `ms`: 当前图片的**持续时间**. (单位ms)
  > > - `filename`: 分解出来的 `.png` 格式的图片的**地址**. 



**示例**

> 假定当前ass文件的路径为: `'D:/subtitle/img_decompose_gif.ass'`,
> 假定有一张图片的储存路径为: `'./imgs/dog.gif'`, 其尺寸为 *200x200* , 有20帧图片, 每帧持续时间为 10ms .

```lua
-- 分解 Gif 图片
msg_list = _G.img_parser.decompose_gif('./imgs/dog.gif')

print(#msg_list)
-- --> 20

first_frame = msg_list[1]
print(first_frame.width, first_frame.height, first_frame.ms, first_frame.filename)
-- --> 200 200 10 'D:/subtitle/dog/dog-0.png'

second_frame = msg_list[2]
print(second_frame.width, second_frame.height, second_frame.ms, second_frame.filename)
-- --> 200 200 10 'D:/subtitle/dog/dog-1.png'
```

```lua
-- 分解 Gif 图片并将其放大 200%
msg_list = _G.img_parser.decompose_gif('./imgs/dog.gif', 200)

first_frame = msg_list[1]
print(first_frame.width, first_frame.height, first_frame.ms, first_frame.filename)
-- --> 400 400 10 'D:/subtitle/dog(200%)/dog-0.png'

second_frame = msg_list[2]
print(second_frame.width, second_frame.height, second_frame.ms, second_frame.filename)
-- --> 400 400 10 'D:/subtitle/dog(200%)/dog-1.png'
```

