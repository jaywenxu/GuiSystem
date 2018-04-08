--*****************************************************************
--** 文件名:	DamageRankItem.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-12-22
--** 版  本:	1.0
--** 描  述:	伤害统计单元
--** 应  用:  
--******************************************************************

local DamageRankItem = UIControl:new
{
	windowName	= "DamageRankItem",
}

function DamageRankItem:Attach(obj)
	UIControl.Attach(self, obj)
	
end

function DamageRankItem:SetItemInfo(nRank)
	local tData = IGame.DamageRankClient:GetDamageObj(nRank)
	if not tData then
		return
	end
	
	local controls = self.Controls
	controls.m_Rank.text = tostring(nRank)
	controls.m_ClanName.text = tostring(tData.szName)
	controls.m_Damage.text = tostring(tData.nDamage)
end

return DamageRankItem