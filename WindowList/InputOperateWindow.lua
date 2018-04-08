------------------------------------------------------------
local InputOperateWindow = UIWindow:new
{
	windowName = "InputOperateWindow" ,
	
	tOtherOperBtnData = nil,
}
------------------------------------------------------------

------------------------------------------------------------
function InputOperateWindow:Init()
    self.callback_OnMainRightBottomWindowShow = function() self:OnMainRightBottomWindowShow() end
	self.callback_UpdateGuaJi = function(event, srctype, srcid, eventData) self:OnUpdateGuajiState(event, srctype, srcid, eventData) end
end
------------------------------------------------------------
function InputOperateWindow:OnAttach( obj )

	UIWindow.OnAttach(self,obj,UIManager._InputEventLayer)

    self.m_MoveJoyStick = require("GuiSystem.WindowList.InputOperate.MoveJoyStick"):new()
    self.m_MoveJoyStick:Attach( self.Controls.m_MoveJoyStick.gameObject )

    self.m_InputEventLayer = require("GuiSystem.WindowList.InputOperate.InputEventLayer")
    self.m_InputEventLayer.Attach(self.transform.gameObject)

    self.m_SkillAttackButtons = require("GuiSystem.WindowList.InputOperate.SkillButtonJoySticks"):new()
    self.m_SkillAttackButtons:Attach(self.Controls.m_SkillButtonJoySticks.gameObject)

    self.m_OtherOperBtnSkicks = require("GuiSystem.WindowList.InputOperate.OtherOperBtnSticks"):new()
    self.m_OtherOperBtnSkicks:Attach(self.Controls.m_OtherOperBtnSticks.gameObject, self.tOtherOperBtnData)
	self.tOtherOperBtnData = nil
	
	self.m_QingGongButtons = require("GuiSystem.WindowList.InputOperate.QingGongButtonJoysticks"):new()
	self.m_QingGongButtons:Attach(self.Controls.m_QingGongButtons.gameObject)
    
    rktEventEngine.SubscribeExecute(EVENT_MAIN_RIGHT_BOTTOM_WINDOW_SHOW_OR_HIDE, SOURCE_TYPE_SYSTEM, 0, self.callback_OnMainRightBottomWindowShow)
    rktEventEngine.SubscribeExecute( EVENT_FOLLOW_MOVE_REASON , 0 , JOY_STICK_ID.MoveControl , self.callback_UpdateGuaJi )
	
    return self
end

------------------------------------------------------------
-- 关闭触屏输入事件
-- @param:
--      isDisable  ：是否关闭
function InputOperateWindow:DisableInputs(isDisable)
    self.Controls.m_InputShieldMask.gameObject:SetActive(isDisable)

    self.m_MoveJoyStick:SetActive(not isDisable)
end

-- 获取其它输入事件层
function InputOperateWindow:GetOtherOpBtnSkicks()
   return self.m_OtherOperBtnSkicks
end

-- 获取技能攻击层
function InputOperateWindow:GetSkillAttaBtnWdt()
   return self.m_SkillAttackButtons
end

-- 刷新挂机按钮状态
function InputOperateWindow:OnUpdateGuajiState(event, srctype, srcid, eventData)
	if not self:isLoaded() then
		return
	end
   self.m_SkillAttackButtons:UpdateVisible()
end

------------------------------------------------------------
function InputOperateWindow:OnDestroy()
    rktEventEngine.UnSubscribeExecute(EVENT_MAIN_RIGHT_BOTTOM_WINDOW_SHOW_OR_HIDE, SOURCE_TYPE_SYSTEM, 0, self.callback_OnMainRightBottomWindowShow)
    rktEventEngine.UnSubscribeExecute( EVENT_FOLLOW_MOVE_REASON , 0 , JOY_STICK_ID.MoveControl , self.callback_UpdateGuaJi )
	self.m_QingGongButtons:OnDestroy()
	self.m_QingGongButtons = nil
	
    UIWindow.OnDestroy(self)
    self.m_InputEventLayer.OnDestroy()
end

------------------------------------------------------------
function InputOperateWindow:Show( bringTop)
    UIWindow.Show(self, bringTop)

    self:ShowBasedOnMainRightBottomWindow()
end

-- 获取轻功按钮组
function InputOperateWindow:GetQingGongButtonsWidget()
	return self.m_QingGongButtons
end

-- 隐藏移动摇杆
function InputOperateWindow:HideMoveJoystick(isHide)
    if not self.m_MoveJoyStick then
        return
    end
    
	if not self.m_MoveJoyStick:isLoaded() then
		return
	end
	
	if isHide then
		self.m_MoveJoyStick:Hide()
	else
		self.m_MoveJoyStick:Show()
	end
end

