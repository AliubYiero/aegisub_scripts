local tr = aegisub.gettext
local script_name = tr "Apply Karaoke Template File Parser"
local script_description = tr "通过文件热重载加载的卡拉OK执行器"
local script_author = "Yiero"
local script_version = "1.0.0"

-- 引入卡拉OK执行器
require('./kara-templater')

-- 用户配置
local user_config = {
    -- 是否显示注释到字幕编辑栏中：`true`为显示 | `false`为不显示
    display_comment = not false,
}

function re_macro_apply_templates(subs, selected_lines)
    printf = aegisub.debug.out
    --- 获取字幕对话行开始行编号
    --- @return number dialogue_start_index|字幕对话行开始行编号
    function get_dialogue_start_index()
        for i = 1, #subs do
            local line = subs[i]
            if line.class == "dialogue" then
                return i
            end
        end
    end

    --- 读取文件
    --- @param file_path string 文件路径
    --- @return table lines|包含文件中所有行的数据
    function read_file(file_path)
        if file_path:match("^@") then
            file_path = file_path:gsub("^@", aegisub.decode_path("?user") .. "\\automation\\src")
        end
        local file = io.open(file_path)

        local lines = {}
        for line in file:lines() do
            if line ~= "" then
                table.insert(lines, line)
            end
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
    function parse_line(data)
        local effect = data.effect
        local display_comment = data.display_comment
        local lines = data.lines
        --- 数组过滤器
        --- @param table table 表(数组)对象
        --- @param fn function 过滤判断条件数组，条件为true时(可以是match的文本)返回新数组
        --- @return table 返回的新表
        function table.filter(table, fn)
            if not table then
                return table
            end

            local new_table = {}
            for i = 1, #table do
                local value = table[i]
                local is_insert = false
                if tostring(fn(value)) == "true" then
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
        function parse_code(data)
            local display_comment = data.display_comment
            local lines = data.lines

            -- 注释处理
            if not display_comment then
                lines = table.filter(lines, function(line)
                    if line:match('%-%-') then
                        return line:match('^(.-)%-%-.*')
                    end

                    return true
                end)
            end

            return lines
        end

        --- 解析template行
        function parse_template(data)
            local display_comment = data.display_comment
            local lines = data.lines

            local effect_area_start = false
            local effect_area_end = true
            lines = table.filter(lines, function(line)
                if line:match("{") then
                    effect_area_start = true
                    effect_area_end = false
                    return true
                elseif line:match("}") then
                    effect_area_start = false
                    effect_area_end = true
                    return true
                end

                --  特效标签区，处理反斜杠标记和文本标记
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

                    return effect_tag
                end

                -- 处理文本和函数
                if line:match("^\".-\"$") then     -- 文本处理
                    return line:match("\"(.-)\"")

                elseif line:match('^%-%-') then    -- 函数处理
                    if not display_comment then
                        return false
                    end
                    return "{Comment: " .. line:match('%-%-(.*)'):gsub("^ *", "") .. "}"

                else    -- 函数处理
                    return "!" .. line .. "!"
                end

            end)

            return lines
        end

        -- 判断模板声明
        local line_tbl  -- 处理完的代码行表
        local sep       -- 分割符
        if effect == "code" then
            line_tbl = parse_code(data)
            sep = " "
        elseif effect == "template" then
            line_tbl = parse_template(data)
            sep = ""
        end

        -- 返回处理完毕的文本，清除换行符
        return table.concat(line_tbl, sep):gsub("\t", ""):gsub("    ", "")
    end

    --- 开始遍历字幕行
    local dialogue_start_index = get_dialogue_start_index()
    for i = dialogue_start_index, #subs do
        local line = subs[i]

        -- 读取文件
        local data = {}
        if line.actor:match('^%[file://(.-)%]$') then
            local file_path = line.actor:match('^%[file://(.-)%]$')
            data.lines = read_file(file_path)

            -- 读取声明类型
            if line.effect:match("^code") then
                data.effect = "code"
            elseif line.effect:match("^template") then
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

aegisub.register_macro(script_name, script_description, re_macro_apply_templates, macro_can_template)



