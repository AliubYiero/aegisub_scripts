# aegisub_scripts

### Yiero's Aegisub插件库

| autoload                              | 功能                                                         | 版本  |                     说明文档                      |
| ------------------------------------- | ------------------------------------------------------------ | :---: | :-----------------------------------------------: |
| actor_to_style                        | 使用txt导入多人轴，将说话人从说话人栏转移到样式栏            | 1.1.3 |    [[README]](./docx/actor_to_style/README.md)    |
| append_style_to_text                  | 需要使用 `GUI_generate`函数库<br />将样式添加上规定修饰添加到文本中，并不使原字幕文本发生偏移 | 1.2.5 | [[README]](./docx/append_style_to_text/README.md) |
| append_style_to_text_without_generate | **不需要**使用 `GUI_generate`函数库的 `append_style_with_leading`独立版本<br />但是可能不会和 `append_style_with_leading`同步更新，请查看版本号和更新日志 | 1.2.5 |                         ↑                         |
| kara-templater_file-parser            | kara-templater的入口，在调用原kara-templater执行器的基础上，添加了一个读取文件重载代码的功能 | 1.0.0 |                                                   |

### Yiero's Aegisub函数库

| include      | 功能                    | 版本  | 说明文档                               |
| ------------ | ----------------------- | ----- | -------------------------------------- |
| GUI_generate | 用于辅助GUI生成的函数库 | 1.3.5 | [[README]](./docx/GUI_generate/README.md) |

### 如何下载

> - 点击本页面右上角 `[Code]` - `[Download Zip]` 将所有文件拷贝下来之后再选择需要的插件安装.
> - 通过**油猴插件**独立下载单独文件

### 如何使用

- `autoload`：该文件夹存放**插件库**，该目录下的 `.lua`文件放置在Aeg安装目录下的 `[./automation/autoload]`下
- `include`：该文件夹存放**函数库**，该目录下的 `.lua`文件需放置在Aeg安装目录下的 `[./automation/include]`下
- `docx`：该文件夹存放插件/函数库的说明文档以及测试文件
