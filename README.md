# aegisub_scripts

一些aegisub小插件

| list           | 功能                                                       | 下载                                      |
| -------------- | ---------------------------------------------------------- | ----------------------------------------- |
| actor_to_style | [文本导入辅助](#actor_to_style---多人轴说话人文本导入辅助) | [Download](./autoload/actor_to_style.lua) |
| effect_tags    | [后期相关插件集](#effect_tags---后期相关插件集)            | [Download](./autoload/effect_tags.lua)    |
| shape_rewrite  | [图形转写](#shape_rewrite---图形转写)                      | [Download](./autoload/shape_rewrite.lua)  |

> 如果不会下载/没有插件辅助, 请点击本页面右上角 `[Code]` - `[Download Zip]` 将所有文件拷贝下来之后再选择需要的插件安装.



## 普通轴相关

### actor_to_style - 多人轴说话人文本导入辅助

将txt文本标记的说话人导入到样式栏，而不是aeg原生txt文本导入的说话人栏。

兼容全角符号，以及非UTF-8编码txt文件报错

1. 快速导入txt文本（Add选项）
2. 将aeg原生导入txt文本的说话人，快速转写为样式（OK选项）

---


## 后期轴相关

### effect_tags - 后期相关插件集

以下功能的整合插件

- clips_printer - 动态遮罩过渡
- multi_bord - 多重边框

###### clips_printer - 动态遮罩过渡

快速输出一个包括整个字幕行的动态遮罩。可选择动态出现(`clip`)或动态消失(`iclip`)，包含6种展开方向

兼容行内标签(`an` `pos` `fsc` `fscx` `fscy` `org` `frz`)

###### multi_bord - 多重边框

快速输出具有多行边框的字幕行

---

### shape_rewrite - 图形转写

通过视频区快捷栏能快速进行clip的图形绘制, 将**绘制的图形转写成绘图代码**