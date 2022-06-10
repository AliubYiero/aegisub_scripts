local tr = aegisub.gettext
script_name = tr("shape_rewrite")
script_description = tr("将矢量/标准clip转写成绘图形式, 方便快捷绘图")
script_author = "Yiero"
script_version = "1.0"

-- 抓取所有坐标点
function get_shape(s)
	-- 删除小数
	s = s:gsub("%.%d*", "")
	-- 抓取坐标点
	local pos = {}
	for v in s:gmatch("%d*") do
		if v ~= "" then table.insert(pos, tonumber(v)) end
	end
	-- 定位x, y坐标点
	pos.x, pos.y = {}, {}
	for i=1, #pos, 2 do
		table.insert(pos.x, pos[i])
		table.insert(pos.y, pos[i+1])
	end
	return pos
end


-- 获得坐标轮廓
function get_shape_bounding(s)
	-- 获取所有坐标
	local pos
	pos = get_shape(s)
	-- 获取四顶点
	local left, right, top, bottom
	left = math.min(table.unpack(pos.x))
	right = math.max(table.unpack(pos.x))
	top = math.min(table.unpack(pos.y))
	bottom = math.max(table.unpack(pos.y))
	return left, right, top, bottom
end

-- 将矢量图形移位至坐标原点
function replace_shape_position(s)
	-- 获取图形顶点坐标
	local pos = get_shape(s)
	local left, right, top, bottom
	left, right, top, bottom = get_shape_bounding(s)
	
	-- 整体移位
	for i=1, #pos-1, 2 do
		pos[i] = pos[i] - left
		pos[i+1] = pos[i+1] - top
	end
	
	-- 重写绘图代码
	local counter_i = 0
	s = s:gsub("%d+", function(v)
		counter_i = counter_i + 1
		return pos[counter_i]
	end)
	
	return s
end

shape_rewrite = function(subs,selected_lines)
	for _ , i in ipairs(selected_lines) do
		local l = subs[i]
		
		-- 抓取clip
		local clips = l.text:match("\\clip%((.-)%)")
		
		-- 清除同类特效标签
		l.text = l.text:gsub("\\clip%b()", ""):
				gsub("\\p%d", ""):
				gsub("\\an%d", ""):
				gsub("\\pos%b()", "")
		
		-- 矩形clip绘图
		local left, right, top, bottom
		if clips:match(",") then 
			left, top, right, bottom = clips:match("(.-),(.-),(.-),(.*)")
			clips = string.format("m %d %d l %d %d l %d %d l %d %d l %d %d", 
					left, top,
					right, top, 
					right, bottom, 
					left, bottom, 
					left, top)
		end
		
		-- 记录图形/转写绘图代码
		left, right, top, bottom = get_shape_bounding(clips)
		l.text = l.text:gsub("{", string.format("{\\p1\\an7\\bord0\\shad0\\pos(%d, %d)", left, top)):
					gsub("$", replace_shape_position(clips))
		
		subs[i] = l
	end
end

aegisub.register_macro(script_name, script_description, shape_rewrite)








