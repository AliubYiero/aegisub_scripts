--- 图片解析函数库
--- @module img_parser
--- @author Yiero
--- @version 1.0.0
--- 遍历数组 tab , 执行回调函数

local unicode = require('aegisub.unicode')

--- 剪除输入字符串 `str` 的前后的多余空白字符串
--- @param str string
--- @return string
local trim = function(str)
	return str:gsub('^%s*', ''):gsub('%s*$', '')
end

--- @param tab table
--- @param callback function function(item: any, index: number|string):void
--- @return table 返回的新表
local for_each = function(tab, callback)
	for index, item in ipairs(tab) do
		callback(item, index)
	end
end

--- 判断字符串|数字 str 是否存在于表 tab 中, 输出 true / false
--- @param tab table any[]
--- @param str string|number
--- @return boolean
includes = function(tab, str)
	for _, v in pairs(tab) do
		if str == v then
			return true
		end
	end
	return false
end


--- 在表 tab 中找到符合条件的值, 返回对应的项
--- @param tab table T[]
--- @param callback function function(item: T, index: number):boolean
--- @return any|boolean T
find = function(tab, callback)
	for index, value in pairs(tab) do
		if callback(value, index) then
			return value
		end
	end
	return false
end

--- 将 `string.gmatch()` 扁平化, 输出一张 table
--- @param str string
--- @param pattern string 模式匹配
--- @return table string[]
match_list = function(str, pattern)
	local spilt_list = {}
	for s in str:gmatch(pattern) do
		table.insert(spilt_list, s)
	end
	return spilt_list
end

--- 获取输入 table 的所有 key 值
--- @param tbl table
--- @return table
keys = function(tbl)
	local key_list = {}
	for key in pairs(tbl) do
		table.insert(key_list, key)
	end
	return key_list
end

------------------------------------------------------------------------------------
-------------------------------------path_parser-------------------------------------
------------------------------------------------------------------------------------
local path_parser = {}

--- 检测输入路径(字符串)是否合法
--- @param path string 字符串
--- @return boolean
path_parser.validate = function(path)
	local alpha_validate = not path:match('[%*%?"<>|]')
	local ascii_validate = #path == unicode.len(path)
	return alpha_validate and ascii_validate
end

--- 将路径按照分隔符切割成数组
--- @param path string
--- @return string[]
path_parser.split = function(path)
	local path_list = {}
	for s in (path .. '\\'):gmatch('(.-)[/\\]+') do
		table.insert(path_list, s)
	end
	return path_list
end

--- 拼接地址, 使其风格统一
--- 并忽略其中的目录分隔符
--- @param ... string[]
--- @return string
path_parser.join = function(...)
	local concat_path = ''
	for_each({ ... }, function(path, index)
		if index == 1 then
			concat_path = path
			return ;
		end
		concat_path = concat_path .. '\\' .. path
	end)
	concat_path = concat_path:gsub('[\\/]+', '\\')
	return concat_path
end

--- 将相对路径转为绝对路径
--- @param path string 相对路径地址
--- @param root_path string 要参照的根路径地址, 如果不填默认为 .ass 文件所在的地址
--- @return string
path_parser.to_absolute = function(path, root_path)
	-- 参数归一化
	root_path = root_path or _G.aegisub.decode_path('?script')
	
	-- 跳出判断
	if not path:find('^%.') then
		return path
	end
	
	-- 计算层级
	local input_path_list = path_parser.split(path)
	if not input_path_list[1]:match('^%.$') then
		table.insert(input_path_list, 1, '.')
	end
	
	local result_path_list = {};
	for_each(input_path_list, function(item, index)
		if item == '.' and index == 1 then
			local root_path_list = path_parser.split(root_path)
			for_each(root_path_list, function(root_path)
				table.insert(result_path_list, root_path)
			end)
			return
		end
		
		if item == '..' then
			table.remove(result_path_list)
		else
			table.insert(result_path_list, item)
		end
		
		if #result_path_list == 0 then
			error('相对路径错误, 不能删除盘符: ' .. path)
		end
	end)
	
	-- 输出
	return path_parser.join(table.unpack(result_path_list))
end

--- 判断目录(含文件)是否存在
--- @return boolean
path_parser.exist_dir = function(dir_path)
	local respond = os.rename(dir_path, dir_path)
	return not not respond
end

--- 判断文件是否存在
--- @param filepath string 文件路径
--- @return boolean
path_parser.exist_file = function(filepath)
	local file = io.open(filepath, "r")
	if file then
		file:close()
	end
	return file ~= nil
