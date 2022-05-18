local tr = aegisub.gettext
script_name = tr("clip_prints")
script_description = tr("clips printer")
script_author = "Yiero"
script_version = "2.0.0"

include("karaskel.lua")
require("unicode")

-- 修改原文件(慎用)
function reself(line, replace, search)
	-- 读取本文件
	file = string.format("%s\\automation\\autoload\\clips_printer.lua",aegisub.decode_path("?data"))

	-- 读取本文件
	local lines = {}
	for v in io.lines(file) do
		table.insert(lines,v)
	end
	
	-- 搜索替换项
	if line then
		line = math.min(line,#lines+1)
		search = search or ".*"
		lines[line] = lines[line]:gsub(search,replace)
	else
		for k,v in ipairs(lines) do
			lines[k] = v:gsub(search,replace)
		end
	end
	
	io.open(file,"w+"):write(table.concat(lines,"\n"))
	return ""
end

clip_prints = function(subs, sel)
	-- 读取字幕文件
	meta, styles = karaskel.collect_head(subs, false)

	for _, i in ipairs(sel) do
		l = subs[i]
	
		-- 处理行信息
		karaskel.preproc_line(subs, meta, styles, l)
		
		-- 报错(没有文本)
		if l.text_stripped == "" then aegisub.debug.out("Error: Cannot match characters.\n"); aegisub.cancel() end
		
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
		
		-- 获取间距fsp
		fsp, syln = 0, 1
		if l.text:match("\\fsp%d") then 
			fsp = l.text:match("\\fsp(%d*)")
			syln = unicode.len(l.text_stripped)
		end
		
		
		-- 计算缩放后x轴坐标
		width = l.width + fsp*syln + (l.styleref.outline*2)
		-- 对齐方式1 4 7(x轴定位)
		if align%3 == 1 then 
			if poses then left = pos.x - l.styleref.outline
			elseif an and not(poses) then left = (l.styleref.margin_l+l.margin_l) - l.styleref.outline
			else left = l.left - l.styleref.outline
			end
			x = left
			right = left + width*(scale_x/100)
			center = (right+left)/2
		-- 对齐方式2 5 8(x轴定位)
		elseif align%3 == 2 then 
			if poses then center = pos.x 	
			elseif an and not(poses) then center = meta.res_x/2 + (l.styleref.margin_l-l.styleref.margin_r) + (l.margin_l-l.margin_r)
			elseif angles then 
			else center = l.center
			end
			x = center
			left = center - (width*(scale_x/100))/2
			right = center + (width*(scale_x/100))/2
		-- 对齐方式3 6 9(x轴定位)
		elseif align%3 == 0 then
			if poses then right = pos.x + l.styleref.outline
			elseif an and not(poses) then right = meta.res_x - (l.styleref.margin_r+l.margin_r) + l.styleref.outline
			else right = l.right + l.styleref.outline
			end
			x = right
			left = right - width*(scale_x/100)
			center = (right+left)/2
		end		
		
		-- 计算缩放后y轴坐标
		height = l.height + (l.styleref.outline*2)
		-- 对齐方式1 2 3(y轴定位)
		if align <= 3 then 
			if poses then bottom = pos.y + l.styleref.outline
			elseif an and not(poses) then bottom = (meta.res_y-l.styleref.margin_v-l.margin_v) + l.styleref.outline
			else bottom = l.bottom + l.styleref.outline
			end
			y = bottom
			top = bottom - height*(scale_y/100)
			middle = (bottom+top)/2
		-- 对齐方式4 5 6(y轴定位)
		elseif align <= 6 then 
			if poses then middle = pos.y
			elseif an and not(poses) then middle = meta.res_y/2 
			else middle = l.middle
			end
			y = middle
			top = middle - (height*(scale_y/100))/2
			bottom = middle + (height*(scale_y/100))/2
		-- 对齐方式7 8 9(y轴定位)
		elseif align <= 9 then 
			if poses then top = pos.y - l.styleref.outline
			elseif an and not(poses) then top = (l.styleref.margin_v+l.margin_v) - l.styleref.outline
			else top = l.top - l.styleref.outline
			end
			y = top
			bottom = top + height*(scale_y/100)
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
		clips_GUI = {
			{x=1, y=0, class="checkbox", label="启用GUI", name="GUI", value=true, hint="取消勾选后，再次使用本插件将会直接输出标签，而不会打开GUI(需重载一遍自动化)\n关闭GUI后在说话人栏输入数字即可修改持续时间(默认从左到右展开)\n在说话人栏输入\"GUI on\"，能够重新进入GUI界面"},
			{x=2, y=0, class="checkbox", label="清除遮罩标签", value=true, name="clean", hint="勾选后将会清除原有的遮罩标签(包括含遮罩标签的t标签)"},
			{x=1, y=1, class="label", label="遮罩标签："}, {x=2, y=1, class="dropdown", name="tags", value="clip", items={"clip", "iclip"}, hint="选择输出的遮罩标签"},
			{x=1, y=2, class="label", label="开始时间："}, {x=2, y=2, class="intedit", name="start_time", value=0, min=0, max=l.duration, hint="修改动态遮罩开始的时间(默认为0)"},
			{x=1, y=3, class="label", label="持续时间："}, {x=2, y=3, class="intedit", name="duration", value=l.duration, min=0, max=l.duration, hint="修改动态遮罩的持续时间(默认行持续时间)\n在说话人栏输入数字能快捷输出(关闭GUI后)"},
			{x=1, y=4, class="label", label="加速度："},   {x=2, y=4, class="floatedit", name="acc", value=1.0, hint="修改动态遮罩的过渡的加速度(也就是\t的加速度)"},
			{x=1, y=5, class="label", label="过渡方向："}, {x=2, y=5, class="dropdown", name="way", value="从左到右", items={"从左到右",  "从上到下", "从右到左", "从下到上", "从中间向两端(竖直)", "从中间向两端(水平)"}, hint="修改动态遮罩展开的方向"},
		}
		
		-- 读取用户输入（说话人栏）
		if l.actor == "GUI on" then 
			btt = true
			l.actor = ""
		elseif l.actor == "GUI off" then 
			clips_GUI[1].value = false
			l.actor = ""
		elseif tonumber(l.actor) then 
			duration = math.min(l.duration, tonumber(l.actor))
			l.actor = ""	
		end
		
		-- 判断GUI是否启用
		if not(btt) and not(clips_GUI[1].value) then 
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
		
		-- GUI关闭跳转
		::GUI::
		
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
			if l.text:find("%b{}") then 
				l.text = l.text:gsub("^(.-{)", string.format("%%1%s", clips))
			else 
				l.text = string.format("{%s}%s", clips, l.text)
			end
		
			-- 修改GUI选项
			if cp_res.GUI ~= clips_GUI[1].value then 
				reself(nil, string.format('label="启用GUI", name="GUI", value=%s,', cp_res.GUI), 'label="启用GUI", name="GUI", value=%w-,') 
			end
		end	
		
		subs[i] = l
	end
	return ""
end


aegisub.register_macro(script_name, script_description, clip_prints)