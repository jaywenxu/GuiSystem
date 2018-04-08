RichTextHelp = {}
--string 为此类型 我要<herf><color=#FF0000>倚天屠龙刀</color><fun>test(string)</fun></herf>你卖吗？
--sourceStr 需要解析的字符串
function RichTextHelp.AsysSerText(sourceStr,fontSize)	
	local tempStr = nil
	local destStr = ""
	local startPos1 = 0
	local endPos1 =0
	local startPos2 = 0
	local endPos2 =0
	local funStartPos1 = 0
	local funEndPos1 = 0
	local funStartPos2 = 0
	local funEndPos2 = 0
	local otherStr = "" 
	local funTextStr = ""
	local TextStartPos = 0
	local TextEndPos = 0
	local tableText = {}
	local maxHeight = 0
	tempStr = sourceStr
	--先转一下表情
	tempStr,maxHeight = RichTextHelp.Chat_ShortcutEmotion(tempStr,fontSize)
	for n=1,100 do
		local item = {}
		if nil == tempStr or nil == sourceStr then
			destStr =destStr..tempStr
			break
		end
		startPos1,endPos1 = string.find(tempStr,"<herf>")
		startPos2,endPos2 =  string.find(tempStr,"</herf>")
		if startPos1 == endPos1 then
			destStr =destStr..tempStr
			break
		end
		--非我们定义的格式
		if startPos1 > startPos2 then
			destStr =destStr..tempStr
			break
		end
		funStartPos1,funEndPos1 = string.find(tempStr,"<fun>")
		funStartPos2,funEndPos2 = string.find(tempStr,"</fun>")
		--非我们定义的格式
		if funStartPos1 > funStartPos2 then
			destStr =destStr..tempStr
			break
		end
		--非要点击的文字
		otherStr = string.sub(tempStr,1,startPos1-1)
		--函数名字
		funTextStr = string.sub(tempStr,funEndPos1+1,funStartPos2-1)
		--前面已取字符与现在非点击字符
		destStr =destStr..otherStr
		--要点击的字符起始位置(位置要全部用C#的string函数来计算，因为LUA的汉字和C#不一样)
		TextStartPos = utf8.len(destStr)
		--要点击的字符终止位置
		TextEndPos = utf8.len(string.sub(tempStr,endPos1+1,funStartPos1-1)) + TextStartPos
		--已经组装好的文字
		destStr = destStr..string.sub(tempStr,endPos1+1,funStartPos1-1)
		TextStartPos1 ,TextEndPos1 = string.find(destStr,funTextStr)
		item.startPos = TextStartPos
		item.endPos = TextEndPos
		item.fun = funTextStr
		if nil == tableText then
			tableText = {}
		end
		table.insert(tableText,item)
		tempStr = string.sub(tempStr,endPos2+1)
	end

	return destStr,tableText,maxHeight
end

--点击事件的调用
--begin index点击的位置 由Unity函数提供
--endIndex 点击的位置 由Unity函数提供
-- _G["CallBackItemCell"]("123")
--tableText 解析字符串时保存的方法字符串信息（就是上面那个方法）
function RichTextHelp.OnClickAsysSerText(beginIndex,endIndex,tableText)
	if nil == tableText then 
		return false
	end
	for i, v in pairs(tableText) do
		if beginIndex > v.startPos-1 and endIndex < v.endPos then
				local FunText = v.fun
				if IsNilOrEmpty(FunText) then 
					return false
				end
				LuaEval(FunText)
				
			return true
		end
	end
	return false
end

--快捷输入表情
--@: text: 传入的文本
function RichTextHelp.Chat_ShortcutEmotion(text,fontSize)
	local pos = 0
	local temp = ""
	local length = 0
	local startStr=""
	local numberLength = 0
	local str2 =""
	local realNum = 0
	local colorPos1 =0
	local colorPos2 =0
	local colorPos3 = 0
	local MaxHeight = 36
	for n = 1,100 do
		pos=0
		if text == nil then 
			return temp,MaxHeight
		end
		length=string.len(text)
	
		pos = string.find(text,"#",pos + 1)
		if pos ~= nil and pos ~=0  then
			colorPos1,colorPos2 = string.find(text,"<color=",0)
			if colorPos1 ~=nil and colorPos2~=nil then 
				colorPos3 = string.find(text,">",colorPos2)
			end
			if colorPos1 == nil or colorPos3 == nil or pos < colorPos1 or pos > colorPos3 then 
				local str = nil 
				local fstr = string.sub(text,pos+1,pos+1)		--取得第一个数据
				local secstr = string.sub(text,pos+2,pos+2)		--取得第二个数据
				local lstr = string.sub(text,pos+3,pos+3)		--取得第二个数据
				if fstr ~= nil and secstr~=nil and lstr ~=nil then
					str = fstr
					str = str..secstr..lstr
				elseif fstr ~= nil and secstr~=nil and lstr ==nil then
					str = fstr
					str = str..secstr
				elseif fstr ~= nil and lstr ==nil then
					str = fstr
				end
					--判断数字在标号范围内（）
				realNum =tonumber(str)
				
				if (realNum== nil or realNum <10)  or 
				(realNum>73 and 
				realNum~= 501 and 
				realNum~= 502 and 
				realNum ~= 503 and
				realNum ~= 504 and 
				realNum ~= 505 and 
				realNum ~= 506
				 ) then 
					
					startStr= string.sub(text,1,pos)
					temp=temp..startStr
					text = string.sub(text,pos+1,length)
				else
					--判断表情是否可用（比如会员等级等）都要加判断放在NIL后面
					if str ~=nil then
						numberLength =string.len(str)
						local str1 = "#"..str
						startStr= string.sub(text,1,pos-1)
					
						str2 = "<quad size="..fontSize.." width=1 emoji=" ..str1.."/>" 
						MaxHeight = Mathf.Max(MaxHeight,fontSize)
						--将第一个原来字符的信息替换掉
						text = string.sub(text,pos+numberLength+1,length)
						
					else
						startStr= string.sub(text,1,pos)
						str2=""
						text = string.sub(text,pos+1,length)
						
					end
					temp=temp..startStr..str2
					if text == nil then 
						return temp,MaxHeight
					end	
						
				end
				


			else
				
				startStr= string.sub(text,1,colorPos3)
				temp=temp..startStr
				text = string.sub(text,colorPos3+1,length)
			end

		end
		
	end
	return temp..text ,MaxHeight
end