--/*******************************************************************
--** 文件名:    BuffIconWidget.lua
--** 版  权:    (C) 深圳冰川网络技术有限公司 2016 - Speed
--** 创建人:    贾屹夫
--** 日  期:    2017/05/25
--** 版  本:    1.0
--** 描  述:    人物头像窗口下面的一排buff图标
--********************************************************************/

local max_icon_count = 6

local BuffIconWidget = UIControl:new
{
	windowName = "BuffIconWidget",
	isAwake = false,
	iconList = {},
}

function BuffIconWidget:Attach( obj )
    UIControl.Attach(self,obj)
	self.isAwake = true
	
	self.callback_OnAddBuff = function(event, srctype, srcid, msg) self:OnAddBuff(msg) end
	self.callback_OnRemoveBuff = function(event, srctype, srcid, msg) self:OnRemoveBuff(msg) end
	rktEventEngine.SubscribeExecute(EVENT_CREATURE_ADDBUFF, SOURCE_TYPE_PERSON, 0, self.callback_OnAddBuff)
	rktEventEngine.SubscribeExecute(EVENT_CREATURE_REMOVEBUFF, SOURCE_TYPE_PERSON, 0, self.callback_OnRemoveBuff)
end

function BuffIconWidget:OnDestroy()
	rktEventEngine.UnSubscribeExecute(EVENT_CREATURE_ADDBUFF, SOURCE_TYPE_PERSON, 0, self.callback_OnAddBuff)
	rktEventEngine.UnSubscribeExecute(EVENT_CREATURE_REMOVEBUFF, SOURCE_TYPE_PERSON, 0, self.callback_OnRemoveBuff)
	UIControl.OnDestroy(self)
end

function BuffIconWidget:OnAddBuff(msg)
	if not self.isAwake then
		return
	end
    
    local hero = GetHero()
    if not hero then
        return
    end
    
    if tostring(msg.uidMaster) ~= tostring(hero:GetUID()) then
        return
    end
	
	local scheme = IGame.rktScheme:GetSchemeInfo(BUFF_CSV, msg.dwBuffID, msg.dwLevel)
	if not scheme then
		return
	end
	
	if not IGame.BuffClient:NeedShowIcon(scheme) then
		return
	end
	
	self:AddIcon(scheme.strSmallIconPath, msg.dwIndex)
end

function BuffIconWidget:AddIcon(path, buffIndex)
	if not path or path == "" then
		return
	end
	
	local curNum = 0
	for i = 1, max_icon_count do
		if self.iconList[i] ~= nil then
			curNum = curNum + 1
		else
			break
		end
	end
	
	if curNum >= max_icon_count then
		return
	end
	
	local UIIndex = curNum + 1
	UIFunction.SetImageSprite(self.Controls["m_Icon"..UIIndex], AssetPath.TextureGUIPath..path)
	self.Controls["m_Icon"..UIIndex].gameObject:SetActive(true)
    self.Controls["m_Frame"..UIIndex].gameObject:SetActive(true)
	self.iconList[UIIndex] = {buffIndex = buffIndex, UIIndex = UIIndex, path = path}
end

function BuffIconWidget:OnRemoveBuff(msg)
	if not self.isAwake then
		return
	end
    
    local hero = GetHero()
    if not hero then
        return
    end
    
    if tostring(msg.uidMaster) ~= tostring(hero:GetUID()) then
        return
    end
	
	self:RemoveIcon(msg.dwIndex)
end

function BuffIconWidget:RemoveIcon(buffIndex)
	local UIIndex = 0
	for i = 1, max_icon_count do
		if self.iconList[i] ~= nil and self.iconList[i].buffIndex == buffIndex then
			UIIndex = i
			break
		end
	end
	
	if UIIndex == 0 then
		return
	end
	
	-- 后面的图标前移，填充移除后的空位
	for i = UIIndex, max_icon_count do
		local nextIcon = self.iconList[i + 1]
		if nextIcon == nil then
			self.Controls["m_Icon"..i].gameObject:SetActive(false)
            self.Controls["m_Frame"..i].gameObject:SetActive(false)
			self.iconList[i] = nil
			break
		else
			UIFunction.SetImageSprite(self.Controls["m_Icon"..i], AssetPath.TextureGUIPath..nextIcon.path)
			self.Controls["m_Icon"..i].gameObject:SetActive(true)
            self.Controls["m_Frame"..i].gameObject:SetActive(true)
			self.iconList[i] = nextIcon
		end
	end
end

return BuffIconWidget