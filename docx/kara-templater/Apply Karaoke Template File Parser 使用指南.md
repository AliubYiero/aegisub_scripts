# Apply Karaoke Template File Parser 使用指南



###  加载Lua文件

- `[file://<url>]`

在**说话人栏**输入`[file://<url>]`作为固定格式，`<url>`是文件路径，可以是绝对路径：`D:\demo1.lua`；也可以是相对路径`@\demo2.lua`。



#### 通过绝对路径加载文件

> 假设一个文件`demo1.lua`存在在D盘根路径下：`D:\demo1.lua`

- `[file://D:\demo1.lua]`



#### 通过相对路径加载文件

> 相对路径使用特殊符号 `@` 表示Aegisub安装的根路径，即存放aegisub.exe的目录。

- `[file://@\demo2.lua]`



> 相对路径支持特殊写法 `@<path>` 表示 `<Aegisub根路径>\automation\<path>` 。

- `[file://@src\demo3.lua]` = `[file://@\automation\src\demo3.lua]`
- `[file://@include\demo4.lua]` = `[file://@\automation\include\demo4.lua]`



#### 忽略文件后缀

> 因为默认是使用lua文件，所以文件后缀是可以省略的：

- `[file://@src\demo5]` = `[file://@src\demo5.lua]`



### 文件解析器

> 即使加载了同一个文件，在`code`声明和在 `template`声明的情况下使用的解析器是不同的，所以在书写模板文件时需要遵循一些格式。



#### 注释配置

> 当在模板文件中注释的时候，你可以通过配置项选择是否将注释显示在解析后的文本中。

打开 `kara-templater_file-parser.lua` 文件，可以代码前面看到一个标注**用户配置**的地方：

```lua
-- 用户配置
local user_config = {
    -- 是否显示注释到字幕编辑栏中：`true`为显示 | `false`为不显示
    display_comment = false,
}
```

可以修改 `display_comment` 属性切换是否显示注释。



#### code解析器

##### 代码解析

> 不需要做任何特殊的格式处理，`code`声明本质上就是调用lua代码。



##### 注释

> ！长注释无论如何都不会被解析到字幕文本中。

> 开启注释显示之后，短注释会被解析到字幕文本；
>
> 关闭注释显示之后，只有代码会被正常解析到字幕文本。



#### template解析器

> template解析器只在template行规范的基础上做了些简单的调整，调整的语法兼容的是Lua语法。



##### 注释

> ！长注释无论如何都不会被解析到字幕文本中。

- 短注释：通过两个短横杠 `--` 表示其之后的语句都是注释语句，直到换行。
- 长注释：通过两个短横杠和两个左中括号 `--[[` 表示长注释开始，直到遇到两个右中括号 `]]` 为止，中间的所有语句都是注释语句。

```lua
--[[
	这是一行长注释，他不会被解析到字幕文本中
	长注释可以换行，短注释不可以换行
]]

-- 这是一行短注释，开启注释显示会解析到字幕文本中
```

↓ 解析

```lua
{Comment: 这是一行短注释，开启注释显示会解析到字幕文本中}
```



##### 公共函数

> 公共函数直接书写，每一行表示一条函数。
>
> 不需要书写半角叹号 `!!` 。

> > 公共函数：`maxloop` `retime` `relayer ` 等在Aeg中可以直接使用的、对字幕属性有作用的函数

```lua
-- 函数解析示例
retime("line", -200, 200)
maxloop(100)
```

↓ 解析

```lua
{Comment: 函数解析示例}!retime("line", -200, 200)!!maxloop(100)!
```



##### 特效标签

