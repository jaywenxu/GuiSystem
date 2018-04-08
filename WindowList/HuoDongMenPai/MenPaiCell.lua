-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    方称称
-- 日  期:    2017/06/22
-- 版  本:    1.0
-- 描  述:    门派入侵cell
-------------------------------------------------------------------

local MenPaiCell = UIControl:new
{
	windowName = "MenPaiCell",
	m_parent,
	m_pos = {},
	m_clickHandler = nil,
}

local this = MenPaiCell

function MenPaiCell:Attach(obj)
	UIControl.Attach(self,obj)
	self.m_clickHandler = handler(self, self.clickCallback)
	self.Controls.m_btn.onClick:AddListener( self.m_clickHandler )
end

--点击
function MenPaiCell:clickCallback()
	if self.m_parent then
		self.m_parent:hideWindow()
	end
	local pHero = IGame.EntityClient:GetHero()
	if not IGame.EntityFactory:StopMove(pHero:GetUID()) then
		return
	end
	MoveTo(self.m_pos.mapId,self.m_pos.x,self.m_pos.y,self.m_pos.z,3)
end

function MenPaiCell:OnDestroy()
	UIControl.OnDestroy(self)
end

function MenPaiCell:SetCellData(data, idx)
    if idx%2 == 1 then
        self.Controls.m_bg.gameObject:SetActive(true)
    else
        self.Controls.m_bg.gameObject:SetActive(false)
    end
	self.m_pos.mapId = data.mapId
	self.m_pos.x = data.x
	self.m_pos.y = data.y
	self.m_pos.z = data.z
	
	self.Controls.m_mapNameTxt.text = data.mapName
	self.Controls.m_remainNumTxt.text = "剩余" .. data.remainNum
end

function MenPaiCell:SetParent(parent)
	self.m_parent = parent
end

function MenPaiCell:OnRecycle()
	self.Controls.m_btn.onClick:RemoveListener( self.m_clickHandler )
	UIControl.OnRecycle(self)
end

return this
