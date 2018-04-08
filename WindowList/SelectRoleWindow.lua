------------------------------------------------------------
local SelectRoleWindow = UIWindow:new
{
	windowName = "SelectRoleWindow" ,
	
	m_CurActorName = "",
	m_deleteName = "",
	m_curCreateRoleName = "",
}
local this = SelectRoleWindow   -- 方便书写

------------------------------------------------------------
function SelectRoleWindow:Init()
	self.SelectRoleWidget = require("GuiSystem.WindowList.SelectRole.SelectRoleWidget")
end
------------------------------------------------------------
function SelectRoleWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	self.SelectRoleWidget:Attach( self.Controls.SelectRoleWidget.gameObject )
	self.SelectRoleWidget:SetParentWindow(self)
	self.calbackBackButtonClick = function() self:OnBackButtonClick() end
	self.Controls.m_backBtn.onClick:AddListener( self.calbackBackButtonClick )
	
	-- 注册按钮事件有两种方式，上面的为一种，下面的为另一种 RoleDeletePasswordField 为UIWindowBehavior
	-- 进入游戏
	self.callbackContinueButtonClick = function() self:OnEnterGameClick() end
	self.Controls.m_EnterGameButton.onClick:AddListener( self.callbackContinueButtonClick )

	-- 删除当前角色
	self.calbackDeleteCurRoleClick = function() self:OnDeleteCurRoleClick() end
	self.Controls.m_DeleteCurRoleButton.onClick:AddListener( self.calbackDeleteCurRoleClick )
	
	-- 删除角色确认按钮
	self.calbackRoleDeleteClick = function() self:OnRoleDeleteClick() end
	self.Controls.m_DeleteRoleCheckButton.onClick:AddListener( self.calbackRoleDeleteClick )
	
	-- 取消删除按钮
	self.calbackSelectAreaClick = function() self:OnCancelRoleDeleteClick() end
	self.Controls.m_CancelDeleteButton.onClick:AddListener( self.calbackSelectAreaClick )
	
	-- 创建角色随机名字按钮
	self.calbackRandomNameClick = function() self:OnRandomNameClick() end
	self.Controls.m_RandomNameButton.onClick:AddListener( self.calbackRandomNameClick )	
	
	-- 创建角色按钮
	self.calbackCreateRoleClick = function() self:OnCreateRoleClick() end
	self.Controls.m_CreateRoleButton.onClick:AddListener( self.calbackCreateRoleClick )	
	
	--关闭删除窗口
	 self.CloseDeleteWind = function() self:OnCloseDeleteWind() end
	 self.Controls.m_closeDeleteBtn.onClick:AddListener( self.CloseDeleteWind )	
	
	self.Controls.m_closeDeleteBtnBg.onClick:AddListener( self.CloseDeleteWind )	
	if self.m_needRefreshOnLoad then
		self.m_needRefreshOnLoad = false		
		self.SelectRoleWidget:RefreshCellItems()
	end
	--SelectRoleWindow:setSceCameraToOrthoGragphic()
	self:playMusic()
    return self
end


function SelectRoleWindow:Show(toTop)
	if self:isLoaded() then 	
		self:playMusic()
	end
	UIWindow.Show(self,toTop)
end

function SelectRoleWindow:Hide(destory)
	UIWindow.Hide(self,destory)

end
------------------------------------------------------------
function SelectRoleWindow:OnDestroy()
	if self.SelectRoleWidget then
		self.SelectRoleWidget:OnDestroy()
	end
    self.m_deleteName = ""

	UIWindow.OnDestroy(self)
end

--播放音效
function SelectRoleWindow:playMusic()
	if self.bMusicPlaying then 
        return
	end
    self.bgMusic = SoundHelp.PlayMusicByConfigID(SELECTROLE_BG_AUDIO_ID)
    self.bMusicPlaying = true
end

--停止播放音效
function SelectRoleWindow:stopMusic()
    if not self.bMusicPlaying then
        return
    end
    if not IGame.rktScheme:GetSchemeInfo(SOUND_CSV,SELECTROLE_BG_AUDIO_ID) then
        SoundHelp.StopMusicByConfigID(LOGIN_BG_AUDIO_ID)
    else
        SoundHelp.StopMusicByConfigID(SELECTROLE_BG_AUDIO_ID)
    end
	self.bgMusic = nil
    self.bMusicPlaying = false
