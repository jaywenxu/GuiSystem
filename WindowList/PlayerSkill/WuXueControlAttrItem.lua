--/******************************************************************
---** 文件名:	WuXueControlAttrItem.lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	林春波
--** 日  期:	2017-07-12
--** 版  本:	1.0
--** 描  述:	武学界面操作面板的属性图标
--** 应  用:  
--******************************************************************/

local WuXueControlAttrItem = UIControl:new
{
	windowName 	= "WuXueControlAttrItem",
}

function WuXueControlAttrItem:Attach(obj)
	
	UIControl.Attach(self,obj)
	
end

-- 更新图标
-- @upgradeAttrInfo:升级的属性数据:WuXueUpgradeAttr
function WuXueControlAttrItem:UpdateItem(upgradeAttrInfo)
	
	if upgradeAttrInfo.m_ActiveLevel > 0 then
		local desc = GameHelp:GetPropDesc(upgradeAttrInfo.m_AttrId, upgradeAttrInfo.m_NextAttrVal)
		self.Controls.m_TextAttrLeft.text = desc or ""
        self.Controls.m_TextAttrLeft.color = UIFunction.ConverRichColorToColor("818384")
		self.Controls.m_jihuoText.text = string.format("%d级激活",upgradeAttrInfo.m_ActiveLevel)
		self.Controls.m_jihuoText.gameObject:SetActive(true)
		self.Controls.m_TfArrow.gameObject:SetActive(false)
		self.Controls.m_TextAttrRight.gameObject:SetActive(false)
		self.Controls.m_leftText.sizeDelta =Vector2.New(305,self.Controls.m_leftText.sizeDelta.y) 
	else 
		local isMaxLevel = upgradeAttrInfo.m_NextAttrVal == 0
		local desc = GameHelp:GetPropDesc(upgradeAttrInfo.m_AttrId, upgradeAttrInfo.m_CurAttrVal)
		self.Controls.m_TextAttrLeft.text = desc or ""
		local desc = GameHelp:GetPropDescOnValue(upgradeAttrInfo.m_AttrId, upgradeAttrInfo.m_NextAttrVal)
		self.Controls.m_TextAttrRight.text = desc or ""
		self.Controls.m_TextAttrLeft.color = UIFunction.ConverRichColorToColor("597993")
		self.Controls.m_jihuoText.gameObject:SetActive(false)
		self.Controls.m_TfArrow.gameObject:SetActive(not isMaxLevel)
		self.Controls.m_TextAttrRight.gameObject:SetActive(not isMaxLevel)
		if isMaxLevel ==true then 
			self.Controls.m_leftText.sizeDelta =Vector2.New(580,self.Controls.m_leftText.sizeDelta.y) 
		else
			self.Controls.m_leftText.sizeDelta =Vector2.New(305,self.Controls.m_leftText.sizeDelta.y) 
		end
	end
	
end

return WuXueControlAttrItem
