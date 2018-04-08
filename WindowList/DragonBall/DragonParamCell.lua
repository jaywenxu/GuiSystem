------------------------------------------------------------
-- DragonBallWindow 的子窗口,不要通过 UIManager 访问
------------------------------------------------------------

------------------------------------------------------------
local DragonParamCell = UIControl:new
{
	windowName = "DragonParamCell" ,
	m_paramName = "",
	m_paramText = "",
}

local this = DragonParamCell   -- 方便书写


------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function DragonParamCell:Attach( obj )
	UIControl.Attach(self,obj)
    return self
end

function DragonParamCell:OnDestroy()
	UIControl.OnDestroy(self)
end

function DragonParamCell:ParaParamStr(szParamName)
	
	if IsNilOrEmpty(szParamName) then
		return "", szParamName
	end
	
	local pos = string.find(szParamName, "#")
	if not pos or pos <= 0 then
		return "", szParamName
	end
	local default = string.sub(szParamName, pos +1, string.len(szParamName)) 
	szParamName = string.sub(szParamName, 1, pos - 1) 
	return default, szParamName
end

-- 设置参数名，清空参数值
function DragonParamCell:SetItemInfo(szParamName)
	szParamName = tostring(szParamName or "")
	local defaultNum,szParamName = self:ParaParamStr(szParamName)
	self.Controls.ParamNameText.text = szParamName
	self.Controls.ParamText:GetComponent(typeof(InputField)).text = tostring(defaultNum)
end

-- 获取参数的值
function DragonParamCell:GetParamText()
	return self.Controls.ParamText:GetComponent(typeof(InputField)).text
end

------------------------------------------------------------

return this