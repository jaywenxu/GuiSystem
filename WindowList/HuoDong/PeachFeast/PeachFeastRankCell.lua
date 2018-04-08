
--------------------------------------------------------------------------------
-- 版  权:    (C)深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    lj.zhou
-- 日  期:    2017.06.27
-- 版  本:    1.0
-- 描  述:    蟠桃盛宴排行榜单元
--------------------------------------------------------------------------------

local NormalTxtsColor   = Color.New(0.32,0.48,0.52)		--正常字体颜色
local SelectedTxtsColor = Color.New(0,1,0,1)					--选中字体颜色

local PeachFeastRankItem = UIControl:new
{
	windowName = "PeachFeastRankItem",
}

function PeachFeastRankItem:Attach(obj)
	
	UIControl.Attach(self, obj)
	
end

function PeachFeastRankItem:SetItemInfo(idx, ItemData)

	local controls = self.Controls
	controls.m_Rank.text = tostring(idx)
	
	controls.m_ClanName.text = tostring(ItemData.szClanName)
	
	controls.m_ClanScore.text = tostring(ItemData.dwScore)
	
	local nClanID = GetHero():GetNumProp(CREATURE_PROP_CLANID)
	if nClanID == ItemData.dwClanID then
		--self:SetTxtsColor(SelectedTxtsColor)
	else
		--self:SetTxtsColor(NormalTxtsColor)
	end
end

function PeachFeastRankItem:SetTxtsColor(color)
	local texts = self.transform:GetComponentsInChildren(typeof(Text))
	for i = 0 , texts.Length - 1 do 
		texts[i].color = color
	end
end

return PeachFeastRankItem









