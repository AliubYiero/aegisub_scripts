# GUI Generate

该函数库用于解放编写Aeg GUI繁琐的工作，本函数库使用md规范的表格文本形式编写静态Aeg GUI。

该函数库将解决您编辑Aeg GUI中的以下问题：

1. 书写过程中，需要不断地计算和输入`x`和`y`
2. 重复输入键
3. GUI配置表可读性差，修改起来很麻烦



## Markdown表格格式

### Markdown表格文本形式

Markdown的表格格式很简单，就是使用同等的竖线划分出 n x n 的表格：

```markdown
## 画一个3x3的表格
|      |      |      |
| ---- | ---- | ---- |
|      |      |      |
|      |      |      |
```



如果想手动写md表格文本的话，在`GUI Generate`中中间的横线是可以省略的，即可以简写为：

```markdown
## 画一个3x3的表格
|      |      |      |
|      |      |      |
|      |      |      |
```

不过还是推荐使用md编辑器去编写，比如`Typora`、`Vscode`或者其它的md编辑器。



### 单元格格式

Aeg的GUI中存在许多选项，比如纯文本`label`、单选框`checkbox`、编辑栏`edit`等等，`GUI Generate`也对这些格式进行了规定。

1. 使用`半角冒号`进行`选项`和`文本`的区分：
	`| checkbox:选中文本 |`，在一个单元格中，这样书写将会识别为`{class="checkbox", label="选中文本"}`
2. 在选项一侧（即半角冒号左边），使用不同符号进行标记会出现不同的识别：
	`| [is_name]checkbox<true>{comment}:label |`
	1. 半角中括号`[]`，将识别为命名：`name = "is_name"`
	2. 半角尖括号`<>`，将识别为默认值：`value = true`
		如`checkbox`的`true`和`false`；`dropdown`的`selected`
	3. 半角花括号`{}`，将识别为鼠标悬停提示：`hint = "comment"`
	4. 三种标记不区分位置
3. 关于默认值：
	1. 单选框`checkbox`的默认值可以表示为`1`和`0`：`1`等同于`true`，`0`等同于`false`
	2. 编辑栏`edit`和编辑框`textbox`比较特殊，可以使用`<>`在默认值`value `输入默认文本，也可以在文本`label `输入默认文本。`label`的优先级更高。
	3. 多选框`dropdown`的选项在文本一侧（半角冒号右边）使用多个半角逗号分隔开
	4. 文字也可以不写`| l:text |`直接使用`| text |`，但是如果`text`中存在半角冒号，就需要使用`l:text`
	5. 选项均存在简写，详细见下面的总表。
4. 总表：

| 选项               | 简写                                      | 展开                                             |
| ------------------ | ----------------------------------------- | ------------------------------------------------ |
| 文字               | l:text                                    | label:text                                       |
| 单选框             | [name]`c`<0>{comment}:text                | [name]`checkbox`<0>{comment}:text                |
| 编辑栏             | [name]`e`{comment}:default_text           | [name]`edit`{comment}:default_text               |
| 编辑框             | [name]`t`{comment}:default_text           | [name]`textbox`{comment}:default_text            |
| 多选框             | [name]`d`<seclected>{comment}:item1,item2 | [name]`dropdown`<seclected>{comment}:item1,item2 |
| 整数编辑框         | [name]`it`<0>{comment}:min, max           | [name]`intedit`<0>{comment}:min, max             |
| 浮点数编辑框       | [name]`ft`<0>{comment}:min, max, step     | [name]`floatedit`<0>{comment}:min, max, step     |
| 颜色选择框         |                                           | [name]`color`{comment}:default_color             |
| 透明值选择框       |                                           | [name]`coloralpha`{comment}:default_alpha        |
| 颜色和透明值选择框 |                                           | [name]`color`{comment}:default_coloralpha        |

5. 本函数库还提供了**有限的合并单元格操作**：
	- `留空`：向左合并
	- **向上合并操作符**`^`：将当前单元格向上合并，只支持`单合并`
	- **向左合并操作符**`<`：将当前单元格向左合并，与`留空`的区别是实现`2 x n`的多单元格合并必须使用向左合并操作符
	- **隔断操作符**`>`：终止`留空`的向左合并，将当前单元格设为空
6. 合并单元格操作示例：

| 1x4单元格 |      |           |      |      |
| --------- | ---- | --------- | ---- | ---- |
| 2x1单元格 | >    | 2x3单元格 | <    | <    |
| ^         | >    | ^         | ^    | ^    |






## 加载函数库

`local GUI = require 'GUI_generate'`



### `GUI.generate`

> `local GUI_configs = GUI.generate(GUI_string_or_path)`

该函数用于生成一个GUI配置表(`table`)，可提供进一步的修改(实现动态GUI配置)或者直接接入Aeg生成GUI（`GUI.display`）。



 **参数** ：

- `GUI_string_or_path`：该参数可以是 包含表格`.md`文件的路径 ，也可以是 md规范的表格字符串 。
	默认`.md`文件将在 [./automation/src] 目录下寻找（src目录需要自己创建）
	如果使用反斜杠输入路径，需要使用转义反斜杠`\\`，即需要输入`[D:\\Test\\test.md]`

