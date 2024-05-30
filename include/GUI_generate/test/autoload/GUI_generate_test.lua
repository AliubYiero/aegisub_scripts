local tr = aegisub.gettext
local script_name = tr("GUI_generate_test")
local script_description = tr("")
local script_author = "Yiero"
local script_version = "1.0.0"

local GUI = require 'GUI_generate'

local GUI_txt_input = [[
	| 说话人分割符： | [actor_spit]e:：                |
	| -------------- | ------------------------------- |
	| 注释前缀：     | [comment]e:#                    |
	| >              | [is_include_blanks]c:包括空白行 |
]]
local main = function(subs, selected_lines)
	-- 使用md表格文本格式写一个Aeg原生导入txt文本的GUI
	local GUI_txt_input = GUI.generate(GUI_txt_input)
	local btn, res_txt_input = GUI.display(GUI_txt_input, {"确认", "取消"})

	-- 使用文件导入[./automation/src]目录下的md文件
	local GUI_blank_video = GUI.generate("GUI-generate_test-blank_video")
	local btn, res_blank_video = GUI.display(GUI_blank_video)

end

aegisub.register_macro(script_name, script_description, main)