# Apply Karaoke Template File Parser

`Apply Karaoke Template File Parser`是一个用于将读取文件解析成模板文本，填写在字幕编辑栏，并应用卡拉OK模板的插件。



## 基础使用

> > 当前的说明只针对简单的入门使用，不保证内容是否会过时，更多的功能介绍和具体使用说明请参照[[说明文档]](./Apply%20Karaoke%20Template%20File%20Parser%20使用指南)。



在说话人栏输入 `[file://<url>]` 即可载入文件，`<url>`是本地文件地址，其余是固定格式，如 `[file://D:\demo.lua]` 、 `[file://E:/demo.lua]` 。

即使没有文件地址也是能够正常调用卡拉OK执行器 `kara-templater` 的，所以也可以直接当做应用卡拉OK模板的脚本使用。

> 每次调用 `Apply Karaoke Template File Parser` 都会重新解析一遍文件，应用后的显示的模板文本只是用于展示/发布给他人的。
>
> 应用之后如果需要修改请不要在Aeg中直接修改代码，请回到文件中进行修改；或者在Aeg中修改后使用原版`Apply Karaoke Template`应用卡拉OK执行器。



#### 特殊的文件路径

- `@/demo1.lua`
- `@include/demo2.lua`
- `@src/demo3.lua`

可以使用一个特殊符号 `@` 省略以下路径：`<Aeg安装根目录>`；

可以使用特殊符号加目录`@src`省略以下路径：`<Aeg安装根目录>/automation/src`，`@<path>`会查找`/automation/<path>`路径下的文件

`@src/demo3.lua` 等价于 `@/automation/src/demo3.lua`



比如：

- Aeg安装路径是`D:\SoftWare\Aegisub3.2.2\`；
- 需要读取的文件是 `demo.lua`；
- demo.lua文件存放在`D:\SoftWare\Aegisub3.2.2\automation\src\demo.lua`；

正常读取需要声明：`[file://D:\SoftWare\Aegisub3.2.2\automation\src\demo.lua]`

可以通过特殊文件路径声明：`[file://@src\demo.lua]`

> 默认Aeg的automation下没有src目录，需要手动创建



#### 对于不同的声明行的解析

1. 对于`code`行

> 按照正常lua代码编写code代码即可，因为本质上code行就是解析lua语句



2. 对于`template`行

> 每一行调用一个语句：
>
> - 使用特效标签时需要包裹在一对大括号中，每一个特效标签需要使用一对半角引号引起来 `"fsc100"` ；
> - 使用函数，如`maxloop(100)`直接调用即可；
> - 在特效标签中使用函数，如`\fsvp!math.random(100)!`仍然需要使用叹号声明；
> - 使用文本，如绘图代码`"m 0 0 l 0 100 l 100 100"`，需要使用一对半角引号引起来。
>
> ```lua
> -- 左边这两横杠表示右边的所有语句都是注释声明，当打开注释解析时会将注释声明使用特效区括起来表示内联注释
> retime("line", -200, 200)
> 
> {
>     -- 在特效区内注释声明是不会被解析成内联注释的，只能在当前文件中进行注释
>     -- 在特效区中通过英文引号声明一个特效标签
> 	"fsc100",
> 
>     -- 逗号本质上可以省略
>     "pos(100, 200)"
> 
>     -- 反斜杠可加可不加
>     "\p1",
> 
>     -- 在特效标签中使用函数需要${}括起来
>     "fsvp${math.random(300)}"
> }
> 
> -- 需要使用一对半角引号表示文本
> "m 0 0 l 0 100 l 100 100"
> ```

##### 关闭注释解析后的模板文本（默认关闭）

```lua
!retime("line", -200, 200)!{\fsc100\pos(100, 200)\p1\fsvp!math.random(300)!}m 0 0 l 0 100 l 100 100
```

##### 开启注释解析后的模板文本

```lua
{Comment: 左边这两横杠表示右边的所有语句都是注释声明，当打开注释解析时会将注释声明使用特效区括起来表示内联注释}!retime("line", -200, 200)!{\fsc100\pos(100, 200)\p1\fsvp!math.random(300)!}{Comment: 需要使用一对半角引号表示文本}m 0 0 l 0 100 l 100 100
```



#### 添加注释解析

打开`kara-templater_file-parser.lua`文件，可以代码前面看到一个标注**用户配置**的地方，修改里面的 `display_comment` 可以添加注释解析。

默认 `display_comment = false` 是不开启注释解析，修改为 `display_comment = true` 可以显示注释解析。



## 更新日志

> ```
> v1.2.2
> 修复了长注释在模板行会被解析为函数的Bug
> ```

> ```
> v1.2.0 & v1.2.1
> 1. 支持单文件多组件的解析，通过`#`分割语句
> 2. 添加了特效区解析可以使用表命名格式的功能（当前版本只是作为IDE不报错的方案，没有实际用途）
> ```

> ```
> v1.1.1
> 修复卡拉OK执行器重复注册的问题
> ```

> ```
> v1.1.0
> 支持template行的变量记忆和调用（自动remember和recall）
> ```