-- 显示技能区域按钮
function InputOperateWindow:ShowSkillButtonArea()
	
	--切换到技能状态				TODO
	--[[local skillWidget = self:GetSkillAttaBtnWdt()
	if skillWidget ~= nil then
		skillWidget:SetStateView(1)
	end--]]
	
    local skillWidget = self:GetSkillAttaBtnWdt()
    if skillWidget ~= nil then
        skillWidget:Show()
        skillWidget:CheckQingGongButtonImageRefreshOnAttach()
    end
	
    --[[if self:IsShowQingGongButtons() then
        local skillWidget = self:GetSkillAttaBtnWdt()
        if skillWidget ~= nil then
            skillWidget:Hide()
        end
        
        local QingGongWidget = self:GetQingGongButtonsWidget()
        if QingGongWidget ~= nil then
            QingGongWidget:Show()
        end
		
		
		
    else
        local skillWidget = self:GetSkillAttaBtnWdt()
        if skillWidget ~= nil then
            skillWidget:Show()
        end
        
        local QingGongWidget = self:GetQingGongButtonsWidget()
        if QingGongWidget ~= nil then
            QingGongWidget:Hide()
        end
		
		--切换到
    end--]]
end

-- 隐藏技能区域按钮
function InputOperateWindow:HideSkillButtonArea()
    local skillWidget = self:GetSkillAttaBtnWdt()
    if skillWidget ~= nil then
        skillWidget:Hide()
    end
    
    --[[local QingGongWidget = self:GetQingGongButtonsWidget()
    if QingGongWidget ~= nil then
        QingGongWidget:Hide()
    end--]]
end

-- 更新轻功气力值
function InputOperateWindow:UpdateQingGongStrength(curStrength, maxStrength)
    local skillWidget = self:GetSkillAttaBtnWdt()
    if skillWidget ~= nil then
        skillWidget:UpdateQingGongStrength(curStrength, maxStrength)
    end
end

-- 功能区显示隐藏
function InputOperateWindow:OnMainRightBottomWindowShow()
    self:ShowBasedOnMainRightBottomWindow()
end

-- 根据功能区决定如何显示自己，例如：
-- 功能区显示菜单，则自己要隐藏技能区
-- 功能区不显示菜单，则自己要显示出技能区
-- 功能区隐藏了，则自己要显示出技能区
function InputOperateWindow:ShowBasedOnMainRightBottomWindow()
    local state = UIManager.MainRightBottomWindow:GetSwitchState()
    local visible = UIManager.MainRightBottomWindow:IsVisibleByConfig()
    if not visible then
        self:ShowSkillButtonArea()
    else
        if state then
            self:HideSkillButtonArea()
        else
            self:ShowSkillButtonArea()
        end
    end
end

-- 设置技能区的显示状态
function InputOperateWindow:SetSkillAreaStateView(state)
    local skillWidget = self:GetSkillAttaBtnWdt()
    if skillWidget ~= nil then
        skillWidget:SetStateView(state)
    end
end

-- 隐藏挂机按钮
function InputOperateWindow:ShowGuaJiButton(isShow)
    local skillWidget = self:GetSkillAttaBtnWdt()
    if skillWidget ~= nil then
        skillWidget:ShowGuaJiButton(isShow)
    end
end

-- 显示特殊操作按钮
function InputOperateWindow:ShowOtherOperBtn(tData)
	
	if not self:isLoaded() then
		self.tOtherOperBtnData = tData
		return
	end
	
	self.m_OtherOperBtnSkicks:ShowOperBtn(tData)
end

-- 隐藏特殊操作按钮
function InputOperateWindow:HideOtherOperBtn()
	
	if not self:isLoaded() then
		self.tOtherOperBtnData = nil
		return
	end
	
	self.m_OtherOperBtnSkicks:HideOperBtn()
end

-- 添加轻功禁用原因
function InputOperateWindow:AddQingGongForbidUseReason(strReason)
    local skillWidget = self:GetSkillAttaBtnWdt()
    if skillWidget ~= nil then
        skillWidget:AddQingGongForbidUseReason(strReason)
    end
end

-- 移除轻功禁用原因
function InputOperateWindow:RemoveQingGongForbidUseReason(strReason)
    local skillWidget = self:GetSkillAttaBtnWdt()
    if skillWidget ~= nil then
        skillWidget:RemoveQingGongForbidUseReason(strReason)
    end
end

-- 是否有技能按钮处于冷却中
function InputOperateWindow:IsSkillButtonsInCooling()
    local skillWidget = self:GetSkillAttaBtnWdt()
    if skillWidget ~= nil then
        return skillWidget:IsSkillButtonsInCooling()
    end
    
    return false
end

-- 切换技能显示方案
function InputOperateWindow:SwitchSkillAreaPlan(plan)
    local skillWidget = self:GetSkillAttaBtnWdt()
    if skillWidget ~= nil then
        return skillWidget:SwitchSkillAreaPlan(plan)
    end
end

-- 获取技能显示方案
function InputOperateWindow:GetSkillAreaPlan()
    local skillWidget = self:GetSkillAttaBtnWdt()
    if skillWidget ~= nil then
        return skillWidget:GetSkillAreaPlan()
    end
    
    return gSkillAreaPlan.Normal
end

------------------------------------------------------------
return InputOperateWindow