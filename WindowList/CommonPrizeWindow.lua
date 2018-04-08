------------------------------------------------------------
-- author by fcc
-- 任务奖励提示弹窗
------------------------------------------------------------

------------------------------------------------------------

local PrizeGridCellClass = require( "GuiSystem.WindowList.Task.TaskPrizeGridCell" )

local CommonPrizeWindow = UIWindow:new
{
	windowName = "CommonPrizeWindow",
    m_openInfo = nil ,
	m_linkstr = "",				-- 当前任务对话完成link
	m_UIGameObject = nil,
	m_UIGameObjectID = 0,  -- -1标识为人，否则为怪物ID
	m_rewardCellObj = {},
	m_prizeCell = {},
}

local this = CommonPrizeWindow   -- 方便书写

function CommonPrizeWindow:Init()
	
end

------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function CommonPrizeWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	
	self.Controls.m_AcceptButton.onClick:AddListener( function() self:OnAcceptButtonCallback() end )
	self.Controls.m_CloseButton.onClick:AddListener( function() self:OnCloseButtonCallback() end )
	
	for i = 1,4 do
		local rewardCellObj = self.Controls.m_rewardGrid.transform:Find("MainTaskWin_RewardGoods_Cell" .. i).gameObject
		rewardCellObj:SetActive(false)
		self.m_prizeCell[i] = PrizeGridCellClass:new()
		self.m_prizeCell[i]:Attach(rewardCellObj)
		self.m_rewardCellObj[i] = rewardCellObj
	end

    if nil ~= self.m_openInfo then
        local info = self.m_openInfo
        self:ShowSceneDialog( info.npcid , info.linkstr , info.taskInfo )
    end
end

function CommonPrizeWindow:OnDestroy()
	
end

------------------------------------------------------------
-- 操作需要在 OnAttach 之后进行的操作
function CommonPrizeWindow:OnNeedAwakeAfter()
	
end

function CommonPrizeWindow:OnAcceptButtonCallback()

	-- 推进任务
	if not IsNilOrEmpty(self.m_linkstr) then
		GameHelp.PostServerRequest(self.m_linkstr)
		self.m_linkstr = ""
	end
	self:SceneDialogEnd()
	
end

function CommonPrizeWindow:OnCloseButtonCallback()
	self:SceneDialogEnd()
end

-----------------------------------------------------------
-- 清空对白数据
function CommonPrizeWindow:ClearDialogInfo()
	self.m_linkstr = ""				-- 当前任务对话完成link
	self:ClearCurGmaeObject()
end

-- 删除当前的object
function CommonPrizeWindow:ClearCurGmaeObject()
	
	if self.m_UIGameObject then
		self.m_UIGameObject:Destroy()
	end
	self.m_UIGameObject = nil
	self.m_UIGameObjectID = 0
end

-----------------------------------------------------------
-- 任务对白结束
function CommonPrizeWindow:SceneDialogEnd()
	self:ClearDialogInfo()
	self:HideDialogModel()
end

-- 显示NPC模型
function CommonPrizeWindow:DisplayNPC(NpcID)
	
	local info = IGame.rktScheme:GetSchemeInfo(MONSTER_CSV,NpcID)
	if not info then
		uerror("[DialogModelWidget]:DisplayNPC 找不到指定Npc: "..NpcID)
		return false
	end
	
	-- 模型相同，不用再显示
	if self.m_UIGameObjectID == NpcID then
		return
	else
		self:ClearCurGmaeObject()
	end
	
	local pSchemeInfo = IGame.rktScheme:GetSchemeInfo(CONFIGRESOURCE, info.lResID)
	if not pSchemeInfo then
		return nil
	end
	local ptPos = {}
	if pSchemeInfo.fPos then
		ptPos = 
		{
			x = pSchemeInfo.fPos[1],
			y = pSchemeInfo.fPos[2],
			z = pSchemeInfo.fPos[3],
		}
	end
	local tmpScale = {}
	if pSchemeInfo.scale then
		tmpScale = 
		{
			xscale = pSchemeInfo.scale[1],
			yscale = pSchemeInfo.scale[2],
			zscale = pSchemeInfo.scale[3],
		}
	end
	
	-- 显示npc模型
	local pos = Vector3.New( 0,0,(ptPos.z or -200))
	local scale = Vector3.New((tmpScale.xscale or 320),(tmpScale.yscale or 320),(tmpScale.zscale or 320))
	local nYAngle = pSchemeInfo.fYAngle or 180
	
	local param = {}
	param.entityClass = tEntity_Class_Monster
    param.layer = "UI"  -- 角色所在层
    param.Name = "DialogModel"   --角色实例名字
    param.Position = pos
	param.localScale  = scale * 0.5  --因为使用canvas去绘制模型
	param.rotate = Vector3.New(0,nYAngle,0)	--模型旋转角度
	param.MoldeID =  info.lResID			--模型ID
	param.ParentTrs = self.Controls.m_ObjectDisplay.transform		--父节点
	param.UID = 1		-- UID
	
	self.m_UIGameObject = UICharacterHelp:new()
	self.m_UIGameObject:Create(param)
	self.m_UIGameObjectID = NpcID
