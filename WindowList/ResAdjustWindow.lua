--*******************************************************************
--** 文件名:	ResAdjustWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	何水大
--** 日  期:	2017-07-26
--** 版  本:	1.0
--** 描  述:	等级封印
--** 应  用:  
--*******************************************************************

local ResAdjustWindow = UIWindow:new
{
	windowName  = "ResAdjustWindow",
	m_strContent = "在封印解除前，达到等级封印上限的玩家将不能提升人物等级，但可以继续积累经验。封印解除后，方可继续升级。",
}

function ResAdjustWindow:OnAttach(obj)
	UIWindow.OnAttach(self, obj)	

	UIFunction.AddEventTriggerListener( self.Controls.m_Close , EventTriggerType.PointerClick , function() self:OnCloseBtnClick() end )
    self:ShowUI()
end

function ResAdjustWindow:ShowUI()
	if not self:isLoaded() then
        return
    end

	local controls = self.Controls
	-- 等级封印描述
	controls.m_txtContent.text = self.m_strContent
	local curLevel = IGame.ResAdjustClient:GetLvCivilGrade()
	local levelText = {}
	levelText[1] = "当前: 封印一"
	levelText[2] = "当前: 封印二"
	levelText[3] = "当前: 封印三"
	levelText[4] = "当前: 封印四"
	levelText[5] = "当前: 封印五"
	levelText[6] = "当前: 封印六"
	levelText[7] = "当前: 封印七"
	
	controls.m_txtLvCivilGrade.text = levelText[curLevel]
	controls.m_txtLevelLimit.text  = IGame.ResAdjustClient:GetLevelLimit()
	
	local day = IGame.ResAdjustClient:GetLvCivilGradeLeftDay()
	day = day or 0
	if day > 0 then
		controls.m_txtLvCivilGradeLeftDay.text = day .. "天"
	else
		controls.m_txtLvCivilGradeLeftDay.text = "已冲破所有封印"
	end

	controls.m_txtExpUpRatio.text = IGame.ResAdjustClient:GetExpUpRatio() .. "%"
end

function ResAdjustWindow:OnCloseBtnClick()
	self:Hide()
end

function ResAdjustWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end

return ResAdjustWindow


