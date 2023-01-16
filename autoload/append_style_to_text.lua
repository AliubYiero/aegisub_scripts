local tr = aegisub.gettext
local script_name = tr("Append Style to Text")
local script_description = tr("append style name to text and leading the style text will not use the space of the origin text.")
local script_author = "Yiero"
local script_version = "1.2.4"

require 'karaskel'
local GUI = require 'GUI_generate'

---[[ 重写`karaskel.preproc_line_pos`优化性能
function karaskel.preproc_line_pos(meta, styles, line)
	line.styleref = line.styleref or styles[line.style]

	-- Calculate whole line sizing
	line.text_stripped = line.text:gsub("{[^}]+}", "")
	line.width, line.height, line.descent, line.extlead = aegisub.text_extents(line.styleref, line.text_stripped)
	line.width = line.width * meta.video_x_correct_factor

	-- Effective margins
	line.margin_v = line.margin_t
	line.eff_margin_l = ((line.margin_l > 0) and line.margin_l) or line.styleref.margin_l
	line.eff_margin_r = ((line.margin_r > 0) and line.margin_r) or line.styleref.margin_r
	line.eff_margin_t = ((line.margin_t > 0) and line.margin_t) or line.styleref.margin_t
	line.eff_margin_b = ((line.margin_b > 0) and line.margin_b) or line.styleref.margin_b
	line.eff_margin_v = ((line.margin_v > 0) and line.margin_v) or line.styleref.margin_v
	-- And positioning
	if line.styleref.align == 1 then
		-- Left aligned
		line.left = line.eff_margin_l
		line.center = line.left + line.width / 2
		line.right = line.left + line.width
		line.x = line.left
		line.halign = "left"

		-- Bottom aligned
		line.bottom = meta.res_y - line.eff_margin_b
		line.middle = line.bottom - line.height / 2
		line.top = line.bottom - line.height
		line.y = line.bottom
		line.valign = "bottom"
	elseif line.styleref.align == 2 then
		-- Centered
		line.left = (meta.res_x - line.eff_margin_l - line.eff_margin_r - line.width) / 2 + line.eff_margin_l
		line.center = line.left + line.width / 2
		line.right = line.left + line.width
		line.x = line.center
		line.halign = "center"

		-- Bottom aligned
		line.bottom = meta.res_y - line.eff_margin_b
		line.middle = line.bottom - line.height / 2
		line.top = line.bottom - line.height
		line.y = line.bottom
		line.valign = "bottom"
	elseif line.styleref.align == 3 then
		-- Right aligned
		line.left = meta.res_x - line.eff_margin_r - line.width
		line.center = line.left + line.width / 2
		line.right = line.left + line.width
		line.x = line.right
		line.halign = "right"

		-- Bottom aligned
		line.bottom = meta.res_y - line.eff_margin_b
		line.middle = line.bottom - line.height / 2
		line.top = line.bottom - line.height
		line.y = line.bottom
		line.valign = "bottom"
	elseif line.styleref.align == 4 then
		-- Left aligned
		line.left = line.eff_margin_l
		line.center = line.left + line.width / 2
		line.right = line.left + line.width
		line.x = line.left
		line.halign = "left"

		-- Mid aligned
		line.top = (meta.res_y - line.eff_margin_t - line.eff_margin_b - line.height) / 2 + line.eff_margin_t
		line.middle = line.top + line.height / 2
		line.bottom = line.top + line.height
		line.y = line.middle
		line.valign = "middle"
	elseif line.styleref.align == 5 then
		-- Centered
		line.left = (meta.res_x - line.eff_margin_l - line.eff_margin_r - line.width) / 2 + line.eff_margin_l
		line.center = line.left + line.width / 2
		line.right = line.left + line.width
		line.x = line.center
		line.halign = "center"

		-- Mid aligned
		line.top = (meta.res_y - line.eff_margin_t - line.eff_margin_b - line.height) / 2 + line.eff_margin_t
		line.middle = line.top + line.height / 2
		line.bottom = line.top + line.height
		line.y = line.middle
		line.valign = "middle"
	elseif line.styleref.align == 6 then
		-- Right aligned
		line.left = meta.res_x - line.eff_margin_r - line.width
		line.center = line.left + line.width / 2
		line.right = line.left + line.width
		line.x = line.right
		line.halign = "right"

		-- Mid aligned
		line.top = (meta.res_y - line.eff_margin_t - line.eff_margin_b - line.height) / 2 + line.eff_margin_t
		line.middle = line.top + line.height / 2
		line.bottom = line.top + line.height
		line.y = line.middle
		line.valign = "middle"
	elseif line.styleref.align == 7 then
		-- Left aligned
		line.left = line.eff_margin_l
		line.center = line.left + line.width / 2
		line.right = line.left + line.width
		line.x = line.left
		line.halign = "left"

		-- Top aligned
		line.top = line.eff_margin_t
		line.middle = line.top + line.height / 2
		line.bottom = line.top + line.height
		line.y = line.top
		line.valign = "top"
	elseif line.styleref.align == 8 then
		-- Centered
		line.left = (meta.res_x - line.eff_margin_l - line.eff_margin_r - line.width) / 2 + line.eff_margin_l
		line.center = line.left + line.width / 2
		line.right = line.left + line.width
		line.x = line.center
		line.halign = "center"

		-- Top aligned
		line.top = line.eff_margin_t
		line.middle = line.top + line.height / 2
		line.bottom = line.top + line.height
		line.y = line.top
		line.valign = "top"
	elseif line.styleref.align == 9 then
		-- Right aligned
		line.left = meta.res_x - line.eff_margin_r - line.width
		line.center = line.left + line.width / 2
		line.right = line.left + line.width
		line.x = line.right
		line.halign = "right"

		-- Top aligned
		line.top = line.eff_margin_t
		line.middle = line.top + line.height / 2
		line.bottom = line.top + line.height
		line.y = line.top
		line.valign = "top"
	end
	line.hcenter = line.center
	line.vcenter = line.middle
end
--]]

