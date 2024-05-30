-- @author: Yiero
-- @version: 1.3.5
--[[
   @description:
 GUI_generate是一个用于Aegisub插件GUI创建的函数库，提供了3个辅助函数：
`GUI.generate`: 生成AegGUI配置表
`GUI.display` : 使用AegisubGUI显示接口
`GUI.config_concat`: 将GUI配置表输出为table形式的字符串，可用于将调整完成的GUI表格输出，使脚本独立出`GUI_generate`
 您可以在`autoload`目录下找到演示示例
--]]

-- @feature: 如果文本中需要使用反斜杠 `\`，请使用转义反斜杠 `\\`

-- @bug: 目前无法支持换行，即md的`<br />`，使用后会出现单元格丢失的情况
-- @bug: 目前只能合并2列的单元格，不支持3列及以上的单元格合并
-- @bug: 目前合并列单元格需要将第二行的单元格全部标记上`^`，否则可能错误标记

-- @attribute GUI.blank_line 一个标准ASS空白行
-- @function configs = GUI.generate(GUI_string_or_path)
-- @function btn, return_tbl = GUI.display(GUI_configs, btns, is_config)



-- 生成AegGUI配置
-- @param GUI_str:string 规定格式的长文本
-- @return GUI_configs:table AegGUI表
local GUI = {
	-- 定义一个空白行
	-- @return blank_line:table 一个标准ASS空白行
	blank_line = {
		["section"] = "[Events]",
		["class"] = "dialogue",
		["start_time"] = 0,
		["end_time"] = 0,
		["text"] = "",
		["comment"] = false,
		["actor"] = "",
		["effect"] = "",
		["style"] = "Default",
		["layer"] = 0,
		["margin_t"] = 0,
		["margin_r"] = 0,
		["margin_l"] = 0,
		["margin_b"] = 0,
		["raw"] = "Comment: 0,0:00:00.00,0:00:00.00,Default,,0,0,0,,",
		["extra"] = {}
	},

	-- 读取md文件中的表数据
	-- @param file_path:string	md文件路径
	-- @return file_str:string	读取的文件数据
	load_mdfile = function(file_path)
		local file = io.open(file_path)
		if not(file) then error("Error Input.\n" .. "Please input a correct file path: " .. file_path) end
		local file_str = file:read("a")
		file:close()

		return file_str
	end,

    -- 根据输入字符串获取单元格原始文本表数据
    -- @return cells:table	原始文本数据
    string_format = function(GUI_str)
        local cells = {}
        -- 获取行
        for line_str in GUI_str:gmatch("\t-(|.-|)\n") do
            local line = {}
            -- 清除Typora等md编辑器的标题行标记 or 清除空行
            if line_str:match("| :?%-*:? |") or (line_str:gsub("[ |]", "") == "") then
                goto continue
            end

            -- 重新标记单元格
            line_str = "「" .. line_str:match("^|(.*)|$") .. "」"
            line_str = line_str:gsub("([^\\])|", "%1」 「")
            -- print(line_str)

            -- 获取列
            local line = {}
            for row in line_str:gmatch("「 *(.-) *」") do
                -- 清除转义
                if row:match("\\\\") then
					row = row:gsub("\\\\", "\\")
				elseif row:match("\\") then
                    row = row:gsub("\\", "")
                end
                table.insert(line, row)
            end

            table.insert(cells, line)
            ::continue::
        end
        return cells
    end,

    -- 输出GUI配置表
    -- @param cells:table		原始文本单元格数据表
    -- @return configs:table	GUI配置信息表
    configs = function(cells)
        local configs = {}
        for y, line in ipairs(cells) do
            for x, cell_str in ipairs(line) do
                local cell = {}
                cell.y = y - 1
                cell.x = x - 1
				cell.width = 1
				cell.height = 1

                -- 处理`class`和文本`label`
                local class, label = cell_str:match("^([^:]*):?(.-)$")
				local origin_class = class
				class = class:gsub("%s", "")

                -- 处理`class`里的值：默认值`<value>`、`[name]`、`{hint}`
                local value = ""
                local name = ""
                local hint = ""
                -- 默认值`{hint}`
                if class:match("%b{}") then
                    class = class:gsub("(%b{})", function(hint_str)
						hint_str = hint_str:match("^{(.*)}$")
                        hint = hint_str
                        return ""
                    end)
                end
                -- 默认值`<value>`
                if class:match("%b<>") then
                    class = class:gsub("(%b<>)", function(value_str)
						value_str = value_str:match("^<(.*)>$")
                        value = value_str
                        return ""
                    end)
                end
                -- 默认值`[name]`
                if class:match("%b[]") then
                    class = class:gsub("(%b[])", function(name_str)
						name_str = name_str:match("^%[(.*)%]$")
                        name = name_str
                        return ""
                    end)
                end

                -- 处理checkbox文本
                if class == "c" or class == "checkbox" then
                    cell.class = "checkbox"
                    cell.label = label
                    cell.hint = hint
                    cell.name = name

                    if value == "1" or value == "true" then
                        cell.value = true
                    elseif value == "0" or value == "false" or value == "" then
                        cell.value = false
                    end

                    goto continue
                end

                -- 处理edit文本
                if class == "e" or class == "edit" then
                    cell.class = "edit"
                    cell.hint = hint
                    cell.name = name
                    cell.text = label
					if label == "" and value ~= "" then
						cell.text = value
					end
                    goto continue
                end

                -- 处理textbox文本
                if class == "t" or class == "text" or class == "textbox" then
                    cell.class = "textbox"
                    cell.hint = hint
                    cell.name = name
                    cell.text = label
					if label == "" and value ~= "" then
						cell.text = value
					end
                    goto continue
                end

                -- 处理intedit文本
                if class == "intedit" or class == "ie" or class == "it" then
                    cell.class = "intedit"
                    cell.hint = hint
                    cell.name = name
                    cell.value = tonumber(value)

                    local min, max = label:match("^([^,]-),?([^,]-)$")
                    if min == "" then
                        min = max
                        max = ""
                    end
                    cell.min = tonumber(min)
                    cell.max = tonumber(max)

                    goto continue
                end

                -- 处理floatedit文本
                if class == "floatedit" or class == "fe" or class == "ft" then
                    cell.class = "floatedit"
                    cell.hint = hint
                    cell.name = name
                    cell.value = tonumber(value)

                    local min, max, step = label:match("^([^,]-),?([^,]-),?([^,]-)$")
                    if max == "" then
                        min = step
                        step = ""
                    elseif min == "" then
                        min = max
                        max = step
                        step = ""
                    end
                    cell.min = tonumber(min)
                    cell.max = tonumber(max)
                    cell.step = tonumber(step)

                    goto continue
                end

                -- 处理dropdown文本
                if class == "d" or class == "dropdown" then
                    cell.class = "dropdown"
                    cell.hint = hint
                    cell.name = name
                    cell.value = value

                    local items = {}
                    for item in label:gmatch("([^, ]+),?") do
                        table.insert(items, item)
                    end
                    cell.items = items

                    goto continue
                end

                -- 处理color文本
                if class == "color" then
                    cell.class = "color"
                    cell.hint = hint
                    cell.name = name
					cell.value = label
					if label == "" and value ~= "" then
						cell.value = value
					end
                    goto continue
                end

                -- 处理coloralpha文本
                if class == "coloralpha" then
                    cell.class = "coloralpha"
                    cell.hint = hint
                    cell.name = name
					cell.value = label
					if label == "" and value ~= "" then
						cell.value = value
					end
                    goto continue
                end

                -- 处理alpha文本
                if class == "alpha" then
                    cell.class = "alpha"
                    cell.hint = hint
                    cell.name = name
					cell.value = label
					if label == "" and value ~= "" then
						cell.value = value
					end
                    goto continue
                end

				-- 隔断不合并标记
				if label == "" and class == ">" then
					cell = nil
					goto continue
				end

				-- 空白行/合并行合并到左行(x轴)
				if label == "" and class == "<" or class == "" then
					if configs[#configs].y ~= y - 1 then
						goto nowidth
					end
					configs[#configs].width = configs[#configs].width + 1
					::nowidth::
					cell = nil
					goto continue
				end

				-- 合并列合并到上行(y轴)
				if label == "" and class == "^" then
					local min_cell = math.max(1, #configs - (#line+1))
					for i = #configs, min_cell, -1 do
						if configs[i].x == x and configs[i].y == y - 2 then
							configs[i].height = configs[i].height + 1
							cell = nil
							goto continue
						end
					end
					if configs[#configs].x ~= x - 1 then
						cell = nil
						goto continue
					end
					error(string.format('Error Input in (%d, %d): `^` should not be here.', x, y))
				end

				-- 处理label文本
				if class == "l" or class == "label" then
					cell.label = label
					cell.class = "label"
					goto continue
				end

				cell.label = class .. label
				cell.class = "label"
				if label == "" then
					cell.label = origin_class
				end

                ::continue::
                table.insert(configs, cell)
            end

			-- -- 在每一行的最右插入一个空白单元格优化GUI观感
			-- local space_right_cell = {
			-- 	["y"] = y - 1,
			-- 	["x"] = #line + 1,
			-- 	["class"] = "label",
			-- 	["label"] = " "
			-- }
			-- table.insert(configs, space_right_cell)
        end

        return configs
    end,

    -- GUI配置表字符串输出
    -- @param configs:table		GUI配置信息表
    -- @param GUI_name:string	可选参数, 输出的GUI表名(默认为`config`))
    -- @return config_str:string	GUI配置表字符串输出
    config_concat = function(configs, GUI_name)
        GUI_name = GUI_name or "config"

        local config_str = [[
%s = {
	%s
}]]

		local list_strs = {}
        for i, config in ipairs(configs) do
			local str_list = "{%s}"

			local list_key_str = {}
            for k, v in pairs(config) do
                if type(v) == "string" then
                    v = string.format('"%s"', v)
                elseif type(v) == "table" then
                    v = '{"' .. table.concat(v, '", "') .. '"}'
                end
                table.insert(list_key_str, string.format("%s = %s", k, v))
            end

			table.insert(list_strs, str_list:format(table.concat(list_key_str, ", ")))
        end
        config_str = config_str:format(GUI_name, table.concat(list_strs, ", \n\t"))
        return config_str
    end
}

-- 生成GUI配置
-- @param GUI_string_or_path:string		可以是存放了表数据的md文件路径，也可以是表数据
-- @return configs:table				GUI配置信息表
GUI.generate = function(GUI_string_or_path)
	local GUI_str = GUI_string_or_path
	local is_file
	-- 形参是文件路径，读取文件
	if GUI_str:match(":\\") or GUI_str:match(":/")
	or GUI_str:match("%.\\") or GUI_str:match("%./") then
		GUI_str = GUI.load_mdfile(GUI_string_or_path)
		is_file = true
	-- 形参是文件，没有包含路径
	elseif GUI_str:match("%.%w+$") then
		-- 默认md文件在[./automation/src]目录下
		GUI_str = GUI.load_mdfile(aegisub.decode_path("?user") .. "\\automation\\src\\" .. GUI_string_or_path)
		is_file = true
	-- 形参是文件，没有文件后缀
	elseif not(GUI_str:match("|")) then
		-- 默认md文件在[./automation/src]目录下
		GUI_str = GUI.load_mdfile(aegisub.decode_path("?user") .. "\\automation\\src\\" .. GUI_string_or_path .. ".md")
		is_file = true
	end


	local cells = GUI.string_format(GUI_str)
	local configs = GUI.configs(cells)
	-- 添加文件输入标记
	if is_file then
		configs[1].is_generate = true
	end
	return configs
end

-- 使用AegisubGUI显示接口
-- @param GUI_configs:table		GUI配置信息表
-- @param btns:table			可选参数，按钮选项，默认`确定`和`取消`
-- @return btn:string			用户点击事件
-- @return return_tbl:table		用户返回数据
GUI.display = function(GUI_configs, btns, is_config)
	btns = btns or {"OK", "Cancel"}

	-- configs输出标记添加button
	if (is_config ~= false and GUI_configs[1].is_generate) or is_config == true then
		GUI_configs[1].is_generate = false
		btns[#btns + 1] = "Config"
	end

	local btn, return_tbl = aegisub.dialog.display(GUI_configs, btns)
	if not(btn) or btn:lower() == "cancel" or btn:lower() == "close" or btn == "取消" or btn == "关闭" then aegisub.cancel() end
	if btn == "Config" then
		local btn = aegisub.dialog.display({{x=1,y=0,width=60,height=20,class="textbox",name="config",text=GUI.config_concat(GUI_configs)}}, {"OK", "Back", "Cancel"})
		if btn == "Cancel" then aegisub.cancel() end
		if btn == "Back" then
			btn, return_tbl = aegisub.dialog.display(GUI_configs, btns)
			return btn, return_tbl
		end
		-- if btn == "OK" then
			-- 由于存在部分Aeg有clipboard无法使用的情况(AegisubDC, arch1t3cht's Aegisub)，所以无法自动复制剪切板
			-- local clipboard = require 'aegisub.clipboard'
			-- clipboard.set(return_tbl.config)
		-- end
	end
	return btn, return_tbl
end

-- GUI_generate测试函数
-- @return string
local GUI_generate_test = function(GUI_str)
    -- GUI_generate.main()

    -- 原始文本表数据测试
    local cells = GUI.string_format(GUI_str)
    for i = 1, #cells, 1 do
        io.write("line" .. i .. ": ")
        for j = 1, #cells[i], 1 do
            io.write("[row" .. j .. "]:(" .. cells[i][j] .. ")\t")
        end
        print ""
    end

    local configs = GUI.configs(cells)
    local configs_str = GUI.config_concat(configs)

    print(configs_str)
end

--[[
-- 测试单元
GUI_generate_test(GUI_str3)
 ]]

return GUI