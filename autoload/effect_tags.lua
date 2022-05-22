local tr = aegisub.gettext
script_name = tr("effect_tags")
script_description = tr("help tags")
script_author = "Yiero"
script_version = "1.0.1"

include("karaskel.lua")


-- 浏览文件获取其行表
viewfiles = function(path)
	-- 读取行
	local lines = {}
	-- 以追加更新模式读取文件（若没有文件，则新建文件）
	for v in io.open(path,"a+"):lines() do
		lines[#lines+1] = v
	end
	return lines
end

-- 读取/修改配置信息
function load_cfg(script_name, key, input, Default)
	-- 加载配置文件路径
	local file_path
	file_path = string.format("%s\\automation\\include\\Yuint_config.lua", aegisub.decode_path("?data"))

	-- 读取文件
	local lines
	lines = viewfiles(file_path)
	
	-- 初始化文件
	file = io.open(file_path, "w+")
	if not(lines[1]) then lines[1] = "Yuint_config = {}"; lines[2] = "return Yuint_config" end

	-- 遍历至配置信息
	local save, line
	local i = 1
	while i < #lines do
		if lines[i]:match(script_name) then 
			while lines[i] ~= "}" do
				save = lines[i]:match(string.format('%s = "(.-)",', key))
				line = i
				if save then break end
				i=i+1
			end
			break
		end
		i=i+1
	end
	-- 无配置信息输出
	if i == #lines then 
		table.insert(lines, #lines, string.format("Yuint_config.%s = {", script_name))
		table.insert(lines, #lines, string.format('\t%s = "%s",', key, Default))
		table.insert(lines, #lines, string.format("}"))
	elseif not(save) then
		table.insert(lines, i, string.format('\t%s = "%s",', key, Default))
		save = Default
		line = i
	end
	
	-- 布尔值重赋值
	if save == "true" then save = true
	elseif save == "false" then save = false
	end
	
	-- 判断输入or输出
	-- 输出
	if input == nil then 
		file:write(table.concat(lines,"\n"))
		file:close()
		return save
		
	-- 输入
	else
		if input ~= save then lines[line] = string.format('\t%s = "%s",', key, input) end
		file:write(table.concat(lines,"\n"))
		file:close()
		return ""
	end
end

-- 添加函数至文本中
add_effect = function(s, tag)
	if not(s:match("%b{}")) then s = string.format("{}%s", s) end
	s = s:gsub("^(.-)}", string.format("%%1%s}", tag))
	return s
end
			
-- 动态遮罩主函数
clip_prints = function(subs, sel)
	-- 读取字幕文件
	meta, styles = karaskel.collect_head(subs, false)

	for _, i in ipairs(sel) do
		local l = subs[i]

		-- 处理行信息
		karaskel.preproc_line(subs, meta, styles, l)
		
		-- 报错(没有文本)
		if l.text:gsub("%b{}","") == "" then aegisub.debug.out("Error: Cannot match characters.\n"); aegisub.cancel() end
		
		-- 定义变量
		local x, y
		local left, right, center
		local top, bottom, middle
		local width, height
		local fsp, syln
		local align, an
		local scale_x, scale_y
		local pos, poses
		local start_time, duration, acc
		local clips_GUI, cp, cp_res
		local btt
		local tag
		local angle, org
		local shadow, outline
		local draws
		
		-- 获取缩放倍率fsc
		scale_x, scale_y = 100, 100
		if l.text:match("\\fsc%d") then 
			scale_x = tonumber(l.text:match("\\fsc(%d*)"))
			scale_y = scale_x 
		elseif l.text:match("\\fscx") or l.text:match("\\fscy") then 
			scale_x = tonumber(l.text:match("\\fscx(%d*)")) or 100
			scale_y = tonumber(l.text:match("\\fscy(%d*)")) or 100
		end
		
		
		-- 获取对齐方式an
		align = l.styleref.align
		an = false
		if l.text:match("\\an%d") then 
			align = tonumber(l.text:match("\\an(%d)")) 
			an = true
		end
		
		-- 获取定位中心pos
		pos = {}
		poses = false
		if l.text:match("\\pos") then 
			pos.x, pos.y = l.text:match("\\pos%((.-),(.-)%)")
			pos.x, pos.y = tonumber(pos.x), tonumber(pos.y)
			poses = true
		end		
		
		require("unicode")
		-- 获取间距fsp
		fsp, syln = 0, 1
		if l.text:match("\\fsp%d") then 
			fsp = l.text:match("\\fsp(%d*)")
			syln = unicode.len(l.text_stripped)
		end
		
		-- 获取边框bord(outline)
		outline = {["x"] = l.styleref.outline, ["y"] = l.styleref.outline}
		if l.text:match("\\bord%d") then 
			outline.x = tonumber(l.text:match("\\bord(%d*)") )
			outline.y = outline.x
		elseif l.text:match("\\[xy]bord%d") then 
			outline.x = tonumber(l.text:match("\\xbord(%d*)")) or l.styleref.outline
			outline.y = tonumber(l.text:match("\\ybord(%d*)")) or l.styleref.outline
		end		
	
		-- 获取阴影shad(shadow)
		shadow = {["x"] = l.styleref.shadow, ["y"] = l.styleref.shadow}
		if l.text:match("\\shad%d") then 
			shadow.x = tonumber(l.text:match("\\shad(%d*)") )
			shadow.y = shadow.x
		elseif l.text:match("\\[xy]shad%d") then 
			shadow.x = tonumber(l.text:match("\\xshad(%-?%d*)")) or l.styleref.shadow
			shadow.y = tonumber(l.text:match("\\yshad(%-?%d*)")) or l.styleref.shadow
		end
		
		-- 计算绘图代码位置信息
		local draw = {["x"]={}, ["y"]={}}
		local draw_left, draw_right, draw_top, draw_bottom, draw_width, draw_height
		local zero = {["x"]=0, ["y"]=0}
		if l.text:match("\\p%d") then
			local p
		
			draws = true
			-- 抓取绘图代码的坐标
			for v in l.text:gsub("%b{}", ""):gmatch("%-?%d*%.?%d*") do
				if v ~= "" then 
					v = tonumber(v)
					if #draw.x <= #draw.y then table.insert(draw.x, v) 
					else table.insert(draw.y, v) 
					end
				end
			end
			
			-- 抓取绘图缩放指令
			p = l.text:match("\\p(%d)")
			
			-- 抓取绘图代码的边界顶点
			draw_left = math.min(table.unpack(draw.x)) * (scale_x/100) * (1/(2^(p-1)))
			draw_right = math.max(table.unpack(draw.x)) * (scale_x/100) * (1/(2^(p-1)))
			draw_bottom = math.max(table.unpack(draw.y)) * (scale_y/100) * (1/(2^(p-1)))
			draw_top = math.min(table.unpack(draw.y)) * (scale_y/100) * (1/(2^(p-1)))
			draw_width = draw_right - draw_left
			draw_height = draw_bottom - draw_top
		end
		-- aegisub.debug.out(string.format("%d, %d ,%d, %d·", draw_left, draw_right, draw_top, draw_bottom))
		
		-- 添加一个x轴间隙
		local space = 5
		-- 计算缩放后x轴坐标
		if draws then width = draw_width + (outline.x*2) + shadow.x + space*2
		else width = l.width + fsp*syln + (outline.x*2) + shadow.x + space*2
		end
		-- 对齐方式1 4 7(x轴定位)
		if align%3 == 1 then 
			if poses then left = pos.x
			elseif an and not(poses) then left = (l.styleref.margin_l+l.margin_l)
			else left = l.left
			end
			-- 计算边框和阴影
			left = left - outline.x - space
			if shadow.x < 0 then left = left + shadow.x end
			-- 计算其他赋值
			right = left + width*(scale_x/100)
			-- 绘图行零点重赋值
			if draws then 
				zero.x = left 
				left = zero.x + draw_left
				right = left + width
			end
			x = left
			center = (right+left)/2
		-- 对齐方式2 5 8(x轴定位)
		elseif align%3 == 2 then 
			if poses then center = pos.x 	
			elseif an and not(poses) then center = meta.res_x/2 + (l.styleref.margin_l-l.styleref.margin_r) + (l.margin_l-l.margin_r)
			elseif angles then 
			else center = l.center
			end
			-- 计算其他赋值
			left = center - (width*(scale_x/100))/2
			right = center + (width*(scale_x/100))/2
			-- 绘图行零点重赋值
			if draws then 
				zero.x = center - draw_width/2 
				left = zero.x + draw_left - outline.x - space
				if shadow.x < 0 then left = left + shadow.x end
				right = left + width*(scale_x/100)
				center = (right+left)/2
			end
			x = center
		-- 对齐方式3 6 9(x轴定位)
		elseif align%3 == 0 then
			if poses then right = pos.x
			elseif an and not(poses) then right = meta.res_x - (l.styleref.margin_r+l.margin_r)
			else right = l.right
			end
			-- 计算边框和阴影
			right = right + outline.x
			if shadow.x > 0 then right = right + shadow.x end
			-- 计算其他赋值
			left = right - width*(scale_x/100)
			-- 绘图行零点重赋值
			if draws then 
				zero.x = right - draw_width
				right = zero.x + draw_right + space
				left = right - width
			end
			x = right
			center = (right+left)/2
		end		
		
		-- 计算缩放后y轴坐标
		if draws then height = draw_height + (outline.y*2) + shadow.y + space*2
		else height = l.height + (outline.y*2) + shadow.y
		end
		-- 对齐方式1 2 3(y轴定位)
		if align <= 3 then 
			if poses then bottom = pos.y
			elseif an and not(poses) then bottom = (meta.res_y-l.styleref.margin_v-l.margin_v)
			else bottom = l.bottom
			end
			-- 计算边框和阴影
			bottom = bottom + outline.y
			if shadow.y > 0 then bottom = bottom + shadow.y end
			-- 计算其他赋值
			top = bottom - height*(scale_y/100)
			-- 绘图行零点重赋值
			if draws then 
				zero.y = bottom - draw_height 
				bottom = zero.y + draw_bottom + space*2
				top = bottom - height
			end
			y = bottom
			middle = (bottom+top)/2
		-- 对齐方式4 5 6(y轴定位)
		elseif align <= 6 then 
			if poses then middle = pos.y
			elseif an and not(poses) then middle = meta.res_y/2 
			else middle = l.middle
			end
			-- 计算其他赋值
			top = middle - (height*(scale_y/100))/2
			bottom = middle + (height*(scale_y/100))/2
			-- 绘图行零点重赋值
			if draws then 
				zero.y = middle - height/2 
				bottom = zero.y + draw_bottom + outline.y + space*2
				if shadow.y > 0 then bottom = bottom + shadow.y end
				top = bottom - height*(scale_y/100)
				middle = (bottom+top)/2
			end
			y = middle
		-- 对齐方式7 8 9(y轴定位)
		elseif align <= 9 then 
			if poses then top = pos.y
			elseif an and not(poses) then top = (l.styleref.margin_v+l.margin_v)
			else top = l.top
			end
			-- 计算边框和阴影
			top = top - outline.y
			if shadow.y < 0 then top = top + shadow.y end
			-- 计算其他赋值
			bottom = top + height*(scale_y/100)
			-- 绘图行零点重赋值
			if draws then 
				zero.y = top 
				top = zero.y + draw_top - space
				bottom = top + height
			end
			y = top
			middle = (bottom+top)/2
		end	
		
		
		-- 获取旋转角度frz和旋转中心org
		angle = l.styleref.angle
		org = {["x"]=x, ["y"]=y}
		if l.text:match("\\frz?%d") then angle = tonumber(l.text:match("\\frz?(%d*)")) end
		if l.text:match("\\org") then org.x, org.y = l.text:match("\\org%((.-),(.-)%)"); org.x, org.y = tonumber(org.x), tonumber(org.y) end
		-- 计算旋转后x, y坐标
		if angle ~= 0 then
			local Hwidth, Hheight = width/2, height/2
			local L_margin_angle, R_margin_angle, O_margin_angle
			local LT, LB, RT, RB
			local radius, Radius
			local Rangle
			
			-- 重置angle区间（1~360）
			if angle < 0 or angle >= 360 then angle = angle + math.floor((360-angle)/360)*360 end
			Rangle = math.rad(angle)
			-- 计算旋转半径
			radius = Hwidth + l.descent
			Radius = math.sqrt((org.x-center)^2+(org.y-middle)^2)
			-- 计算4 7/1的弧度差(定位到左上/左下顶点所需弧度)
			L_margin_angle = math.asin((Hheight) / math.sqrt(Hheight^2+Hwidth^2))
			-- 计算4 3/9的弧度差(定位到右下/右上下顶点所需弧度)
			R_margin_angle = math.acos((Hwidth^2+(Hheight^2+Hwidth^2)-(width^2+Hheight^2))/(2*(Hwidth)*math.sqrt((Hheight^2+Hwidth^2))))
			
			-- 计算旋转中心org与定位中心pos的弧度差
			O_margin_angle = math.asin(math.abs(middle-org.y) / math.sqrt((middle-org.y)^2+(center-org.x)^2))
			-- 重定位旋转中心（video → character）
			org.x = org.x - Radius*(math.cos(Rangle - (O_margin_angle)))
			org.y = org.y + Radius*(math.sin(Rangle - (O_margin_angle)))
			
			-- 计算四个顶点的坐标(相对行中心)
			LT = {["x"] = org.x - radius*(math.cos(Rangle-L_margin_angle)), ["y"] = org.y - radius*(math.sin(Rangle-L_margin_angle))}
			LB = {["x"] = org.x - radius*(math.cos(Rangle+L_margin_angle)), ["y"] = org.y - radius*(math.sin(Rangle+L_margin_angle))}
			RT = {["x"] = org.x - radius*(math.cos(Rangle-R_margin_angle)), ["y"] = org.y - radius*(math.sin(Rangle-R_margin_angle))}
			RB = {["x"] = org.x - radius*(math.cos(Rangle+R_margin_angle)), ["y"] = org.y - radius*(math.sin(Rangle+R_margin_angle))}

			-- debug输出
			-- aegisub.debug.out(string.format("%d\n{\\pos(%d,%d)}·", math.deg(Rangle - (O_margin_angle)), org.x, org.y))
			
			-- 初始化坐标
			if angle > 0 and angle <= 90 then
				left = LT.x
				right = RB.x
				top = LB.y
				bottom = RT.y
			elseif angle > 90 and angle <= 180 then
				left = RT.x
				right = LB.x
				top = LT.y
				bottom = RB.y
			elseif angle > 180 and angle <= 270 then
				left = RB.x
				right = LT.x
				top = RT.y
				bottom = LB.y
			elseif angle > 270 and angle <= 360 then
				left = LB.x
				right = RT.x
				top = RB.y
				bottom = LT.y
			end
			center = (right+left)/2
			middle = (bottom+top)/2
		end

		---------------------- 用户输入	
		-- 创建GUI
		local cfg_GUI, cfg_clean
		cfg_GUI = load_cfg("clips_printer", "GUI", nil, true)
		cfg_clean = load_cfg("clips_printer", "clean", nil, true)
		clips_GUI = {
			{x=1, y=0, class="checkbox", label="启用GUI", name="GUI", value=cfg_GUI, hint="取消勾选后，再次使用本插件将会直接输出标签，而不会打开GUI(需重载一遍自动化)\n关闭GUI后在说话人栏输入数字即可修改持续时间(默认从左到右展开)\n在说话人栏输入\"GUI on\"，能够重新进入GUI界面"},
			{x=2, y=0, class="checkbox", label="清除遮罩标签", name="clean", value=cfg_clean, hint="勾选后将会清除原有的遮罩标签(包括含遮罩标签的t标签)"},
			{x=1, y=1, class="label", label="遮罩标签："}, {x=2, y=1, class="dropdown", name="tags", value="clip", items={"clip", "iclip"}, hint="选择输出的遮罩标签"},
			{x=1, y=2, class="label", label="开始时间："}, {x=2, y=2, class="intedit", name="start_time", value=0, min=0, max=l.duration, hint="修改动态遮罩开始的时间(默认为0)"},
			{x=1, y=3, class="label", label="持续时间："}, {x=2, y=3, class="intedit", name="duration", value=l.duration, min=0, max=l.duration, hint="修改动态遮罩的持续时间(默认行持续时间)\n在说话人栏输入数字能快捷输出(关闭GUI后)\nPS.若遮罩显示不全(通过跳帧的方式查看)，极大概率最后一帧没有显示而不是遮罩没罩全，请调整持续时间再作查看"},
			{x=1, y=4, class="label", label="加速度："},   {x=2, y=4, class="floatedit", name="acc", value=1.0, hint="修改动态遮罩的过渡的加速度(也就是\t的加速度)"},
			{x=1, y=5, class="label", label="过渡方向："}, {x=2, y=5, class="dropdown", name="way", value="从左到右", items={"从左到右",  "从上到下", "从右到左", "从下到上", "从中间向两端(竖直)", "从中间向两端(水平)"}, hint="修改动态遮罩展开的方向"},
		}
		
		-- 读取用户输入（说话人栏）
		if l.actor == "GUI on" then 
			btt = true
			l.actor = ""
		elseif l.actor == "GUI off" then 
			cfg_GUI = false
			l.actor = ""
		elseif tonumber(l.actor) then 
			duration = math.min(l.duration, tonumber(l.actor))
			l.actor = ""	
		end
		
		-- 判断GUI是否启用
		if not(btt) and not(cfg_GUI) then 
			cp = "Apply"
			cp_res = {
				["tags"] = "clip",
				["start_time"] = 0,
				["duration"] = l.duration,
				["acc"] = 1,
				["way"] = "从左到右",
				["clean"] = true,
			}
			
		-- 输出GUI
		else 
			cp, cp_res = aegisub.dialog.display(clips_GUI, {"Apply", "Cancel"}, {save="Apply", close="Cancel"}) 
		end
		
		-- 选项[取消]
		if cp == "Cancel" then aegisub.cancel() end
		
		-- 选项[确认]
		if cp == "Apply" then 
			-- 初始化GUI输出结果
			start_time = cp_res.start_time
			duration = cp_res.duration
			tag = cp_res.tags
			if cp_res.acc == 1 then acc = "" else acc = string.format("%0.1f,", cp_res.acc) end
		
			-- 清除clip标签
			if cp_res.clean then 
				l.text = l.text:gsub("([^, ])\\clip%b()","%1")
				l.text = l.text:gsub("([^, ])\\iclip%b()","%1")
				l.text = l.text:gsub("\\t%(.-, ?\\clip%b()%)","")
				l.text = l.text:gsub("\\t%(.-, ?\\iclip%b()%)","")
			end
			
			
			-- 创建clip标签
			local clips
			if cp_res.way == "从左到右" then 
				clips = string.format("\\%s(%d,%d,%d,%d)\\t(%d,%d,%s\\%s(%d,%d,%d,%d))",
					tag, left, top, left, bottom, 
					start_time, duration, acc, 
					tag, left, top, right, bottom)
			elseif cp_res.way == "从上到下" then 
				clips = string.format("\\%s(%d,%d,%d,%d)\\t(%d,%d,%s\\%s(%d,%d,%d,%d))",
					tag, left, top, right, top, 
					start_time, duration, acc, 
					tag, left, top, right, bottom)
			elseif cp_res.way == "从右到左" then 
				clips = string.format("\\%s(%d,%d,%d,%d)\\t(%d,%d,%s\\%s(%d,%d,%d,%d))",
					tag, right, top, right, bottom, 
					start_time, duration, acc, 
					tag, left, top, right, bottom)
			elseif cp_res.way == "从下到上" then 
				clips = string.format("\\%s(%d,%d,%d,%d)\\t(%d,%d,%s\\%s(%d,%d,%d,%d))",
					tag, left, bottom, right, bottom, 
					start_time, duration, acc, 
					tag, left, top, right, bottom)
			elseif cp_res.way == "从中间向两端(竖直)" then 
				clips = string.format("\\%s(%d,%d,%d,%d)\\t(%d,%d,%s\\%s(%d,%d,%d,%d))",
					tag, left, middle, right, middle, 
					start_time, duration, acc, 
					tag, left, top, right, bottom)
			elseif cp_res.way == "从中间向两端(水平)" then 
				clips = string.format("\\%s(%d,%d,%d,%d)\\t(%d,%d,%s\\%s(%d,%d,%d,%d))",
					tag, center, top, center, bottom, 
					start_time, duration, acc, 
					tag, left, top, right, bottom)
			end
			
			-- 添加clip标签
			l.text = add_effect(l.text, clips)
		
			-- 修改GUI选项
			load_cfg("clips_printer", "GUI", cp_res.GUI)
			load_cfg("clips_printer", "clean", cp_res.clean)
		end	
		
		subs[i] = l
	end
	return ""
end

-- 多重边框主函数
multi_bord = function(subs, sel)
	-- 函数：ASS颜色代码转RBG颜色代码
	ass_to_rgb = function(ass)
		local r, g, b
		local r0, g0, b0, r1, g1, b1
		
		ass = ass:gsub("&", "")
		-- 抓取十六进制颜色
		b1, b0, g1, g0, r1, r0 = ass:match("(.)(.)(.)(.)(.)(.)$")
		-- 十六进制字母转十进制数字
		local rgb = function(s)
			if s == "A" or s == "a" then s = 10
			elseif s == "B" or s == "b" then s = 11
			elseif s == "C" or s == "c" then s = 12
			elseif s == "D" or s == "d" then s = 13
			elseif s == "E" or s == "e" then s = 14
			elseif s == "F" or s == "f" then s = 15
			end
			if not(s) then s = 0 end
			return tonumber(s)
		end
		-- 换算十进制
		r = rgb(r0) + rgb(r1)*16
		g = rgb(g0) + rgb(g1)*16
		b = rgb(b0) + rgb(b1)*16
		return string.format("%d,%d,%d", r, g, b)
	end
	
	-- 抓取rgb(string)输出r,g,b(number)
	match_rgb = function(s)
		local r, g, b
		r, g, b = s:match("(%d*),(%d*),(%d*)")
		return tonumber(r), tonumber(g), tonumber(b)
	end
	
	-- 收集头数据
	meta, styles = karaskel.collect_head(subs, false)

	-- 收集未注释对话行
	local sel_dialines = {}
	for i=1, #subs do 
		if subs[i].class == "dialogue" and not(subs[i].comment) then 
			table.insert(sel_dialines, i) 
		end 
	end
	
	-- 创建GUi
	local l = subs[sel_dialines[1]]
	-- 处理行信息
	karaskel.preproc_line(subs, meta, styles, l)
	
	-- 创建一级GUI(输入边框层数)
	local bord_GUI, bd, bd_res
	local bord_n, sel_lines
	bord_GUI = {
		{x=1, y=0, class="label", label="选择行："}, {x=2, y=0, class="dropdown", name="sel_lines", value="所选行", items={"所选行", "全选行"}}, 
		{x=1, y=1, class="label", label="边框层数："}, {x=2, y=1, class="intedit", name="bord_n", value=1} 
	}
	bd, bd_res = aegisub.dialog.display(bord_GUI, {"Apply", "Cancel"}, {save="Apply", cancel="Cancel"})
	bord_n = bd_res.bord_n
	sel_lines = bd_res.sel_lines
	
	if bd == "Cancel" then aegisub.cancel() 
	elseif bd == "Apply" then 
		-- 创建二级GUI（输入颜色）
		bord_GUI = {
			{x=1, y=0, class="label", label="主颜色"}, {x=2, y=0, class="label", label=""}, {x=3, y=0, class="color", value=l.styleref.color1, name="ass", hint="通过颜色管理器选择颜色"}, {x=4, y=0, class="edit", value=ass_to_rgb(l.styleref.color1), name="rgb", hint="输入RGB颜色选择颜色\n注：优先选择RGB颜色"}, 
			{x=1, y=1, class="label", label="边框层数"}, {x=2, y=1, class="label", label="边框厚度"}, {x=3, y=1, class="label", label="选择颜色(ASS)"}, {x=4, y=1, class="label", label="选择颜色(R,G,B)"}, 
		}
		-- 迭代边框
		for i = 1, bord_n do 
			table.insert(bord_GUI, {x=1, y=i+1, class="label", label=string.format("[#%d]边框", i)})
			table.insert(bord_GUI, {x=2, y=i+1, class="edit", value=l.styleref.outline, name=string.format("bord%d", i), hint="边框层数从里到外"})
			table.insert(bord_GUI, {x=3, y=i+1, class="color", value=l.styleref.color3, name=string.format("ass%d", i), hint="通过颜色管理器选择颜色"})
			table.insert(bord_GUI, {x=4, y=i+1, class="edit", value="", name=string.format("rgb%d", i), hint="输入RGB颜色选择颜色\n注：优先选择RGB颜色"})
		end
		
		bd, bd_res = aegisub.dialog.display(bord_GUI, {"Apply", "Cancel"}, {save="Apply", cancel="Cancel"})
			
		if bd == "Cancel" then aegisub.cancel()
		elseif bd == "Apply" then 
			util = require("aegisub.util")
			
			if sel_lines == "全选行" then sel = sel_dialines end
			for u=1, #sel do
				local k = sel[u]+(u-1)*(bord_n-1)
				l = subs[k]
				karaskel.preproc_line(subs, meta, styles, l)
				-- 导入主颜色数据
				local main_color
				if bd_res.rgb ~= ass_to_rgb(l.styleref.color1) then main_color = util.ass_color(match_rgb(bd_res.rgb))
				else main_color = bd_res.ass:gsub("#(..)(..)(..)", "&H%3%2%1&")
				end
				-- 遍历边框数据
				local bord = 0
				local color, rgb
				for i = 1, bord_n do 
					-- 插入行
					if i > 1 then subs.insert(k+(i-1), l) end 
					
					-- 导入用户数据
					bord = bord + tonumber(bd_res[string.format("bord%d", i)])
					color = bd_res[string.format("ass%d", i)]:gsub("#(..)(..)(..)", "&H%3%2%1&")
					rgb = bd_res[string.format("rgb%d", i)]
					
					if rgb ~= "" then color = util.ass_color(match_rgb(rgb)) end
					
					-- 删除重复标签
					l.text = l.text:gsub("\\shad%d*%.?%d*", "")
					l.text = l.text:gsub("\\bord%d*%.?%d*", "")
					l.text = l.text:gsub("\\1?c[%w&]*", "")
					l.text = l.text:gsub("\\3c[%w&]*", "")
					
					-- 输出至文本
					local bords
					bords = string.format("\\1c%s\\3c%s\\bord%s\\shad0", main_color, color, bord)
					l.text = add_effect(l.text, bords)
					l.layer = (bord_n-i)+1
					
					subs[k+(i-1)] = l
				end
			end
		end
	end
end		


aegisub.register_macro(script_name.."/clip_prints", script_description, clip_prints)
aegisub.register_macro(script_name.."/multi_bord", script_description, multi_bord)