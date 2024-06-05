--- 本函数库为 Mock 函数库, 在 aegisub 环境中运行时会自动导入, 用于本地环境调试时使用
--- 函数和效果均与 aegisub.unicode 库一样
--- @module aegisub.unicode
unicode = {}

--- 返回使用UTF-8编码时，在instring中位于index的代码点（code point）所占用的字节数。指向的字符会被假定是一种前缀字节（也就是代码点的首字节）。
--- index参数是可选的，不填时其默认值为1，意为返回instring的首字符宽度。
unicode.charwidth = function(instring, index)
	index = index or 1
	
	local pair_index = 0
	local char_start_index = 0
	local char_end_index = 0
	for width, code in utf8.codes(instring .. ' ') do
		pair_index = pair_index + 1
		
		if pair_index == index then
			char_start_index = width
		elseif pair_index == index + 1 then
			char_end_index = width
			return char_end_index - char_start_index
		end
	end
end

--- 返回一个迭代器函数用于循环所给的UTF-8编码字符串中的每一个代码点。
--- 对于循环中的每次迭代，char会包含表示字符串中下一代码点的字符串。
--- 此字符串长度可能会大于一字节。
unicode.chars = function(instring)
	local string_list = {}
	for _, c in utf8.codes(instring) do
		table.insert(string_list, utf8.char(c))
	end
	
	local i = 0
	return function()
		i = i + 1
		return string_list[i]
	end
end

--- 以代码点为单位判断所给UTF-8编码的字符串的长度。
unicode.len = function(instring)
	return utf8.len(instring)
end

--- 读取instring中的首个Unicode代码点。
unicode.codepoint = function(instring, index)
	index = index or 1
	
	local pair_index = 0
	for width, code in utf8.codes(instring) do
		pair_index = pair_index + 1
		
		if pair_index == index then
			return code
		end
	end
end

--- 将一个字符串转换为大写。 此函数可处理读音符号、非拉丁文字等文本。
unicode.to_upper_case = function(instring)
	return instring:upper()
end

--- 将一个字符串转换为小写。 此函数可处理读音符号、非拉丁文字等文本。
unicode.to_lower_case = function(instring)
	return instring:lower()
end

--- 将一个字符串折叠大小写（fold case）。 这种模式类似于小写，但对语种不敏感，因此用在大小写不敏感的对比时会有更好的表现。
unicode.to_fold_case = function(instring)
	return instring:lower()
end

return unicode
