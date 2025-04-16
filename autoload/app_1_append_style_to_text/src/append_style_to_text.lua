local tr = aegisub.gettext
local script_name = tr("Append Style to Text")
local script_description = tr("append style name to text and leading the style text will not use the space of the origin text.")
local script_author = "Yiero"
local script_version = "1.3.0"

require('karaskel')
local GUI = require('GUI_generate')

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
