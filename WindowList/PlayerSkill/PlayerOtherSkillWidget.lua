--/******************************************************************
---** 文件名:	PlayerOtherSkillWidget.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	林春波
--** 日  期:	2017-06-03
--** 版  本:	1.0
--** 描  述:	玩家技能窗口-其他技能窗口
--** 应  用:  
--******************************************************************/

local PlayerOtherSkillWidget = UIControl:new
{
	windowName 	= "PlayerOtherSkillWidget",
}

function PlayerOtherSkillWidget:Attach(obj)
	
	UIControl.Attach(self,obj)
	
end

-- 显示窗口
function PlayerOtherSkillWidget:ShowWindow()
	
	UIControl.Show(self)
	--self.transform.gameObject:SetActive(true)
	
end

-- 隐藏窗口
function PlayerOtherSkillWidget:HideWindow()
	
	UIControl.Hide(self, false)
	--self.transform.gameObject:SetActive(false)
	
end

return PlayerOtherSkillWidget