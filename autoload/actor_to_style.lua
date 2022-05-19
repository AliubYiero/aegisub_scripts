local tr = aegisub.gettext
script_name = tr("actor2style")
script_description = tr("辅助多人轴文本导入")
script_author = "Yiero"
script_version = "1.2.0"

-- 引用unicode库
require('unicode')

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


re = function(subs, selected_lines)
	-- 遍历说话人和样式个数
	local actor,style = {},{}
	local dia_st	-- 对话行开始
	for i=1, #subs do
		v = subs[i]
		if v.class == "dialogue" then
			if not(dia_st) then dia_st = i end		-- 记录对话行开始
			if v.actor ~= "" then actor[v.actor]=tostring(i) end	-- 记录所有对话人
		end
		-- 记录所有样式
		if v.class == "style" then
			table.insert(style,v.name)
		end
	end
	
	-- 输出说话人匹配样式
	fg_GUI = {
		{x=1, y=0, width=8, class="label", label="用于快速将说话人匹配至样式栏，并删除说话人；也可用于文本的导入(兼容全角冒号)"},
		{x=1, y=1, class="label", label="说话人"},
		{x=2, y=1, class="label", label="样式"},
	}
	for v,k in pairs(actor) do
		table.insert(fg_GUI,{x=1, y=math.ceil((#fg_GUI)/2), class="checkbox", name=k, value=true, label=v, hint="选中替换"})
		table.insert(fg_GUI,{x=2, y=math.ceil((#fg_GUI)/2), class="dropdown", name=v, value="Default", items=style})
	end
	fg, fg_res = aegisub.dialog.display(fg_GUI, {"OK", "Add", "Cancel"}, {save="OK", close="Cancel"})
	
	-- 结束进程[Cancel]
	if fg == "Cancel" then 
		aegisub.cancel() 
	end
	
	-- 确认修改[OK]
	if fg == "OK" then
		-- 剔除没选中的说话人更改
		for v, k in pairs(actor) do 
			if fg_res[k] == false then
				actor[v] = nil
			end
		end
	
		for i=dia_st, #subs do
			l = subs[i]
			for v, k in pairs(actor) do
				if l.actor == v then
					l.style = fg_res[v]
					l.actor = ""
				end
			end
			subs[i] = l
		end
	end
	
	-- 添加文本[Add]
	if fg == "Add" then
		-- 弹出文件选择目录
		f = aegisub.dialog.open("Text","","","*.txt")
		
		-- 弹出文本导入选项
		local cfg_comment, cfg_actor
		cfg_actor = load_cfg("actor_to_style", "actor", nil, ": ")
		cfg_comment = load_cfg("actor_to_style", "comment", nil, "#")
		txt_GUI = {
			{x=0, y=0, width=6, class="label", label="文本导入选项"},
			{x=1, y=1, width=6, class="label", label="说话人分隔符: "},
			{x=7, y=1, class="edit", value=cfg_actor, name="actor"},
			{x=1, y=2, width=5, class="label", label="注释开端: "},
			{x=7, y=2, class="edit", value=cfg_comment, name="comment"},
			{x=7, y=3, class="checkbox", value=false, label="包括空白行",name="include"},
		}
		txt, txt_res = aegisub.dialog.display(txt_GUI, {"OK", "Cancel"}, {save="OK", close="Cancel"})
		
		-- 结束进程
		if txt == "Cancel" then aegisub.cancel() end
		
		-- 导入txt文件
		local lines = {}
		local _v = {}
		for v in io.lines(f) do
			table.insert(lines,v)
			local c = 0
			for char in _G.unicode.chars(v) do
				c = c + 1
				if unicode.codepoint(char) <= 0 then
					table.insert(_v,string.format("Runtime error in \"%s\" (line %s, character %s) \nUTF-8(Encoding) expect, got illegal character (%s)", f, #lines, c, unicode.codepoint(char)))
				end
			end
		end
		
		-- 判断
		if _v[1] then
			aegisub.debug.out(table.concat(_v,"\n\n"))
			return ""
		end
		
		-- 判断是否选中空白行
		if txt_res.include == false then
			local i=1
			while i<=#lines do
				if lines[i] == "" then
					table.remove(lines,i)
					i=i-1
				end
				i=i+1
			end
		end
		
		-- 修改文本
			-- 记录一个标准空白行
		local l = {
			["section"] = "[Events]",["class"] = "dialogue",
			["start_time"] = 0,["end_time"] = 0,
			["text"] = "",["comment"] = false,
			["actor"] = "",["effect"] = "",
			["style"] = "Default",["layer"] = 0,
			["margin_t"] = 0,["margin_r"] = 0,
			["margin_l"] = 0,["margin_b"] = 0,
			["raw"] = "Comment: 0,0:00:00.00,0:00:00.00,Default,,0,0,0,,",["extra"] = {},
		}
		
		-- 删除所有对话行
		subs.deleterange(dia_st,#subs)
		
		-- 导入txt文本
		for i=1, #lines do
			l.text = lines[i]
			-- 处理文本（说话人分割符）
			txt_res.actor = txt_res.actor:gsub(" ","")
			txt_res.comment = txt_res.comment:gsub(" ","")
			if l.text:match(txt_res.actor) then
				l.style,l.text = l.text:match(string.format("(.-)%s(.*)",txt_res.actor))
			elseif l.text:match(txt_res.comment) then
				l.text = l.text:gsub("^"..txt_res.comment,"")
				l.comment = true
			end
			subs[0] = l
			l.comment = false
		end
		
		-- 重定向标识符
		load_cfg("actor_to_style", "actor", txt_res.actor)
		load_cfg("actor_to_style", "comment", txt_res.comment)
	end
	return ""
end


aegisub.register_macro(script_name, script_description, re)