```lua
-- `GUI_string_or_path`参数示例
-- 参数1: 使用md规范的表格字符串
local GUI_string = [[
| actor   | style |
| ------- | ----- |
| Default | Text  |
]]
local GUI_configs = GUI.generate(GUI_string)

-- 参数2: 使用md文件, md文件`GUI_test.md`包含上文`GUI_string`的表格
-- 参数2-1: 直接使用文件名, 这时候会寻找`[./automation/src/GUI_test.md]`文件
local GUI_configs = GUI.generate("GUI_test")

-- 参数2-2: 直接使用文件名(含后缀), 这时候也会寻找`[./automation/src/GUI_test.md]`文件
local GUI_configs = GUI.generate("GUI_test.md")

-- 参数2-3: 使用相对路径查找文件, 这时候也会寻找`[./automation/src/GUI_test.md]`文件
-- Aegisub的相对路径开始路径是`安装路径`，即`Aegisub.exe`所在的路径(但使用相对路径可能出问题)
local GUI_configs = GUI.generate("./automation/src/GUI_test.md")

-- 参数2-4: 使用绝对路径查找文件, 这时候会寻找`[D:/GUI_test.md]`文件
local GUI_configs = GUI.generate("D:/GUI_test.md")
```



### `GUI.display`

`local btn, return_tbl = GUI.display(GUI_configs, btns, is_config)`

该函数将在Aeg中生成一个Aeg GUI，比起直接使用`aegisub.dialog.display`，本函数中添加了一些额外的操作：

1. **默认按钮**：当参数`btns`不填的时候，会有默认按钮`OK`和`Cancel`表示 确认 和 取消 。
2. **默认关闭**：当点击按钮`Cancel`时，不需要再判断`btn`使用`aegisub.cancel`，`GUI.display`内置了关闭操作。 默认关闭操作 支持以下命名（英文 不区分大小写 ）：`取消`、`关闭`、`Cancel`、`Close`。
3. **配置输出**：当输入的`GUI_configs`是使用`GUI.generate`导入文件生成的配置表时，会在GUI中添加一个按钮`Config`，点击`Config`将输出GUI配置表的字符串。



**参数**：

- `GUI_configs`：GUI配置文件表，详细数据见[[Dialog Control table format]](https://aegi.vmoe.info/docs/3.2/Automation/Lua/Dialogs/#dialog-control-table-format)
- `btns`：[可选参数] GUI按钮，默认为`{"OK", "Cancel"}`，详细数据见[[Aegisub Dialog Display]](https://aegi.vmoe.info/docs/3.2/Automation/Lua/Dialogs/#aegisubdialogdisplay)
- `is_config`：[可选参数] 输入`false`可以关闭文件传入时默认的`Config`按钮



返回值：

- `btn`, `return_tbl`：详细数据见[[Aegisub Dialog Display]](https://aegi.vmoe.info/docs/3.2/Automation/Lua/Dialogs/#aegisubdialogdisplay)

### `GUI.blank_line`

`local line = GUI.blank_line`

该属性为一个空白时间/文本/说话人/特效栏，样式为Default的对话行，可用于附加行的自定义修改。



### `GUI.config_concat`

> 目前该函数已集成在`GUI.display`中，无需独立使用。

`local GUI_configs_string = GUI.config_concat(GUI_configs)`

该函数用于输出GUI配置表的字符串，可用于检查GUI配置表生成是否符合预期，或者用于将插件独立出`GUI_generate`。



## 测试文件

- `[./autoload/GUI_generate_test.lua]`
	`GUI_generate`测试插件，安装到`[./automation/autoload/]`目录下成功使用则表示成功使用。
	可以通过这个简单示例一窥`GUI_generate`的使用
- `[./src/GUI-generate_test-blank_video.md]`
	示例md文件，需要复制到`[./automation/src/]`目录下（若不存在`src`路径，则需要自己创建）



## 已知问题

1. 如果文本中需要使用反斜杠 `\`，请使用转义反斜杠 `\\`。该问题属于Lua特性问题。



2. 目前无法支持换行，包括`\n`和md的`<br />`，且使用后md的`<br />`会出现单元格丢失的情况
3. 目前只能合并2列的单元格，不支持3列及以上的单元格合并
4. 目前合并列单元格需要将第二行的单元格全部标记上`^`，否则可能错误标记



## 更新日志

> v1.3.2 | `GUI.display(GUI_configs, btns, is_config)`添加了一个参数`is_config`，用于关闭文件输入时默认添加的`Config`按钮

> v1.3.0 | 添加了隔断操作符`>`

> v1.2.2 | 提供了一个新属性`GUI.blank_line`，该属性是一个标准ASS空白行

> v1.2.0 | 通过`.md`文件导入的GUI，使用`GUI.display`将默认添加一个按钮`Config`，该按钮将输出当前生成的Aeg格式的GUI配置表（即调用`GUI.config_concat`）

> v1.1.0 | 优化了`GUI.config_concat`输出的GUI配置表字符串的格式

> v1.0.0 | 提供了3个GUI生成相关的接口`GUI.generate` `GUI.display` 和 `GUI.config_concat`



### 更新计划

1. 提供动态GUI的结构
2. 修复合并单元格的问题
