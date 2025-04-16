# Append Style to Text

[`append_style_to_text`](https://github.com/AliubYiero/aegisub_scripts/blob/master/autoload/append_style_to_text) 插件是一个用于将样式文本使用特定修饰，附加在字幕行的插件，可用于多人轴区分说话人. 

## 下载

请下载 dist 目录下的 [append_style_to_text.lua](./dist/append_style_to_text.lua) 文件. 

> [Warn] 注意, 从 1.3.0 版本开始, 将不再区分 `append_style_to_text.lua` 和 `append_style_to_text_without_generate.lua` 两个文件.
> 默认请下载 `dist/append_style_to_text.lua` 文件. 该文件为原先的 `append_style_to_text_without_generate` 文件, 也就是不需要导入 `GUI_generate` 模块的文件.
>
> `src/append_style_to_text.lua` 文件请不要使用, 这是工程文件.

## 使用



## 更新日志

- 1.3.0 - feat:
  - 修复了使用硬换行时, 附加行位置计算错误的问题
  - 修改了样式选择的 GUI
  - 为过长文本添加了警告


- 1.2.5 | 「注释样式」模块添加了一个空选项，用于无任何注释的选择
