-- Bundled by luabundle {"version":"1.7.0"}
local __bundle_require, __bundle_loaded, __bundle_register, __bundle_modules = (function(superRequire)
	local loadingPlaceholder = {[{}] = true}

	local register
	local modules = {}

	local require
	local loaded = {}

	register = function(name, body)
		if not modules[name] then
			modules[name] = body
		end
	end

	require = function(name)
		local loadedModule = loaded[name]

		if loadedModule then
			if loadedModule == loadingPlaceholder then
				return nil
			end
		else
			if not modules[name] then
				if not superRequire then
					local identifier = type(name) == 'string' and '\"' .. name .. '\"' or tostring(name)
					error('Tried to require ' .. identifier .. ', but no such module has been registered')
				else
					return superRequire(name)
				end
			end

			loaded[name] = loadingPlaceholder
			loadedModule = modules[name](require, loaded, register, modules)
			loaded[name] = loadedModule
		end

		return loadedModule
	end

	return require, loaded, register, modules
end)(require)
__bundle_register("__root", function(require, _LOADED, __bundle_register, __bundle_modules)
local tr = aegisub.gettext
local script_name = tr("Append Style to Text")
local script_description = tr("append style name to text and leading the style text will not use the space of the origin text.")
local script_author = "Yiero"
local script_version = "1.3.0"

require("karaskel")
local GUI = require("GUI_generate")

-- 删除附加字幕行，还原字幕
local function delete_append(subs)
	local delete_lines = {}
	for i = 1, #subs, 1 do
		local line = subs[i]
		--  删除附加字幕行
		if (line.class == "dialogue" and line.effect == "fx") and line.actor == "Text" or line.actor == "Style" or line.actor == "Comment" then
			table.insert(delete_lines, i)
			-- 还原字幕
		elseif (line.class == "dialogue" and line.effect == 'karaoke') then
			line.effect = ''
			line.comment = false
			subs[i] = line
		end
	end
	subs.delete(delete_lines)
end

--- 获取对话行字幕行数据, 并添加行号
--- @return number 字幕对话行的开始索引
local function get_dialogue_start_index(subs)
	for i = 1, #subs, 1 do
		if subs[i].class == "dialogue" then
			return i
		end
	end
end

-- GUI显示函数库
local display = {
	inset_styles = function(GUI, styles, begin_x, begin_y, is_true)
		begin_y = begin_y or 0
		for style_i = 1, styles.n do
			local style = styles[style_i]
			local ly = begin_y + (style_i - 1)
			
			table.insert(GUI, { x = begin_x, y = ly, class = "label", label = style.name })
			table.insert(GUI, { x = begin_x + 1, y = ly, class = "label", })
			table.insert(GUI, { x = begin_x + 2, y = ly, class = "checkbox", value = is_true, name = style.name })
			table.insert(GUI, { x = begin_x + 3, y = ly, class = "label", label = "|" })
			table.insert(GUI, { x = begin_x + 4, y = ly, class = "checkbox", hint = "选择后会忽略选择样式", name = ('ignore_' .. style.name) })
		end
	end
}

-- 样式文本GUI
display.GUI_prev_style_string = function(subs)
	local GUI_prev_style_string = [[
| 添加样式修饰文本：                                                               |                                                                                |
| -------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| [is_space_split]c<1>{在样式文本和原始文本中间添加一个硬空格 `\\h`}:添加空格分隔 | [is_zoom]c<1>{选择后将默认添加 `{\\fscx50\\fscy50}`缩小字体}:添加文本缩小50% |
| 样式左侧修饰文本：                                                               | [prev_string]e{在样式文本的左侧添加修饰}:[                                     |
| 样式右侧修饰文本：                                                               | [post_string]e{在样式文本的右侧添加修饰}:]                                     |
	]]
	
	local prev_style_string
	local btn, return_list = GUI.display(GUI.generate(GUI_prev_style_string), { "OK", "Delete Append", "Cancel" })
	if btn == "Delete Append" then
		delete_append(subs)
		return false
	end
	
	local is_space_split = ""
	if return_list.is_space_split then
		is_space_split = "\\h"
	end
	
	prev_style_string = string.format("%s%%s%s%s", return_list.prev_string, return_list.post_string, is_space_split)
	return prev_style_string, return_list
end

-- 样式选择GUI
display.GUI_style_chosen = function(styles)
	local GUI_style_chosen = [[
| [select_all]c<1>{取消后仅应用于选择行}:应用到所有行 | | | | |
| 样式名                    |    |   选择样式       |         | 忽略样式 |
	]]
	
	local GUI_style_chosen = GUI.generate(GUI_style_chosen)
	display.inset_styles(GUI_style_chosen, styles, 0, 2, true)
	local btn, return_list = GUI.display(GUI_style_chosen, { "OK", "Cancel" })
	
	return return_list
end

--- 按分隔符, 将字符串转为数组
--- @param str string 模板字符串
--- @param delimiter string 默认空字符串
--- @return string, string 字符串宽度, 字符串高度
local function split(str, delimiter)
	delimiter = delimiter or ''
	
	-- 处理空分隔符的情况（返回每个字符）
	if delimiter == "" then
		local result = {}
		for i = 1, #str do
			table.insert(result, str:sub(i, i))
		end
		return result
	end
	
	local result = {}
	local from = 1
	
	-- 循环查找分隔符的位置并分割字符串
	while true do
		local i, j = str:find(delimiter, from)
		if not i then
			-- 没有找到分隔符，将剩余部分加入结果
			table.insert(result, str:sub(from))
			break
		end
		-- 将分隔符前的部分加入结果
		table.insert(result, str:sub(from, i - 1))
		-- 更新起始位置到分隔符后的下一个字符
		from = j + 1
	end
	
	return result
end

--- 计算行尺寸 / 宽高
--- @param line table 行信息表
--- @param meta table 通过 meta = karaskel.collect_head(subs) 解析出来的 meta 元信息
--- @param styles table 通过 _, styles = karaskel.collect_head(subs) 解析出来的样式表总信息
--- @return number, number, table 当前行最大宽度, 当前行总高度, 当前行解析出来的所有宽高信息表
local function computedSize(line, meta, styles)
	karaskel.preproc_line_size(meta, styles, line)
	
	-- 去除特效标签
	local textStripped = line.text:gsub('{.-}', '')
	-- 获取分行后的字符数组
	local textList = split(textStripped, '\\N')
	
	local lineHeight = 0
	local lineWidth = 0
	
	local lineInfos = {};
	for _, text in ipairs(textList) do
		local width, height = aegisub.text_extents(line.styleref, text)
		-- 计算总高度
		lineHeight = height + lineHeight
		-- 计算最大宽度
		lineWidth = math.max(width, lineWidth)
		-- 储存当前宽度/高度
		table.insert(lineInfos, {
			width = width,
			height = height
		})
	end
	
	return lineWidth, lineHeight, lineInfos
end

--- 处理附加行的基本数据
local function parseAppendLineBaseInfo(line)
	line.actor = ''
	line.effect = 'fx'
	line.comment = false
	line.text = line.text:gsub('{.-}', '')
	
	return line;
end

--- 处理行
local function parseLine(parma)
	local li = parma.li
	local appendLineList = parma.appendLineList
	local subs = parma.subs
	local meta = parma.meta
	local styles = parma.styles
	local prev_style_string = parma.prev_style_string
	local res_prev_style = parma.res_prev_style
	local res_style_chosen = parma.res_style_chosen
	local zoom_string = parma.zoom_string
	local start_index = parma.start_index
	local totalDialogueLineLength = parma.totalDialogueLineLength
	
	local line = subs[li]
	karaskel.preproc_line_pos(meta, styles, line)
	karaskel.preproc_line_size(meta, styles, line)
	
	if res_style_chosen['ignore_' .. line.style] then
		return ;
	end
	
	-- 当前行添加注释, 特效栏
	line.effect = 'karaoke'
	line.comment = true
	if line.actor == 'Warn' then
		line.actor = ''
	end
	subs[li] = line
	
	local align = line.styleref.align
	
	-- 计算文本附加行
	local textLine = table.copy_deep(line)
	table.insert(appendLineList, textLine)
	-- 修改基本行信息
	parseAppendLineBaseInfo(textLine)
	textLine.actor = 'Text'     -- 标记文本行
	
	-- 判断当前的样式对齐方式
	local isTop = align >= 7 and align <= 9
	local isMiddle = align >= 4 and align <= 6
	local isBottom = align >= 1 and align <= 3
	local isLeft = align == 1 or align == 4 or align == 7
	local isCenter = align == 2 or align == 5 or align == 8
	local isRight = align == 3 or align == 6 or align == 9
	
	-- 计算当前文本行的坐标
	local textLineX = textLine.x
	local textLineY = textLine.y
	-- 左对齐, 文本行需要向右偏移, 留出给样式行的空间
	local styleText = prev_style_string:format(line.style);     -- 样式行的文本
	local styleTextWidth = aegisub.text_extents(line.styleref, styleText)   -- 样式行的文本宽度
	if res_prev_style.is_zoom then
		styleTextWidth = styleTextWidth * 0.5
	end
	if isLeft then
		textLineX = textLineX + styleTextWidth
	end
	
	-- 输出文本行文本
	textLine.text = string.format(
			'{\\an%d\\pos(%d, %d)}%s',
			align,
			textLineX, textLineY,
			textLine.text
	)
	
	-- 计算样式附加行
	local styleLine = table.copy_deep(line)
	table.insert(appendLineList, styleLine)
	-- 修改基本行信息
	parseAppendLineBaseInfo(styleLine)
	styleLine.actor = 'Style'   -- 标记注释行
	
	-- 计算正确的宽高, 对应到 styleLine 的坐标上
	local styleLineX = styleLine.x
	local styleLineY = styleLine.y
	local lineWidth, lineHeight = computedSize(textLine, meta, styles)
	
	-- 计算当前的高度对齐方式
	if isTop then
		styleLineY = styleLineY + lineHeight / 2
	elseif isBottom then
		styleLineY = styleLineY - lineHeight / 2
	end
	-- 计算当前的宽度对齐方式
	
	local styleAlign = 5;   -- 样式行对齐方式
	-- 1个空格的宽度, 用于中间对齐补足
	local spaceWidth = 0
	if res_prev_style.is_space_split then
		spaceWidth = aegisub.text_extents(line.styleref, ' ')   -- 空格的文本宽度
	end
	if isLeft then
		styleAlign = 4
	elseif isRight then
		styleLineX = styleLineX - lineWidth
		styleAlign = 6
	elseif isCenter then
		styleLineX = styleLineX - lineWidth * 0.5 - spaceWidth
		styleAlign = 6
	end
	
	-- 输出样式行文本
	styleLine.text = string.format(
			'{%s}{\\an%d, \\pos(%d, %d)}%s',
			zoom_string,
			styleAlign,
			styleLineX, styleLineY,
			styleText
	)
	
	-- 如果文本超出屏幕长度, 报错
	if (meta.res_x < styleTextWidth + lineWidth + spaceWidth) then
		aegisub.debug.out(string.format(
				'[Warning] 文本长度过长警告, 可能导致样式无法正确显示, 请使用硬换行或者分为多行字幕行\n行编号: %d\n行文本: %s\n------\n',
				li - start_index + 1,
				line.text
		))
		line.actor = 'Warn'
		subs[li] = line
	end
	
	-- 设置流程进度
	aegisub.progress.set((li / totalDialogueLineLength) * 100)
end

--- 主函数
local main = function(subs, selected_lines)
	-- 获取字幕元数据
	local meta, styles = karaskel.collect_head(subs)
	-- 删除附加行
	delete_append(subs)
	
	-- 无视频输入流警告
	if (meta.res_x == 384 and meta.res_y == 288) or (meta.res_x == 0 and meta.res_y == 0) then
		aegisub.progress.title("Warming")
		aegisub.debug.out(2, "由于没有视频流输入，字幕将显示在错误的位置。")
		aegisub.debug.out(2, "There isn't vidoe stream input, the subtitles will display incorrect positons.\n")
	end
	
	-- GUI显示1 - 样式文本GUI
	local prev_style_string, res_prev_style = display.GUI_prev_style_string(subs)
	if not (prev_style_string) then
		return
	end
	local zoom_string = ""
	if res_prev_style.is_zoom then
		zoom_string = "\\fscx50\\fscy50"
	end
	
	-- GUI显示2 - 样式选择GUI
	local res_style_chosen = display.GUI_style_chosen(styles)
	
	-- 进度条显示
	aegisub.progress.title("Appending the style")
	
	-- 获取对话行开始结束索引
	local start_index = get_dialogue_start_index(subs)
	local end_index = #subs
	-- 迭代当前所有对话行, 每一行新增样式行和文本行, 并添加到表 appendLineList 中
	local appendLineList = {};
	local totalDialogueLineLength = end_index - start_index
	
	if res_style_chosen.select_all then
		for li = start_index, end_index do
			parseLine({
				li = li,
				appendLineList = appendLineList,
				subs = subs,
				meta = meta,
				styles = styles,
				prev_style_string = prev_style_string,
				res_prev_style = res_prev_style,
				res_style_chosen = res_style_chosen,
				zoom_string = zoom_string,
				start_index = start_index,
				totalDialogueLineLength = totalDialogueLineLength,
			})
		end
	else
		start_index = selected_lines[1]
		end_index = #selected_lines
		totalDialogueLineLength = end_index - start_index
		for _, li in ipairs(selected_lines) do
			parseLine({
				li = li,
				appendLineList = appendLineList,
				subs = subs,
				meta = meta,
				styles = styles,
				prev_style_string = prev_style_string,
				res_prev_style = res_prev_style,
				res_style_chosen = res_style_chosen,
				zoom_string = zoom_string,
				start_index = start_index,
				totalDialogueLineLength = totalDialogueLineLength,
			})
		end
	end
	
	
	-- 将新增的附加行添加到字幕中
	subs.append(table.unpack(appendLineList))
	
	-- 完成流程
	aegisub.progress.set(100)
end

aegisub.register_macro(script_name, script_description, main)

end)
__bundle_register("GUI_generate", function(require, _LOADED, __bundle_register, __bundle_modules)
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
end)
return __bundle_require("__root")