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

--- 调用 ImageMagick api 输出重置大小图片 (并将图片输出为.png格式)
--- @param img_path string 图片地址, 支持绝对路径和相对路径
--- @param re_width number 重置的图片宽度
--- @param re_height number 重置的图片高度
--- @param resize_way string 重置大小方式: 'focus' (强制缩放) | 'keep' (保持宽高比(取最长的一边))
--- @return string 重置大小后的图片地址
img_parser.resize = function(img_path, re_width, re_height, resize_way)
	--[[ 参数归一化 ]]
	-- 转换 resize_way
	local resize_way_mapper = {
		focus = '!',
		keep = '^',
	}
	resize_way = includes({'focus', 'keep'}, resize_way) and resize_way or 'focus'
	resize_way = resize_way_mapper[resize_way]
	
	--[[ 异常处理 ]]
	-- 验证路径合法性
	if not path_parser.validate(img_path) then
		error('\n路径出现非法字符: \n  ' .. img_path)
	end
	-- 验证图片是否存在
	if not path_parser.exist_file(img_path) then
		error('\n原始图片不存在: \n  ' .. img_path)
	end
	
	--[[ 主体功能 ]]
	-- 获取文件名
	img_path = path_parser.to_absolute(img_path)
	local dir, filename = path_parser.split_dir(img_path);
	local basename, extend = path_parser.split_basename(filename)
	
	-- 转换图片
	-- 输出重置完大小的图片地址
	local re_img_path = path_parser.join(
		dir,
		('%s(%sx%s%s)%s'):format(
			basename,
			re_width, re_height, resize_way,
			'.png')
	)
	
	-- 如果已经存在转换过的文件, 直接输出路径
	if path_parser.exist_file(re_img_path) then
		return re_img_path
	end
	
	-- 写入重置图片
	img_parser.exec(('start /b magick "%s" -resize "%sx%s%s" "%s"'):format(
		img_path,
		re_width, re_height, resize_way,
		re_img_path
	))
	
	return re_img_path
end

--- 调用 ImageMagick api 将图片为.png格式
--- @param img_path string 图片地址, 支持绝对路径和相对路径
--- @return string 重置大小后的图片地址
img_parser.to_png = function(img_path)
	--[[ 参数归一化 ]]
	-- 将相对路径转为绝对路径
	img_path = path_parser.to_absolute(img_path)
	
	--[[ 异常处理 ]]
	-- 验证路径合法性
	if not path_parser.validate(img_path) then
		error('\n路径出现非法字符: \n  ' .. img_path)
	end
	-- 验证图片是否存在
	if not path_parser.exist_file(img_path) then
		error('\n原始图片不存在: \n  ' .. img_path)
	end
	
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
	--[[ 参数归一化 ]]
	-- 将相对路径转为绝对路径
	img_path = path_parser.to_absolute(img_path)
	
	--[[ 异常处理 ]]
	-- 验证路径合法性
	if not path_parser.validate(img_path) then
		error('\n路径出现非法字符: \n  ' .. img_path)
	end
	-- 验证图片是否存在
	if not path_parser.exist_file(img_path) then
		error('\n原始图片不存在: \n  ' .. img_path)
	end
	
	--[[ 主体功能 ]]
	-- 读取图像信息
	--- @type string `${width: string}x${height: string}`
	local size = img_parser.exec(('start /b magick identify -format "%%[fx:w]x%%[fx:h]" %s'):format(img_path))
	
	-- 获取宽高并输出
	local width, height = size:match('(%d+)x(%d+)')
	return width, height
end


return img_parser