end

function SelectRoleWindow:OnCloseDeleteWind()
	self:ShowDeleteDialogWindow(false)
    self.m_deleteName = ""
end

------------------------------------------------------------
-- 返回
function SelectRoleWindow:OnBackButtonClick()
    self.m_deleteName = ""
	IGame.CommonClient:BackToSelectServer()
end

------------------------------------------------------------
-- 开始游戏
function SelectRoleWindow:OnEnterGameClick()
	
	LoginApi_OnEnterGame(self.m_CurActorName)
end

------------------------------------------------------------
-- 更新数据
function SelectRoleWindow:UpdateActorInfo()

	local actorlist = IGame.FormManager:GetActorList()
	
	if actorlist == nil then
		return
	end
	for i ,data in pairs(actorlist) do
		self.m_CurActorName= data.szActorName
		if self.m_CurActorName == self.m_curCreateRoleName then
			self.m_curCreateRoleName = ""
			self:OnEnterGameClick()
			return
		end
	end

	if not self:isLoaded() then
		self.m_needRefreshOnLoad = true
        return
    end

	self.SelectRoleWidget:RefreshCellItems()
end

------------------------------------------------------------
function SelectRoleWindow:DestroySceneCamera()
	
	
end

------------------------------------------------------------
function SelectRoleWindow:SetCurActorName(szName)	
	self.m_CurActorName = szName or ""
end
------------------------------------------------------------
function SelectRoleWindow:IsInActorList(szName)	
	if IsNilOrEmpty(szName) then
		return false
	end
	local actorlist = IGame.FormManager:GetActorList()
	
	if actorlist == nil then
		return false
	end
	for i ,data in pairs(actorlist) do
		if szName == data.szActorName then
			return true
		end
	end
	return false
end

------------------------------------------------------------
function SelectRoleWindow:SetDeleteActorName(szName)
	self.m_deleteName = szName
end

------------------------------------------------------------
function SelectRoleWindow:GetDeleteActorName()
	return self.m_deleteName
end

------------------------------------------------------------
-- 响应删除角色成功
function SelectRoleWindow:OnResponseDeleteActor()
    if not IsNilOrEmpty(self.m_deleteName) and not self:IsInActorList(self.m_deleteName) then
        UIManager.ChatSystemTipsWindow:AddSystemTips("删除角色成功")
        self.m_deleteName = ""
		return
	end
end

------------------------------------------------------------
-- 显示或隐藏删除角色对话框窗口
function SelectRoleWindow:ShowDeleteDialogWindow(bShow)
	if not bShow then
		bShow = false
	else
		bShow = true
	end
	self.Controls.m_RoleDeleteDialog.gameObject:SetActive(bShow)	
end

------------------------------------------------------------
-- 删除当前角色
function SelectRoleWindow:OnDeleteCurRoleClick()
	self:ShowDeleteDialogWindow(true)
	self:SetDeleteActorName(self.m_CurActorName)
end

------------------------------------------------------------
-- 删除角色
function SelectRoleWindow:OnRoleDeleteClick()
	
	local szText = self.Controls.RoleDeletePasswordField:GetComponent(typeof(InputField)).text
	-- string.upper和string.lower 
	-- 暂时先改成小写判断，字符匹配忽略大小写
	if not szText or string.upper(szText) ~= "LONGWU" then
        UIManager.ChatSystemTipsWindow:AddSystemTips("输入的确认信息不匹配")
		return
	end
	if not self:IsInActorList(self.m_CurActorName) then
        UIManager.ChatSystemTipsWindow:AddSystemTips("删除的角色名不再角色列表中")
		return
	end
	-- 删除角色
	IGame.SelectActorForm:DeleteActor(self.m_CurActorName)
	
	self:ShowDeleteDialogWindow(false)
	self.m_CurActorName = ""
	self.Controls.RoleDeletePasswordField:GetComponent(typeof(InputField)).text = ""
end

------------------------------------------------------------
-- 取消删除角色
function SelectRoleWindow:OnCancelRoleDeleteClick()
	
    self:SetDeleteActorName("")
	self:ShowDeleteDialogWindow(false)
end

------------------------------------------------------------
-- 随机角色名字按钮
function SelectRoleWindow:OnRandomNameClick()
	local nVocation = self.m_curVocation
	if not gDefaultVocationRoleCfg[nVocation] then
		return
	end	
	local nSex = gDefaultVocationRoleCfg[nVocation].sex		-- 0男性，1女性
	IGame.SelectActorForm:RequestRandName(nSex)