end

--- 分离目录和文件名
--- @param filepath string 文件路径
--- @return string, string dir, filename
path_parser.split_dir = function(filepath)
	return filepath:match('(.*)[\\/](.*)');
end

--- 分离文件基本名和拓展名
--- @param filename string 文件路径
--- @return string, string basename, extend(如 `.lua`)
path_parser.split_basename = function(filename)
	return filename:match('(.*)(%.%w*)')
end

------------------------------------------------------------------------------------
-------------------------------------img_parser-------------------------------------
------------------------------------------------------------------------------------
local img_parser = {}

--- 向外暴露出命令行, 让用户可以自行执行命令
--- @param command string
--- @return string
img_parser.exec = function(command)
	-- 执行命令
	local file = io.popen(command)
	local result = trim(file:read('a'))
	file:close()
	-- 返回命令返回结果
	return result
end

--- 预处理 img_parser 函数, 进行统一的参数处理, 错误处理等
--- @param parma table 类型为 {img_path: string; resize_way: string | 'focus' | 'keep';}
--- @return table 类型为 {img_path: string; resize_way: '!' | '^';}
local _img_parser_prev_parse = function(parma)
	--[[ 参数归一化 ]]
	-- 将相对路径转为绝对路径
	local img_path = path_parser.to_absolute(parma.img_path)
	
	-- 转换 resize_way
	local resize_way_mapper = {
		focus = '!',
		keep = '^',
	}
	local resize_way = resize_way_mapper[includes(keys(resize_way_mapper), parma.resize_way) and parma.resize_way or 'focus']
	
	-- 转换 resize
	-- 如果输入 re_width 和 re_height , 则按照尺寸缩放
	-- 如果只输入 re_width , 则 re_width 将视为缩放百分比
	local re_size = ''
	if parma.re_width and parma.re_height then
		re_size = ('%sx%s%s'):format(parma.re_width, parma.re_height, resize_way)
	elseif parma.re_width and not parma.re_height then
		re_size = ('%s%%'):format(parma.re_width)
	end
	
	--[[ 异常处理 ]]
	-- 验证路径合法性
	if not path_parser.validate(img_path) then
		error('\n路径出现非法字符: \n  ' .. img_path)
	end
	-- 验证图片是否存在
	if not path_parser.exist_file(img_path) then
		error('\n原始图片不存在: \n  ' .. img_path)
	end
	
	return {
		img_path = img_path,
		resize_way = resize_way,
		re_size = re_size,
	}
end

--- 调用 ImageMagick api 输出重置大小图片 (并将图片输出为.png格式)
--- @param img_path string 图片地址, 支持绝对路径和相对路径
--- @param re_width number 重置的图片宽度
--- @param re_height number 重置的图片高度
--- @param resize_way string 重置大小方式: 'focus' (强制缩放) | 'keep' (保持宽高比(取最长的一边))
--- @return string 重置大小后的图片地址
img_parser.resize = function(img_path, re_width, re_height, resize_way)
	--[[ 参数异常预处理 ]]
	local prev_result = _img_parser_prev_parse({
		img_path = img_path,
		resize_way = resize_way,
		re_width = re_width,
		re_height = re_height,
	})
	img_path = prev_result.img_path
	resize_way = prev_result.resize_way
	local re_size = prev_result.re_size
	
	--[[ 主体功能 ]]
	-- 获取文件名
	local dir, filename = path_parser.split_dir(img_path);
	local basename = path_parser.split_basename(filename)
	
	-- 转换图片
	-- 输出重置完大小的图片地址
	local output_filename = ('%s(%s).png'):format(basename, re_size)
	local re_img_path = path_parser.join(dir, output_filename)
	
	-- 如果已经存在转换过的文件, 直接输出路径
	if path_parser.exist_file(re_img_path) then
		return re_img_path
	end
	
	-- 写入重置图片
	local re_size_config = re_size ~= ''
		and string.format('-resize "%s"', re_size)
		or ''
	local command = ('start /b magick "%s" %s "%s"'):format(
		img_path,
		re_size_config,
		re_img_path
	)
	img_parser.exec(command)
	
	return re_img_path
end