> 需要包裹在一对**大括号**（即特效区）中，左大括号单独一行，右大括号单独一行；
>
> 每一个特效标签需要使用一对**半角引号**括起来；
>
> 可以不写反斜杠 `\`，但是当不写反斜杠的时候需要每个特效标签单独写一行。

```lua
-- 基础特效标签使用示例
{
    -- 在特效区中使用短注释也不会被解析
    "\p1\an7"	-- 在同一行使用多个标签，但是需要写反斜杠
	"fsc150"	-- 不写反斜杠，但是一行只能书写一个标签
}
```

↓ 解析

```lua
{Comment: 基础特效标签使用示例}{\fsc150\an5}
```



**语法兼容**

> 为了兼容编译器的Lua语法，在template特效区的基础上增加了一些额外的语法支持，这些语法支持并不会改变特效标签的解析，但是能够让用户使用的编译器不会爆红（语法检查报错）。这些额外的语法本质上是将特效区变成一个`table`（Lua类型）。
>
> - 可以在左大括号的左边使用一个变量命名，即 `<name> = {` ；
>
> - 可以在每一行特效标签的后面加一个半角逗号。

```lua
-- 特效标签额外语法示例
tags = {
	"fsc150",
    "an5",
}
```

↓ 解析

```lua
{Comment: 特效标签额外语法示例}{\fsc150\an5}
```





##### 文本

> 通过一对**半角引号** `""` 表示文本。

> > 在特效标签区以外的区域，使用半角括号表示文本，不使用则表示函数

```lua
-- 文本和函数示例
maxloop(100)

{
	"p1"
    "an7"
}

"m 0 0 l 0 100 100 100 100 0"
```

↓ 解析

```lua
{Comment: 文本和函数示例}!maxloop(100)!{\p1\an7}m 0 0 l 0 100 100 100 100 0
```



##### 内联函数

> 在特效标签中使用**内联函数**，如 `math.random` ，`_G.ass_color`，通过 `${}` 进行引用。
>
> 当然也可以直接使用一对**半角叹号** `!!` 使用内联函数，但是这意味着抛弃 `${}` 对内联函数的特殊解析。

```lua
-- 内联函数示例
{
    "fscx${math.random(100)}",
    "fscy!math.random(100)!"
}
```

↓ 解析

```lua
{Comment: 内联函数示例}!{\fscx!math.random(100)!\fscy!math.random(100)!}
```



**内联函数的变量声明**

> 可以在 `${}` 中使用变量声明来储存一个变量，如：`${num = math.random(100)}`；并且在之后引用这个变量：`${num}`。

> > 本质上是自动调用 `remember` 和 `recall` 。

```lua
-- 在内联函数中声明变量
{
	"fscx${num = math.random(100)}",
    "fscx${num}",
}
```

↓ 解析

```lua
{Comment: 在内联函数中声明变量}!{\fscx!remember("num", math.random(100))!\fscx!recall.num!}
```



### 组件

> 前面所阐述的内容都是单文件单模块，即一个lua文件中的所有代码只服务于一行字幕行；
>
> 除此之外，还可以在一个lua文件中注册多个模块，每次调用只调用一个模块，这样就能在同一个lua文件中写入多个不同的模块，比如一个模块负责code行的绘图代码定义，另外一个模块负责在template行中调用这个绘图。这样我们将这个写入了多个模块的lua称之为一个**组件**。
>
> > 当一个文件注册为一个组件时，它将不能按照正常文件名的形式加载调用，需要按模块调用。所以推荐将单文件模块和组件存放在不同的目录下防止错误调用。

#### 注册模块

> 通过 `#<module name>` 可以注册一个模块。这个语句下面的内容将会被视为这个模块的内容，直到遇到另一个注册模块语句或者文件结束。 

```lua
--[[
	下面的内容注册了两个模块：`#code`模块和`#callback shape`模块
	`#code`模块通过`rect`变量定义了一个矩形绘图代码
	`#callback shape`模块调用了这个`rect`变量
]]

#code 
rect = "m 0 0 l 0 100 100 100 100 0"

#callback shape
{
	"\p1\an7"
}
rect
```



**lua语法兼容**

> 因为 `#` 符号并不是一个正常的注释语句，所以在一些编辑器中同样也会爆红（语法检查报错），所以针对模块注册也提供一定的lua语法兼容写法：

- `-- #<module name>`：将 `#<module name>` 使用短注释语句注释起来也是可以将其解析为一个模块的。

```lua
--[[
	模块注册的Lua语法兼容
]]

-- #code 
rect = "m 0 0 l 0 100 100 100 100 0"

-- #callback shape
{
	"\p1\an7"
}
rect
```



#### 调用组件中的模块

> 假如上面的组件的名字是`demo6.lua`，存放的路径是`@src\demo6.lua`。

> 调用组件中的模块需要在文件名之后（文件后缀前）添加上模块名，如 `demo6#code.lua` 就会调用 `demo6.lua `这个组件下的 `#code` 模块。

- 调用 `demo6.lua` 组件下的 `#code` 模块：
  `[file://@src\demo6#code.lua]` = `[file://@src\demo6#code]`

- 调用 `demo6.lua` 组件下的 `#callback shape` 模块：
  `[file://@src\demo6#callback shape.lua]` = `[file://@src\demo6#callback shape]`



