--/******************************************************************
---** 文件名:	HeadIcon.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	haowei
--** 日  期:	2017-08-30
--** 版  本:	1.0
--** 描  述:	施法目标
--** 应  用:  
--******************************************************************/

local HeadIcon = UIControl:new
{
	windowName = "HeadIcon",
	
	m_UID = 0,
    m_PDBID = 0,
	
	enterCB = nil, 
	exitCB = nil,
}

function HeadIcon:Attach(obj)
	UIControl.Attach(self,obj)
	
	return self
end

function HeadIcon:Show()
	UIControl.Show(self)
	self:SetSelect(false)
end

--获取UID
function HeadIcon:GetUID()
	return self.m_UID
end

--设置UID
function HeadIcon:SetUID(uid)
	self.m_UID = uid
end

-- 设置PDBID
function HeadIcon:SetPDBID(pdbid)
    self.m_PDBID = pdbid
end

-- 获取PDBID
function HeadIcon:GetPDBID()
    return self.m_PDBID
end

--设置是否是队长
function HeadIcon:SetCaptain(enabled)
	self.Controls.m_CaptainIcon.gameObject:SetActive(enabled)
end

--设置血量
function HeadIcon:SetHP(percent, showWarning)
	self.Controls.m_HP.fillAmount = percent
	if showWarning then
		if percent <= 0.5 then
			self.Controls.m_Warning.gameObject:SetActive(true)
		else
			self.Controls.m_Warning.gameObject:SetActive(false)
		end
	else
		self.Controls.m_Warning.gameObject:SetActive(false)
	end
end

--设置头像
function HeadIcon:SetHeadIcon(faceID)
	UIFunction.SetHeadImage(self.Controls.m_HeadIcon,faceID)
end

--设置选中状态
function HeadIcon:SetSelect(selected)
	self.Controls.m_Select.gameObject:SetActive(selected)
end

--设置警告
function HeadIcon:SetWarning(enabled)
	self.Controls.m_Warning.gameObject:SetActive(enabled)
end

--设置鼠标进入事件
function HeadIcon:SetPointEnterCB(enter_callback)
	self.enterCB = enter_callback
	 UIFunction.AddEventTriggerListener( self.transform , EventTriggerType.PointerEnter , self.enterCB)
end

--设置鼠标移出事件
function HeadIcon:SetPointExitCB(exit_callback)
	self.exitCB = exit_callback
	UIFunction.AddEventTriggerListener( self.transform , EventTriggerType.PointerExit , self.exitCB)
end

--移除所有监听的事件 
function HeadIcon:RemoveAllListener()
	UIFunction.RemoveEventTriggerListener(self.transform, EventTriggerType.PointerEnter, self.enterCB)
	UIFunction.RemoveEventTriggerListener(self.transform, EventTriggerType.PointerExit, self.exitCB)
end

return HeadIcon