end

------------------------------------------------------------
-- 创建角色按钮
function SelectRoleWindow:OnCreateRoleClick()
	
	local nVocation = self.m_curVocation
	if not gDefaultVocationRoleCfg[nVocation] then
		return
	end
	-- 先暂时这么填，职业0,2,3 已经有模板，1没有模板

	local nSex = gDefaultVocationRoleCfg[nVocation].sex		-- 0男性，1女性
	local strActorName = self.Controls.CreateRoleName:GetComponent(typeof(InputField)).text
	if IsNilOrEmpty(strActorName) then
		UIManager.CommonNoticeWindow:Show(true)
        UIManager.CommonNoticeWindow:ShowNotice("请输入创建的角色名")
		return
	end 
	if utf8.wchar_size(strActorName) > 12  then
		UIManager.CommonNoticeWindow:Show(true)
        UIManager.CommonNoticeWindow:ShowNotice("输入的角色名过长，请重新输入")
		return
	end
	
	-- 创建角色名有屏蔽字，不能修改
	if StringFilter.FilterKeyWord(strActorName) then
		UIManager.CommonNoticeWindow:Show(true)
        UIManager.CommonNoticeWindow:ShowNotice("角色名含有屏蔽字，请重新输入！")
		return
	end
	-- 创建角色有屏蔽字，不能修改
	if StringFilter.CheckMoreSpaceStr(strActorName, 1) then
		UIManager.CommonNoticeWindow:Show(true)
        UIManager.CommonNoticeWindow:ShowNotice("角色名含有空格，请重新输入！")
		return
	end
	
	self.m_curCreateRoleName = strActorName
	local pIconCfg = gDefaultVocationHeadCfg[nVocation]
	local nFaceID = 1
	-- 选择默认头像
	if pIconCfg then
		if pIconCfg[nSex] == 0 then
			nFaceID = pIconCfg.maleIcon
		else
			nFaceID = pIconCfg.femaleIcon
		end
	end	
	IGame.SelectActorForm:CreateActor(nVocation,nSex,nFaceID,strActorName)
	-- 提示窗口显示则关闭窗口
	if UIManager.CommonNoticeWindow:isShow() then
		UIManager.CommonNoticeWindow:Hide()
	end
end

------------------------------------------------------------
-- 创建角色按钮
function SelectRoleWindow:UpdateCurVocationInfo(nVocation)
	if not gDefaultVocationRoleCfg[nVocation] then
		return
	end
	local imagePath = gDefaultVocationRoleCfg[nVocation].imagePath
	UIFunction.SetImageSprite( self.Controls.m_VocationImage , imagePath )
	self.Controls.m_VocationText1.text = tostring(gDefaultVocationRoleCfg[nVocation].attackMode)
	self.Controls.m_VocationText2.text = tostring(gDefaultVocationRoleCfg[nVocation].attDesc)
end

------------------------------------------------------------
function SelectRoleWindow:UpdateCurRole(nVocation,nCurRoleName)
	self.m_curVocation = nVocation
	self:SetCurActorName(nCurRoleName)
	self:UpdateCurVocationInfo(nVocation)
	-- 没有角色，需要显示创建角色按钮，隐藏进入游戏删除角色按钮
	if IsNilOrEmpty(self.m_CurActorName) then
		self.Controls.m_CreateRoleBg.gameObject:SetActive(true)
		self.Controls.m_EnterGameBg.gameObject:SetActive(false)
		self.Controls.m_DeleteCurRoleButton.gameObject:SetActive(false)
	else
		self.Controls.m_CreateRoleBg.gameObject:SetActive(false)
		self.Controls.m_EnterGameBg.gameObject:SetActive(true)
		self.Controls.m_DeleteCurRoleButton.gameObject:SetActive(true)
		self.Controls.m_CurRoleNane.text = tostring(self.m_CurActorName)
	end
end
------------------------------------------------------------
-- 刷新创建角色名字
function SelectRoleWindow:RefeshCreateRoleName(szName)
	if not self:isLoaded() then
		return
	end
	self.Controls.CreateRoleName:GetComponent(typeof(InputField)).text = szName or  ""
end

------------------------------------------------------------
return this
