# 暴露出命令行接口

## `_G.img_parser.exec`

> 本函数等同于 [`os.execute`](https://www.runoob.com/manual/lua53doc/manual.html#pdf-os.execute) / [`io.popen`](https://www.runoob.com/manual/lua53doc/manual.html#pdf-io.popen) 使用前请确保对**命令行指令调用**有一定的理解. 

`_G.img_parser.exec` 函数接受一个**字符串**参数, 返回一个**字符串**返回值: 

```lua
_G.img_parser.exec(command): result
```



**说明**

> 调用本函数等同于执行以下命令: 

```lua
result = io.popen(command):read('a')
```



**参数**

- `command`: 命令行指令

**返回值**

- `result`: 字符串, 输入命令行指令后的返回值. 