--- 调用 ImageMagick api 将图片为.png格式
--- @param img_path string 图片地址, 支持绝对路径和相对路径
--- @return string 重置大小后的图片地址
img_parser.to_png = function(img_path)
	--[[ 参数异常预处理 ]]
	local prev_result = _img_parser_prev_parse({
		img_path = img_path
	})
	img_path = prev_result.img_path
	
	--[[ 主体功能 ]]
	-- 将图片拓展改为 .png 格式
	local filename = path_parser.split_basename(img_path) .. '.png'
	
	-- 如果已经存在转换过的文件, 直接输出路径
	if path_parser.exist_file(filename) then
		return filename
	end
	
	-- 转换图片
	img_parser.exec(('start /b magick "%s" "%s"'):format(
		img_path,
		filename
	))
	
	-- 返回转换图片路径
	return filename
end

--- 获取图片信息
--- @param img_path string 图片地址, 支持绝对路径和相对路径
--- @return string, string width, height (图片宽高)
img_parser.get_size = function(img_path)
	--[[ 参数异常预处理 ]]
	local prev_result = _img_parser_prev_parse({
		img_path = img_path
	})
	img_path = prev_result.img_path
	
	--[[ 主体功能 ]]
	-- 读取图像信息
	--- @type string `${width: string}x${height: string}`
	local size = img_parser.exec(('start /b magick identify -format "%%Wx%%H" %s'):format(img_path))
	
	-- 获取宽高并输出
	local width, height = size:match('(%d+)x(%d+)')
	return width, height
end

--- 分解 gif 图片为帧信息
--- @param img_path string 图片地址, 支持绝对路径和相对路径
--- @param re_width number 可选参数. 重置的图片宽度
--- @param re_height number 可选参数. 重置的图片高度
--- @param resize_way string 重置大小方式: 'focus' (强制缩放) | 'keep' (保持宽高比(取最长的一边))
--- @return table 包含以下信息的数组: {index: number; width: number; height: number; ms: number}
img_parser.decompose_gif = function(img_path, re_width, re_height, resize_way)
	--[[ 参数异常预处理 ]]
	local prev_result = _img_parser_prev_parse({
		img_path = img_path,
		resize_way = resize_way,
		re_width = re_width,
		re_height = re_height,
	})
	img_path = prev_result.img_path
	resize_way = prev_result.resize_way
	local re_size = prev_result.re_size
	
	--[[ 主体功能 ]]
	-- 获取文件 basename (含路径)
	local dir, filename = path_parser.split_dir(img_path)
	local basename = path_parser.split_basename(filename)
	
	-- 创建文件夹
	local output_basename = re_size == ''
		and basename
		or ('%s(%s)'):format(basename, re_size)
	local output_dir = path_parser.join(dir, output_basename)
	local not_exist_dir = not path_parser.exist_dir(output_dir)
	if not_exist_dir then
		local command = ('start /b mkdir "%s"'):format(output_dir)
		img_parser.exec(command)
	end
	
	-- 转换图片
	if not_exist_dir then
		local re_size_config = re_size ~= '' and string.format('-resize "%s"', re_size) or ''
		local command = ('start /b magick "%s" %s -coalesce "%s-%%d.png"')
			:format(img_path, re_size_config, path_parser.join(output_dir, basename))
		img_parser.exec(command)
	end
	
	-- 获取gif帧数, 宽高和时间帧
	local gif_msg_command = string.format('start /b magick identify -format "%%Wx%%Hx%%T\\n" "%s"', img_path)
	local gif_msg_str = img_parser.exec(gif_msg_command) .. '\n'
	local gif_msg_tbl = {}
	for width, height, ms in gif_msg_str:gmatch('(%d+)x(%d+)x(%d+)\n') do
		-- index 和输出的索引一样, 都是从 0 开始
		index = #gif_msg_tbl
		table.insert(gif_msg_tbl, {
			index = index,
			width = tonumber(width),
			height = tonumber(height),
			ms = tonumber(ms) * 10,
			filename = ('%s-%d.png'):format(path_parser.join(output_dir, basename), index)
		})
	end
	-- 重置图片尺寸
	local img_msg_command = string.format(
		'start /b magick identify -format "%%f||%%Wx%%H\\n" "%s"',
		path_parser.join(output_dir, '*.png')
	)
	local img_msg_str = img_parser.exec(img_msg_command) .. '\n'
	for index, width, height in img_msg_str:gmatch('(%d+)%.png||(%d+)x(%d+)\n') do
		local current_msg_tbl = find(gif_msg_tbl, function(item)
			return tonumber(item.index) == tonumber(index)
		end)
		current_msg_tbl.width = width;
		current_msg_tbl.height = height;
	end
	
	return gif_msg_tbl
end

return img_parser