-- 删除附加字幕行，还原字幕
local function delete_append(subs)
	local delete_lines = {}
	for i = 1, #subs, 1 do
		local line = subs[i]
		if (line.class == "dialogue" and line.effect == "fx") and line.actor == "Text" or line.actor == "Style" or line.actor == "Comment" then
			table.insert(delete_lines, i)
		elseif (line.class == "dialogue" and line.comment) then
			line.comment = false
			subs[i] = line
		end
	end
	subs.delete(delete_lines)
end

-- 获取字幕行数据，并附加行号
local function get_subs_lines(subs)
	local lines = {}
	local delete_lines = {}
	for i = 1, #subs, 1 do
		if subs[i].class == "dialogue" and subs[i].actor == "Text" or subs[i].actor == "Style" or subs[i].actor == "Comment" then
			table.insert(delete_lines, i)
		elseif subs[i].class == "dialogue" then
			lines[#lines+1] = subs[i]
			lines[#lines].li = i
		end
	end
	subs.delete(delete_lines)
	return lines
end

-- 计算当前行显示层数
local function get_current_displays(current_displays, line)
	-- 第一行
	if not(next(current_displays)) then
		current_displays[1] = line
		return
	end

	-- 判断重叠行
	for prev_li = 1, #current_displays do
		local line_prev = current_displays[prev_li]

		if line.start_time >= line_prev.end_time then
			current_displays[prev_li] = line
			return
		end
	end

	-- 新增行
	current_displays[#current_displays + 1] = line
	return
end

-- GUI显示函数库
local display = {
	inset_styles = function(GUI, styles, begin_x, begin_y, is_true)
		begin_y = begin_y or 0
		for style_i = 1, styles.n do
			local style = styles[style_i]
			local ly = begin_y + (style_i - 1)

			table.insert(GUI, {x=begin_x, y=ly, class="label", label="|"})
			table.insert(GUI, {x=begin_x + 1, y=ly, class="checkbox", value=is_true, name=style.name, label=style.name, hint="取消后将不会添加样式文本, 但参加重叠冲突判断"})
			table.insert(GUI, {x=begin_x + 2, y=ly, class="label", label="|"})
		end
	end
}

-- 样式文本GUI
display.GUI_prev_style_string = function(subs)
	local GUI_prev_style_string = [[
| 添加样式修饰文本：                                                               |                                                                                |
| -------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| [is_space_spit]c<1>{在样式文本和原始文本中间添加一个硬空格 `\\h`}:添加空格分隔 | [is_zoom]c<1>{选择后将默认添加 `{\\fscx50\\fscy50}`缩小字体}:添加文本缩小50% |
| 样式左侧修饰文本：                                                               | [prev_string]e{在样式文本的左侧添加修饰}:[                                     |
| 样式右侧修饰文本：                                                               | [post_string]e{在样式文本的右侧添加修饰}:]                                     |
	]]

	local prev_style_string
	-- local btn, return_list = GUI.display(GUI.generate("GUI-append_style_with_leading-prev_style_string"), {"OK", "Delete Append", "Cancel"})
	local btn, return_list = GUI.display(GUI.generate(GUI_prev_style_string), {"OK", "Delete Append", "Cancel"})
	if btn == "Delete Append" then
		delete_append(subs)
		return false
	end

	local is_space_spit = ""
	if return_list.is_space_spit then is_space_spit = "\\h" end

	prev_style_string = string.format("%s%%s%s%s", return_list.prev_string, return_list.post_string, is_space_spit)
	return prev_style_string, return_list
end

-- 样式选择GUI
display.GUI_style_chosen = function(styles)
	local GUI_style_chosen = [[
| 选择添加前后缀的样式                    |                                                                                                                                                  | ： |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ | -- |
| 注释样式：                              | [is_comment]d<注释>{注释样式将直接被忽略，右边的单选项仅是不显示，但是还会参与重叠冲突计算；如果您使用了多个样式进行注释，请点击 `Extra`按钮}: |    |
| c<1>{取消后仅应用于选择行}:应用到所有行 | | |
	]]

	-- local GUI_style_chosen = GUI.generate("GUI-append_style_with_leading-style_chosen")
	local GUI_style_chosen = GUI.generate(GUI_style_chosen)
	display.inset_styles(GUI_style_chosen, styles, 5, 0, true)

	-- 忽略样式
	local style_names = {}
	for style_i = 1, styles.n do
		local style = styles[style_i]
		table.insert(style_names, style.name)
	end

	for i, v in ipairs(GUI_style_chosen) do
		if v.class == "dropdown" then
			GUI_style_chosen[i].items = style_names
			break
		end
	end

	local btn, return_list = GUI.display(GUI_style_chosen, {"OK", "Extra", "Cancel"})

	return_list.is_comment = {return_list.is_comment}
	local GUI_multi_comment_chosen = {
		{y=0, x=1, width=3, class="label", label = "选择需要注释的样式："}
	}
	if btn == "Extra" then
		display.inset_styles(GUI_multi_comment_chosen, styles, 1, 1, false)
		local btn, res_multi_comment_chosen = GUI.display(GUI_multi_comment_chosen)
		for k, v in pairs(res_multi_comment_chosen) do
			if v then
				table.insert(return_list.is_comment, k)
			end
		end
	end

	return return_list
end


main = function(subs)
	local ado = aegisub.debug.out

	local meta, styles = karaskel.collect_head(subs)
	local lines = get_subs_lines(subs)

	-- 无视频输入流警告
	if (meta.res_x == 384 and meta.res_y == 288) or (meta.res_x == 0 and meta.res_y == 0) then
		aegisub.progress.title("Warming")
		aegisub.debug.out(2, "There isn't vidoe stream input, the subtitles will display incorrect positons.")
	end

	-- GUI显示1 - 样式文本GUI
	local prev_style_string, res_prev_style = display.GUI_prev_style_string(subs)
	if not(prev_style_string) then return end
	local zoom_string = ""
	if res_prev_style.is_zoom then zoom_string = "\\fscx50\\fscy50" end

	-- GUI显示2 - 样式选择GUI
	local res_style_chosen = display.GUI_style_chosen(styles)

	-- 进度条显示
	aegisub.progress.title("Appending the style")

	local current_displays = {}
	for li = 1, #lines do
		local line = lines[li]
		karaskel.preproc_line_pos(meta, styles, line)

		get_current_displays(current_displays, line)

		-- 开始重新计算位置信息
		local line_append = table.copy_deep(line)
		local line_style = table.copy_deep(line)
		for current_li = 1, #current_displays do
			if line.li == current_displays[current_li].li then
				local line_prev = current_displays[current_li]

				line.x = line.left
				line.y = line.bottom

				if current_li > 1 and line.styleref.align <= 3 then
					line.y = line.y - (line_prev.styleref.fontsize + (line_prev.styleref.outline + line.styleref.outline))
				elseif current_li > 1 then
					line.y = line.y + (line_prev.styleref.fontsize + (line_prev.styleref.outline + line.styleref.outline))
				end

				-- 注释原文本行
				line.comment = true

				-- 注释样式附加文本行
				if table.concat(res_style_chosen.is_comment):match(line.style) then
					line_append.actor = "Comment"
					line_append.comment = false
					line_append.effect = "fx"
					line_append.text = line.text_stripped
					res_style_chosen[line.style] = false
					break
				end

				-- 附加文本行
				line_append.actor = "Text"
				line_append.comment = false
				line_append.effect = "fx"
				-- 通过对齐方式更改实现位置的绝对定位
				line_append.text = string.format("{\\an1\\pos(%d, %d)}%s",line.x, line.y, line.text_stripped)

				if not(res_style_chosen[line_style.style]) then break end
				-- 附加样式文本行
				line_style.actor = "Style"
				line_style.comment = false
				line_style.effect = "fx"
				local prev_style_string = prev_style_string:format(line.style)
				-- ado(line.style)
				-- 缩小字体将y轴向上偏移`line.descent`，即偏移至基线位置优化观感
				line_style.y = line.y
				if res_prev_style.is_zoom then line_style.y = line.y - line.descent end
				-- 通过对齐方式更改实现位置的绝对定位
				line_style.text = string.format("{\\an3\\pos(%d, %d)%s}%s",line.x, line_style.y, zoom_string, prev_style_string)

				break
			end
		end

		subs[line.li] = line
		subs.append(line_append)
		if res_style_chosen[line_style.style] then subs.append(line_style) end

		aegisub.progress.set((li/#lines)*100)
	end
	aegisub.progress.set(100)
end

aegisub.register_macro(script_name, script_description, main)