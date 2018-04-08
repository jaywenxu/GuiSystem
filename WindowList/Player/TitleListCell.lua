-- 称号列表子项
------------------------------------------------------------
local TitleListCell = UIControl:new
{
	windowName = "TitleListCell" ,
	m_TitleID = nil,
}
------------------------------------------------------------
function TitleListCell:Attach( obj )
	UIControl.Attach(self,obj)
	self.callbackOnApplyButtonClick = function() self:OnSelectButtonClick() end
	self.Controls.m_SelectBtn.onClick:AddListener(self.callbackOnApplyButtonClick)
	return self
end


function TitleListCell:OnRecycle()
	self.Controls.m_SelectBtn.onClick:RemoveListener(self.callbackOnApplyButtonClick)
	UIControl.OnRecycle(self)
end

------------------------------------------------------------
function TitleListCell:RefreshCellUI(nTitleID, bShow, bHad)
	m_TitleID = nTitleID
	if not bHad then
		self.Controls.m_SelectBtn.gameObject:SetActive(false)		
		self.Controls.m_NotGetImage.gameObject:SetActive(true)
	else
		self.Controls.m_SelectBtn.gameObject:SetActive(true)		
		self.Controls.m_NotGetImage.gameObject:SetActive(false)
		if bShow then
			UIFunction.SetImageSprite(self.Controls.m_ShowImage, AssetPath.TextureGUIPath.."Title/Achievement_yincang.png")
		else
			UIFunction.SetImageSprite(self.Controls.m_ShowImage, AssetPath.TextureGUIPath.."Title/Achievement_xianshi.png")
		end
	end
	local tTitleCfg = IGame.rktScheme:GetSchemeInfo(TITLE_CSV, m_TitleID)
	if tTitleCfg == nil then
		return
	end
	self.Controls.m_HowGetText.text = "<color=#597993>"..tTitleCfg.szDesc.."</color>"
	UIFunction.SetImageSprite(self.Controls.m_TitleImage, AssetPath.TextureGUIPath..tTitleCfg.szImage)
end

function TitleListCell:OnDestroy()
	self.Controls.m_SelectBtn.onClick:RemoveListener(self.callbackOnApplyButtonClick)
	UIControl.OnDestroy(self)
end

-- 显示或者隐藏称号
function TitleListCell:OnSelectButtonClick()
	IGame.TitleClient:SelectGeneralTitle(self.m_TitleID)
end

------------------------------------------------------------
return TitleListCell
