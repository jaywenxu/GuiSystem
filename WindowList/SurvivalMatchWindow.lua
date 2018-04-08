local SurvivalMatchWindow = UIWindow:new
{
	windowName = "SurvivalMatchWindow" ,
	m_Data = {}
}
	
---------------------------------------------------------------
function SurvivalMatchWindow:Init()

end
---------------------------------------------------------------
function SurvivalMatchWindow:OnAttach( obj )    
	UIWindow.OnAttach(self,obj)
	
	self.Controls.m_DanRenBtn.onClick:AddListener(handler(self, self.OnDanRenSignClick))
	self.Controls.m_DuoRenBtn.onClick:AddListener(handler(self, self.OnDuoRenSignClick))
	self.Controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnCloseButtonClick))
	self:Update(self.nStartTime)
	self:RefreshUI(self.m_Data)
end

function SurvivalMatchWindow:OnDisable()
	
end

function SurvivalMatchWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end

function SurvivalMatchWindow:Update(nBeginTime)
	self.nStartTime = nBeginTime	
	if not self:isLoaded() then
		return
	end	
	if IGame.TeamClient:GetTeamID() ~= INVALID_TEAM_ID then
		if self.nStartTime == nil then
			UIFunction.SetImageSprite(self.Controls.m_DuoRenImage, AssetPath.TextureGUIPath.."Achivement/Achievement_xianshi.png")
		else
			UIFunction.SetImageSprite(self.Controls.m_DuoRenImage, AssetPath.TextureGUIPath.."Achivement/Achievement_yincang.png")
		end
		UIFunction.SetImageSprite(self.Controls.m_DanRenImage, AssetPath.TextureGUIPath.."Achivement/Achievement_xianshi.png")
	else
		if self.nStartTime == nil then
			UIFunction.SetImageSprite(self.Controls.m_DanRenImage, AssetPath.TextureGUIPath.."Achivement/Achievement_xianshi.png")
		else
			UIFunction.SetImageSprite(self.Controls.m_DanRenImage, AssetPath.TextureGUIPath.."Achivement/Achievement_yincang.png")
		end
		UIFunction.SetImageSprite(self.Controls.m_DuoRenImage, AssetPath.TextureGUIPath.."Achivement/Achievement_xianshi.png")
	end
end

function SurvivalMatchWindow:OnDanRenSignClick()
	if self.nStartTime == nil then
		GameHelp.PostServerRequest("RequestPubgSingleSignup()")
	else
		GameHelp.PostServerRequest("RequestPubgSingleSignupCancle()")
	end
end

function SurvivalMatchWindow:OnDuoRenSignClick()
	if self.nStartTime == nil then
		GameHelp.PostServerRequest("RequestPubgTeamSignup()")
	else
		GameHelp.PostServerRequest("RequestPubgTeamSignupCancle()")
	end
end

-- 关闭按钮
function SurvivalMatchWindow:OnCloseButtonClick() 
	self:Hide()
end

function SurvivalMatchWindow:RefreshUI(tTemp)
	if tTemp == nil then
		return
	end
	self.m_Data = tTemp
	if not self:isLoaded() then
		return
	end
	local szMsg = "最好名次："..tTemp.wEctypeRank
					.."\n吃鸡次数："..tTemp.dwWinCount
					.."\n击杀人数："..tTemp.dwKillCount
					.."\n参与次数："..tTemp.dwEctypeCount
	self.Controls.m_Info.text = szMsg
end

return SurvivalMatchWindow
