local tr = aegisub.gettext
local script_name = tr "Apply Karaoke Template File Parser"
local script_description = tr "通过文件热重载加载的卡拉OK执行器"
local script_author = "Yiero"
local script_version = "1.3.9"


-- 用户配置
local user_config = {
    -- 是否显示注释到字幕编辑栏中：`true`为显示 | `false`为不显示
    display_comment = false,
}

------------------------------------------------------------------------

--[[
更新日志:
1.3.9
    添加功能：`require`关键字现在可以通过`#module`直接调用本文件的模块
    添加功能：`require`关键字现在可以通过第二个参数，声明code的类型`once | line | syl`
1.3.8
    添加功能：支持更复杂的特效区变量解析。
    如 `${t2 = t1 + 50}` 能够被解析为 `!remember("t2", recall.t1 + 50)!` 了。
    在之前的版本会被直接解析为 `!remember("t2", t1 + 50)!` 从而导致模板编译失败。
1.3.7
    添加功能：在template行的解析中添加了一个`require`关键字，和文件路径的解析一样，可以在文件中引入code模块。
    默认无路径只有文件名的解析路径是`./automation/src/template/code`

    由于操作了字幕行（添加和删除require依赖），为了优化性能，所以fx行的删除会在本插件中进行。
    如果您没有对原生`kara-templater`进行修改，那么本插件对于fx行的删除同时也会优化原生`kara-templater`的性能。
1.2.7
    修复了当特效标签中存在反斜杠时（比如 `t(0,1000,\fsc150)` ），不会自动添加反斜杠的问题。现在能够正确识别了。
1.2.5 & 1.2.6
    添加了一个特殊文件路径`@template`，表示`./automation/src/template`
1.2.4
    修复了内联函数变量无法使用代码区的问题：即`${num+100}`现在可以正常解析为`!recall.num+100!`了
1.2.3
    修改了一些注释描述，调整了用户配置的位置
1.2.2
    修复了长注释在模板行会被解析为函数的Bug
1.2.0 & 1.2.1
    支持单文件多组件的解析，通过`#`分割语句
    添加了特效区解析可以使用表命名格式的功能（当前版本只是作为IDE不报错的方案，没有实际用途）
1.1.1
    修复卡拉OK执行器重复注册的问题
1.1.0
    支持template行的变量记忆和调用
    （自动remember和recall）
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
    local printf = function(...)
        local str = ''
        for i, value in pairs({ ... }) do
            str = str .. tostring(value) .. "\t"
        end
        aegisub.debug.out(str .. "\n")
    end

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
        local file_info = {}

        -- 获取文件路径
        file_info.path = str:match('^%[file://(.*)%]$')
        -- 清除文件后缀
        file_info.path = file_info.path:gsub("%.[%w_]-$", "")

        -- 特殊路径重定向
        -- 将 `@` 重定向至 `./automation/`
        -- 将 `@src`|`@includes` 重定向至 `./automation/src` | `./automation/includes` 等路径
        -- 将 `@template` 重定向至 `./automation/src/template`
        if file_info.path:match("^@") then
            -- 获取特殊路径
            local sp_path = file_info.path:match("^@(.-)[/\\]")
            -- 特殊路径 `@template` 特殊处理
            if (sp_path == "template") then sp_path = "src\\template\\" end
            -- 写入相对文件路径
            local automation_path = "\\automation\\" .. sp_path .. "\\"
            -- 写入绝对文件路径
            file_info.path = file_info.path:gsub("^@.-[/\\]", aegisub.decode_path("?user") .. automation_path)
        end

        -- 文件内模块重定向
        if file_info.path:match("#[^\\/]-$") then
            file_info.path, file_info.module = file_info.path:match("^(.-)(#.*)$")
        end

        -- 补全后缀名
        file_info.path = file_info.path .. ".lua"
        -- 获取文件名
        file_info.name = file_info.path:match("[\\/](.-)$")

        return file_info
    end

    --- 读取文件
    --- @param file_info table 包含文件信息的表
    --- @param file_info.path string 文件路径
    --- @param file_info.module string 文件模块(如果存在)
    --- @param file_info.name string 文件名
    --- @return table lines|包含文件中所有行的数据
    local function read_file(file_info)
        --printf(file_info.path)
        local file = io.open(file_info.path)
        if (not file) then
            printf("寻找不到文件，请查询是否出现路径错误\n" .. "error: file (" .. file_info.path .. ") not found")
            aegisub.cancel()
        end

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

        --- 解析 code 行
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

        --- 解析 code(require) 行
        local function parse_require(line, file_path)
            -- 处理文件路径
            line = line:gsub("require%((['\"].*['\"])%)", "%1")
            local params_counter = 1
            local file_info_relative_string
            local code_param = "once"
            for value in line:gmatch("['\"](.-)[\"']") do
                if params_counter == 1 then
                    file_info_relative_string = value
                elseif params_counter == 2 then
                    code_param = value
                end
                params_counter = params_counter + 1
            end
            if ((not file_info_relative_string:match("[\\/]") and (file_info_relative_string:match("#")))) then
                file_info_relative_string = string.format("%s%s", file_path, file_info_relative_string)
            elseif (not file_info_relative_string:match("[\\/]")) then
                file_info_relative_string = string.format("@template/code/%s", file_info_relative_string)
            end
            local file_info_string = string.format("[file://%s]", file_info_relative_string)

            -- 获取文件绝对路径
            local file_info = get_file_path(file_info_string)

            -- 获取文件数据
            local data = {}
            data.effect = "code"
            data.display_comment = user_config.display_comment
            data.lines = read_file(file_info)

            -- 解析code行
            local code_line = parse_line(data)

            -- 添加code未定义行
            local insert_require_line = {
                ["section"] = "[Events]",
                ["class"] = "dialogue",
                ["start_time"] = 0,
                ["end_time"] = 0,
                ["text"] = code_line,
                ["comment"] = true,
                ["actor"] = string.format("[require://%s]", file_info_relative_string),
                ["effect"] = "code " .. code_param,
                ["style"] = "Default",
                ["layer"] = 0,
                ["margin_t"] = 0,
                ["margin_r"] = 0,
                ["margin_l"] = 0,
                ["margin_b"] = 0,
                ["raw"] = string.format("Comment: 0,0:00:00.00,0:00:00.00,Default,[require://%s],0,0,0,code %s,%s", file_info_relative_string, code_param, code_line),
                ["extra"] = {}
            }
            table.insert(insert_require_line_list, insert_require_line)
        end

        --- 解析 template 行
        local function parse_template(data)
            local display_comment = data.display_comment
            local lines = data.lines

            local function get_recall(string)
                for var in string:gmatch("[%w_]+") do
                    --printf(var, string)
                    if mem_remember[var] then
                        -- 写入remember
                        string = string:gsub(var, string.format("recall.%s", var))
                    end
                end
                return string
            end

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
                    if not effect_tag:match("^\\") then
                        effect_tag = "\\" .. effect_tag
                    end

                    -- 解析内联函数
                    if (effect_tag:match("%${(.-)}")) then
                        effect_tag = effect_tag:gsub("%${(.-)}", function(e)
                            -- 内联函数变量解析，自动转化remember
                            if e:match("=") then
                                local key, value = e:gsub(" ", ""):match("^(.-)=(.*)$")
                                mem_remember[key] = true        -- 写入remember缓存
                                value = get_recall(value)       -- 写入recall缓存
                                e = string.format("remember(\"%s\", %s)", key, value)   -- 写入remember
                                return "!" .. e .. "!"
                            end

                            -- 识别缓存remember，自动转化recall
                            e = get_recall(e)
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
                elseif line:match('require') then
                    --- 需求依赖解析
                    parse_require(line, data.file_path)
                else
                    --- 函数处理
                    local functionList = { "ass_color", "aegisub", "util", }
                    for i = 1, #functionList do
                        local function_string = functionList[i]
                        if (line:match("^" .. function_string)) then
                            line = "_G." .. line
                        end
                    end
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

    local function parse_require(dialogue_start_index, insert_require_line_list, remove_line_list)
        -- 删除require字幕行
        if (next(remove_line_list)) then
            subs.delete(remove_line_list)
        end

        -- 插入require代码行
        if (next(insert_require_line_list)) then
            for i = 1, #insert_require_line_list do
                local insert_line = insert_require_line_list[i]
                subs.insert(dialogue_start_index, insert_line)
            end
        end
    end
    --- 开始遍历字幕行
    local dialogue_start_index = get_dialogue_start_index()   -- 开始对话行索引 | 赋予全局变量因为需要缓存需要插入的require行索引
    local remove_line_list = {}         -- 需要删除字幕行索引表
    mem_remember = {}                   -- 变量缓存 | `mem_remember`缓存的变量通过`recall`调用
    insert_require_line_list = {}       -- 需要添加require字幕行信息表
    for i = dialogue_start_index, #subs do
        local line = subs[i]

        -- 读取文件
        local data = {}
        if ( (line.actor:match('^%[require://.-%]$')) or (line.effect == "fx") ) then
            table.insert(remove_line_list, i)
        elseif line.actor:match('^%[file://.-%]$') then
            local file = get_file_path(line.actor)
            data.file_path = line.actor:match('^%[file://(.-)%]$'):gsub("#[%w_]*", "")
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

    -- 处理require字幕行 | 删除旧require，添加新require
    parse_require(dialogue_start_index, insert_require_line_list, remove_line_list)

    --- 应用卡拉OK执行器
    macro_apply_templates(subs, selected_lines)
end

register_macro(script_name, script_description, re_macro_apply_templates, macro_can_template)




