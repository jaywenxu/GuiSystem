-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    刘翠立
-- 日  期:    2017/02/15
-- 版  本:    1.0
-- 描  述:    滴答Cell
-------------------------------------------------------------------

local DidaItemCell = UIControl:new
{
    windowName = "DidaItemCell" ,
	DidaSeq = nil,
}

local mName = "【滴答Cell】，"


------------------------------------------------------------
function DidaItemCell:Attach( obj )
	UIControl.Attach(self,obj)

    self.Controls.ItemToggle = self.transform:GetComponent(typeof(Toggle))
	self.callback_OnBtnDidaDoClick = function() self:OnBtnDidaDoClick() end
	self.Controls.m_DidaDo.onClick:RemoveListener( self.callback_OnBtnDidaDoClick )
	self.Controls.m_DidaDo.onClick:AddListener(self.callback_OnBtnDidaDoClick)
	
    return self
end

------------------------------------------------------------
--点击“前往”按钮
function DidaItemCell:OnBtnDidaDoClick()
	local DidaObj = IGame.DidaClassManager:GetObjBySeq(self.DidaSeq)
	print("[DidaItemCell]OnBtnDidaDoClick^^^^^^^^^^^^^DidaObj^^^^^",DidaObj,self.DidaSeq)
    if DidaObj == nil then
        uerror("[DidaItemCell]OnBtnDidaDoClick======DidaObj is nil!!! =========")
		UIManager.DidaWindow:RefreshDidaWindow()
        return
    end
	if IGame.DidaClassManager:MssageDidaDoClick(self.DidaSeq) ~= false then
		self:OnRecycle()
		UIManager.DidaWindow:OnBtnCloseClick()
	end
end

------------------------------------------------------------
-- 设置滴答唯一序列号
function DidaItemCell:SetDidaSeq(Sequence)
	self.DidaSeq = Sequence
end

------------------------------------------------------------
--设置标题
function DidaItemCell:SetTitleText(Text)
	self.Controls.m_Dida_Title.text = tostring(Text)
end

------------------------------------------------------------
--设置内容
function DidaItemCell:SetContentText(Text)
	self.Controls.m_Dida_Content.text = tostring(Text)
end
------------------------------------------------------------
function DidaItemCell:OnDestroy()
	self:OnRecycle()
	UIControl.OnDestroy(self)
end

function DidaItemCell:OnRecycle()
	self.DidaSeq = nil
	self.Controls.m_DidaDo.onClick:RemoveListener( self.callback_OnBtnDidaDoClick )
end

function DidaItemCell:SetToggleGroup( toggleGroup )
    self.Controls.ItemToggle.group = toggleGroup
end

return DidaItemCell




