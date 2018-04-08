--在我的队伍窗口显示角色的信息
------------------------------------------------------------
local MyTeamRoleCell = UIControl:new
{
	windowName = "MyTeamRoleCell" ,
	index = nil,						--索引
	m_IsLeader = false,					--是否为队长
	m_dbID = nil,
	m_parent = nil ,
	m_position = Vector3.New(0,0,0),
}
local headTitleClass = require("GuiSystem.WindowList.Team.MyTeamInviteFriendCell")
------------------------------------------------------------
function MyTeamRoleCell:Attach( obj )
	UIControl.Attach(self,obj)
	
	self.callbackOnEnable = function() self:OnEnable() end
	self.unityBehaviour.onEnable:AddListener(self.callbackOnEnable) 
	
	self.callbackOnDisable = function() self:OnDisable() end
	self.unityBehaviour.onDisable:AddListener(self.callbackOnDisable) 
	self.ClickModel =function() self:OnClickModel() end
	self.Controls.m_clickModel.onClick:AddListener(self.ClickModel) 
	return self
end



------------------------------------------------------------
function MyTeamRoleCell:OnDestroy()
	UIControl.OnDestroy(self)
end
------------------------------------------------------------

function MyTeamRoleCell:SetClickClass(Class)
	self.WidegtClass = Class
end

function MyTeamRoleCell:OnClickModel()
	local nPDBID = GetHero():GetNumProp(CREATURE_PROP_PDBID)
	if self.m_dbID == nil or nPDBID == self.m_dbID then 
		return
	end
			--当玩家头像被点击时，创建点击面板 队长点击面板和队员点击面板不一样
	UIManager.TeamShowPanelLeaderClickWindow:InitInfo(self.m_dbID,self.index ,2)
	UIManager.TeamShowPanelLeaderClickWindow:Show(true)
	

	
end

--------------------------------------------------------------
--回收资源
function MyTeamRoleCell:DeleteARoleCell()
	rkt.GResources.RecycleGameObject(self.transform.gameObject)
end
--------------------------------------------------------------
--为这个RoleCell 设置一个模型
--formInfo 是外观信息
function MyTeamRoleCell:DisplayAModel(Mid,nvocation,formInfo)
	if self.UICharacterHelp ~= nil then 
		self.UICharacterHelp:Destroy()
	end
	local param = 
	{
		entityClass = tEntity_Class_Person,
		layer = UNITY_LAYER_NAME.EntityGUI , 									-- 角色所在层
		Name = "EntityModel" ,  									--角色实例名字	
		Position = TEAM_ROLE_MODLE_POSITION[self.index ],
		localScale  = TEAM_ROLE_MODLE_SCALE, 		--因为使用canvas去绘制模型
		rotate = Vector3.New(0,0,0),
		MoldeID = Mid,									--模型ID
		ParentTrs =self.m_parent,						--父节点
		targetUID = nil,  								-- 此为拷贝的对象，若没有则不需填
		UID =15,
	}
	param.UID = GUI_ENTITY_ID_TEAM[self.index]
	param.formInfo =formInfo 
	param.nVocation = nvocation
	self.UICharacterHelp = UICharacterHelp:new()
	local isCreate = self.UICharacterHelp:Create( param )
	if not isCreate then
		print("Failed")
		return
	end
end

function MyTeamRoleCell:InitIndex(i)
	self.index = i
end
------------------------------------------------------------
function MyTeamRoleCell:OnEnable() 
	local MyTeam = IGame.TeamClient:GetTeam()
	if self.m_dbID~= nil then 
		local memberInfo = MyTeam:GetMemberInfo(self.m_dbID)
		
		if nil ~= memberInfo then 
			local formInfo = MyTeam:GetMemberFormData(self.m_dbID)
			self:DisplayAModel(gEntityVocationRes[memberInfo.nVocation],memberInfo.nVocation,formInfo)
		end
	
	end
end

function MyTeamRoleCell:ShowAutoTips(state)
	if self.m_dbID == nil then  
		self.Controls.m_autoTips.gameObject:SetActive(state)
	end
end

------------------------------------------------------------
function MyTeamRoleCell:OnDisable() 
	if nil ~= self.UICharacterHelp then
		self.UICharacterHelp:Destroy()
		self.UICharacterHelp = nil
	end
end


function MyTeamRoleCell:ShowLeader(State)
	
	self.Controls.m_leaderTrs.gameObject:SetActive(State)
	
end
------------------------------------------------------------
function MyTeamRoleCell:OnRecycle()
	
	self.unityBehaviour.onEnable:RemoveListener(self.callbackOnEnable) 
	self.unityBehaviour.onDisable:RemoveListener(self.callbackOnDisable) 
	UIControl.OnRecycle(self)
end
--------------------------------------------------------------

function MyTeamRoleCell:OnUpdate(memberInfo,ParentTrs)
    local MyTeam = IGame.TeamClient:GetTeam()
    if MyTeam == nil then return end 
    
	if memberInfo ~= nil then
		self.Controls.m_topTrs.gameObject:SetActive(true)
		self.Controls.m_bottomTrs.gameObject:SetActive(true)
		self.Controls.m_NameText.text = memberInfo.szName
		self.Controls.m_LevelText.text = "等级："..tostring(memberInfo.nLevel)
		self.Controls.m_CultivationText.text = "修为："..tostring(memberInfo.nXiuWei)
		self.Controls.m_autoTips.gameObject:SetActive(false)
		UIFunction.SetImageSprite(self.Controls.m_ClassesImage,GuiAssetList.gProfessionIcon[memberInfo.nVocation])
		
		self.setHeadCallBack = function() self:SetHeadCallBack() end
		local success = UIFunction.SetCellHeadTitle(memberInfo.nHeadTitleID,self.Controls.m_headTitle,self.Controls,self.setHeadCallBack)
		if success ==true then

		else
			if self.Controls["headTitleCell"] ~= nil then 
				self.Controls["headTitleCell"].transform.gameObject:SetActive(false)
			end
		end
		
		self.m_dbID = memberInfo.dwPDBID
		self.m_parent = ParentTrs
		self:ShowLeader(memberInfo.bCaptainFlag)
		local pTeam = IGame.TeamClient:GetTeam()
		if pTeam then
			local formInfo = MyTeam:GetMemberFormData(memberInfo.dwPDBID)
			self:DisplayAModel(gEntityVocationRes[memberInfo.nVocation],memberInfo.nVocation,formInfo)
		end
	else
		self.Controls.m_topTrs.gameObject:SetActive(false)
		self.Controls.m_bottomTrs.gameObject:SetActive(false)
		if self.UICharacterHelp ~= nil then 
			self.UICharacterHelp:Destroy()
			
		end
		self.m_dbID = nil
	end
end

function MyTeamRoleCell:SetHeadCallBack()
	if self.Controls["headTitleCell"] ~= nil then 
		self.Controls["headTitleCell"].transform:SetAsFirstSibling()
		self.Controls["headTitleCell"].transform.gameObject:SetActive(true)
	end
	
end

return MyTeamRoleCell