end


-- 显示玩家模型实体
function CommonPrizeWindow:DisplayPlayer(nYAngle)
	
	local pHero = IGame.EntityClient:GetHero()
	if not pHero then
		return false
	end
	self.Controls.TaskNameText.text = pHero:GetName()
	-- 显示玩家模型
	if self.m_UIGameObjectID == -1 then
		return
	else
		self:ClearCurGmaeObject()
	end
	self.m_UIGameObjectID = -1
end

------------------------------------------------------------
-- 显示当前对白ID信息
function CommonPrizeWindow:SetTaskFormNPCType(pSchemeInfo)
	
	if not pSchemeInfo then
		return 
	end
	if pSchemeInfo.nNpcID > 0 then
		self:DisplayNPC(pSchemeInfo.nNpcID)
	else
		self:DisplayPlayer(pSchemeInfo.nYAngle)
	end
end

-- 显示对白
function CommonPrizeWindow:ShowSceneDialog(npcid,linkstr,taskInfo )

    if not self:isLoaded() then
        self.m_openInfo = { npcid = npcid , linkstr = linkstr , taskInfo = taskInfo }
        return
    end

	self.Controls.ContextText.text = "　　" .. tostring(taskInfo.description or "")
	self.Controls.TitleText.text = tostring(taskInfo.name or "")
	self:DisplayNPC(npcid)
	self.m_linkstr = linkstr
	
	local taskPrize = taskInfo.prize_array
	local exp = taskInfo.prize_exp or 0
	local yinbi = taskInfo.yinbi or 0
	local yinliang = taskInfo.yinliang or 0
	
	self:hidePrizeIcon()
	-- 显示经验、银币、银两奖励
	local i = 1
	if exp > 0 then
		self.m_rewardCellObj[i]:SetActive(true)
		self.m_prizeCell[i]:SetPrizeInfoEx(9001,exp)
		i = i + 1
	end
	
	if yinbi > 0 then
		self.m_rewardCellObj[i]:SetActive(true)
		self.m_prizeCell[i]:SetPrizeInfoEx(9004,yinbi)
		i = i + 1
	end
	
	if yinliang > 0 then
		self.m_rewardCellObj[i]:SetActive(true)
		self.m_prizeCell[i]:SetPrizeInfoEx(9003,yinliang)
		i = i + 1
	end
	
	if taskPrize == nil or taskPrize == "" then
		return
	end
	-- 显示物品奖励
	local tPrize = split_string(taskPrize,";",tonumber)
	for k,v in pairs(tPrize) do
		if (k + i - 1) > 4 then
			return
		end
		self.m_rewardCellObj[k + i - 1]:SetActive(true)
		self.m_prizeCell[ k + i - 1]:SetPrizeInfo(v)
	end
end

-- 隐藏所有的奖励图标
function CommonPrizeWindow:hidePrizeIcon()
	for i = 1,4 do
		self.m_rewardCellObj[i]:SetActive(false)
	end
end

------------------------------------------------------------
-- 关闭奖励窗口
function CommonPrizeWindow:HideDialogModel()
	if self:isLoaded() then
		self:Hide()
	end
    self:ShowHudWindow(true)
end

------------------------------------------------------------

return this