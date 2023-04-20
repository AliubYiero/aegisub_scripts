local tr = aegisub.gettext
local script_name = tr "Apply Karaoke Template File Parser"
local script_description = tr "通过文件热重载加载的卡拉OK执行器"
local script_author = "Yiero"
local script_version = "1.2.3"


-- 用户配置
local user_config = {
    -- 是否显示注释到字幕编辑栏中：`true`为显示 | `false`为不显示
    display_comment = false,
}

------------------------------------------------------------------------

--[[
更新日志
1.1.0
    支持template行的变量记忆和调用
    （自动remember和recall）
1.1.1
    修复卡拉OK执行器重复注册的问题
1.2.0 & 1.2.1
    支持单文件多组件的解析，通过`#`分割语句
    添加了特效区解析可以使用表命名格式的功能（当前版本只是作为IDE不报错的方案，没有实际用途）
1.2.2
    修复了长注释在模板行会被解析为函数的Bug
--]]

--[[
更新计划：

...
    1. （实现）跨行template的解析（暂时没有好思路）
    2. （实现）单文件多组件的解析（有点思路）
        （通过template#1等标识语句分割）
    3. 模块化构造模板（配置中心、多组件结构链接...）
    4. 支持Lua语句解析的template（无思路）
--]]

-- 修改注册函数`aegisub.register_macro`指向，防止卡拉OK执行器的重复注册
local register_macro = aegisub.register_macro
local register_filter = aegisub.register_filter
aegisub.register_macro = function()

end
-- 引入卡拉OK执行器
require('./kara-templater')


local function re_macro_apply_templates(subs, selected_lines)
    --- 重定向输出语句
    printf = aegisub.debug.out

    --- 获取字幕对话行开始行编号
    --- @return number dialogue_start_index|字幕对话行开始行编号
    local function get_dialogue_start_index()
        for i = 1, #subs do
            local line = subs[i]
            if line.class == "dialogue" then
                return i
            end
        end
    end

    --- 获取文件路径
    --- @param str string 包含文件路径的字符串
    --- @return table 包含文件路径`.path`、文件模块`.module`、文件名`.name`的表
    local function get_file_path(str)
        local file = {}

        -- 获取文件路径
        file.path = str:match('^%[file://(.*)%]$')
        -- 清除文件后缀
        file.path = file.path:gsub("%.%w-$", "")

        -- 特殊路径重定向 | 将@重定向至 `./automation/src`
        if file.path:match("^@") then
            local automation_path = "\\automation\\" .. file.path:match("^@(.-[/\\])")
            file.path = file.path:gsub("^@.-[/\\]", aegisub.decode_path("?user") .. automation_path)
        end

        -- 特殊模块重定向
        if file.path:match("#[^\\/]-$") then
            file.path, file.module = file.path:match("^(.-)(#.*)$")
        end

        -- 补全后缀名
        file.path = file.path .. ".lua"
        -- 获取文件名
        file.name = file.path:match("[\\/](.-)$")

        return file
    end

    --- 读取文件
    --- @param file table 包含文件信息的表
    --- @param file.path string 文件路径
    --- @param file.module string 文件模块(如果存在)
    --- @param file.name string 文件名
    --- @return table lines|包含文件中所有行的数据
    local function read_file(file_info)
        local file = io.open(file_info.path)

        -- 判断是否存在模块
        local insert_start = true
        if (file.module) then
            insert_start = false
        end

        local lines = {}
        for line in file:lines() do
            -- 忽略空白行
            if line == "" then
                goto continue
            end

            -- 剪切首尾空白
            line = line:match("^ -(.*) *$")

            -- 忽略模块声明行
            if line:match("^%-%- ?#") then
                line = line:match("^%-%- ?(#.*)$")
            end

            -- 检测模块使用
            if (line:match("^#") and file_info.module == line) then
                insert_start = true
                goto continue
            elseif (line:match("^#") and insert_start) then
                insert_start = false
                goto continue
            end

            -- 插入文件行表
            if insert_start then
                table.insert(lines, line)
            end


            :: continue ::
        end

        file:close()

        return lines
    end

    --- 解析文件，将其重写至Aeg中
    --- @param data table 包含`.effect`属性、`.display_comment`属性和`.lines`属性的表
    --- @param data.effect string 模板行声明类型(code|template)
    --- @param data.display_comment boolean 显示注释
    --- @param data.lines table 包含文件所有行的表
    --- @return string 解析处理完的代码文本
    local function parse_line(data)
        local effect = data.effect
        local display_comment = data.display_comment
        local lines = data.lines
        --- 数组过滤器
        --- @param table table 表(数组)对象
        --- @param fn function 过滤判断条件数组，条件为true时(可以是match的文本)返回新数组
        --- @return table 返回的新表
        function table.filter(table, fn)
            -- 初始化空表
            if not table then
                return table
            end

            local new_table = {}
            for i = 1, #table do
                local value = table[i]
                local is_insert = false
                if (not fn(value)) then     -- 无返回值默认值
                    value = false
                elseif tostring(fn(value)) == "true" then
                    is_insert = true
                elseif type(fn(value)) ~= "boolean" then
                    is_insert = true
                    value = fn(value)

                    if value == "" then
                        is_insert = false
                    end
                end

                if (is_insert) then
                    _G.table.insert(new_table, value)
                end
            end
            return new_table
        end

        --- 解析code行
        local function parse_code(data)
            local display_comment = data.display_comment
            local lines = data.lines

            -- 注释处理
            local long_comment_start = false
            if not display_comment then
                lines = table.filter(lines, function(line)
                    -- 长注释处理
                    if (line:match('%-%-%[=-%[')) then
                        long_comment_start = true
                        return false
                    elseif (long_comment_start and line:match('%]=-%]')) then
                        long_comment_start = false
                        return false
                    end

                    -- 短注释处理
                    if line:match('%-%-') then
                        return line:match('^(.-)%-%-.*')
                    end

                    -- 返回非注释文本
                    if (not long_comment_start) then
                        return true
                    end
                end)
            end

            return lines
        end

        --- 解析template行
        local function parse_template(data)
            local display_comment = data.display_comment
            local lines = data.lines

            local effect_area_start = false     -- 特效区开始标记
            local effect_area_end = true        -- 特效区结束标记
            local long_comment_start = false    -- 长注释开始标记
            lines = table.filter(lines, function(line)
                --- 特效区标记
                if (line:match("^{") or line:match("{$")) then
                    effect_area_start = true
                    effect_area_end = false
                    return "{"
                elseif (line:match("^}") or line:match("}$")) then
                    effect_area_start = false
                    effect_area_end = true
                    return "}"
                end

                --- 长注释标记
                if (line:match('%-%-%[=-%[')) then
                    long_comment_start = true
                    return false
                elseif (long_comment_start and line:match('%]=-%]')) then
                    long_comment_start = false
                    return false
                end

                ---  特效标签区，处理反斜杠标记和文本标记
                if effect_area_start and not effect_area_end then
                    local effect_tag = line:match("\"(.-)\"")

                    -- 没有获取到特效标签，返回
                    if not effect_tag then
                        return false
                    end

                    -- 没有获取到特效标签声明（反斜杠），添加反斜杠
                    if not effect_tag:match("\\") then
                        effect_tag = "\\" .. effect_tag
                    end

                    -- 解析内联函数
                    if (effect_tag:match("%${(.-)}")) then
                        effect_tag = effect_tag:gsub("%${(.-)}", function(e)
                            -- 内联函数变量解析，自动转化remember
                            if e:match("=") then
                                local key, value = e:gsub(" ", ""):match("^(.-)=(.*)$")
                                mem_remember[key] = true     -- 写入remember缓存
                                e = string.format("remember(\"%s\", %s)", key, value)   -- 写入remember
                            end

                            -- 识别缓存remember，自动转化recall
                            if mem_remember[e] then
                                e = string.format("recall.%s", e)   -- 写入remember
                            end

                            return "!" .. e .. "!"
                        end)
                    end

                    return effect_tag
                end

                --- 忽略长注释
                if (long_comment_start) then
                    return false
                end

                --- 处理文本和函数
                if line:match("^\".-\"$") then
                    --- 文本处理
                    return line:match("\"(.-)\"")

                elseif line:match('^%-%-') then
                    --- 短注释处理
                    if not display_comment then
                        return false
                    end
                    return "{Comment: " .. line:match('%-%-(.*)'):gsub("^ *", "") .. "}"
                else
                    --- 函数处理
                    return "!" .. line .. "!"
                end

            end)

            return lines
        end

        --- 判断模板声明
        local line_tbl  -- 处理完的代码行表
        local sep       -- 分割符
        if effect == "code" then
            line_tbl = parse_code(data)
            sep = " "
        elseif effect == "template" then
            line_tbl = parse_template(data)
            sep = ""
        end

        --- 返回处理完毕的文本，清除换行符
        return table.concat(line_tbl, sep):gsub("\t", ""):gsub("    ", "")
    end

    --- 开始遍历字幕行
    local dialogue_start_index = get_dialogue_start_index()
    mem_remember = {}
    for i = dialogue_start_index, #subs do
        local line = subs[i]

        -- 读取文件
        local data = {}
        if line.actor:match('^%[file://(.-)%]$') then
            local file = get_file_path(line.actor)
            data.lines = read_file(file)

            -- 读取声明类型
            if line.comment and line.effect:match("^code") then
                data.effect = "code"
            elseif line.comment and line.effect:match("^template") then
                data.effect = "template"
            end
        end

        if data.effect then
            -- 解析文件
            data.display_comment = user_config.display_comment
            line.text = parse_line(data)
            subs[i] = line
        end
    end

    --- 应用卡拉OK执行器
    macro_apply_templates(subs, selected_lines)
end

register_macro(script_name, script_description, re_macro_apply_templates, macro_can_template)




