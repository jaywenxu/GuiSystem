------------------------------------------------------------
-- DialogModelWindow 的子窗口,不要通过 UIManager 访问
-- 任务对话弹窗
------------------------------------------------------------

------------------------------------------------------------
local DialogModelWidget = UIControl:new
{
	windowName = "DialogModelWidget",
	SceneDialogTimes = 5000,	-- 对白间隔时间
	m_nCurDialogID = 0,			-- 当前任务对白id
	m_linkstr = "",				-- 当前任务对话完成link
	m_bSetTimer = false,
	m_nPreStartTime = 0,
	m_UIGameObject = nil,
	m_UIGameObjectID = 0,  -- -1标识为人，否则为怪物ID
}

local this = DialogModelWidget   -- 方便书写


------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function DialogModelWidget:Attach( obj )
	UIControl.Attach(self,obj)
	
	self.callBackTimer = function() self:OnDialogTimer() end
	
	-- 推进对白按钮
	self.callbackContinue = function() self:OnClickContinueButton() end
	self.Controls.ContinueBtn.onClick:AddListener(self.callbackContinue)
	
	return self
end

function DialogModelWidget:OnDestroy()
	self:KillSceneDialogTimer()
end

-----------------------------------------------------------
-- 设置父窗口
function DialogModelWidget:SetParentWindow(win)
	self.m_ParentWindow = win
end

-----------------------------------------------------------
-- 清空对白数据
function DialogModelWidget:ClearDialogInfo()
	
	self.m_nCurDialogID = 0			-- 当前任务对白id
	self.m_linkstr = ""				-- 当前任务对话完成link
	self.m_nPreStartTime = 0
	self.BeEnd = 0,					-- 是否结束对话 2:显示任务奖励框 DialogModelTaskPrizeWidget
	self:ClearCurGmaeObject()
end

-- 删除当前的object
function DialogModelWidget:ClearCurGmaeObject()
	
	if self.m_UIGameObject then
		self.m_UIGameObject:Destroy()
	end
	self.m_UIGameObject = nil
	self.m_UIGameObjectID = 0
end
-----------------------------------------------------------
-- 清空对白数据
function DialogModelWidget:OnClickContinueButton()

	local nCurTime = luaGetTickCount()
	if nCurTime - self.m_nPreStartTime < 200 then
		return
	end
	if self.m_nCurDialogID <= 0 then
		
		-- 如果需要显示任务奖励框
		if self.BeEnd and self.BeEnd == 2 then
			self:KillSceneDialogTimer()
			self:ClearDialogInfo()
			self.m_ParentWindow:showTaskPrizeWindow()
			return
		end

		-- 推进任务
		if not IsNilOrEmpty(self.m_linkstr) then
			GameHelp.PostServerRequest(self.m_linkstr)
			self.m_linkstr = ""
		end
		self:SceneDialogEnd()
	else
		-- 推进对白
		self:TaskSceneDialogProcess()
	end 
end

-----------------------------------------------------------
-- 任务对白结束
function DialogModelWidget:SceneDialogEnd()
	
	self:KillSceneDialogTimer()
	self:ClearDialogInfo()
	if self.m_ParentWindow then
		self.m_ParentWindow:HideDialogModel()
	end
end
------------------------------------------------------------
--删除任务对定时器
function DialogModelWidget:SetSceneDialogTimer()
	
	rktTimer.SetTimer(self.callBackTimer, self.SceneDialogTimes, -1, "DialogModelWidget:SetSceneDialogTimer")
	self.m_bSetTimer = true
end

------------------------------------------------------------
--删除任务对定时器
function DialogModelWidget:KillSceneDialogTimer()
	
	rktTimer.KillTimer( self.callBackTimer )
	self.m_bSetTimer = false
end

------------------------------------------------------------
-- 定时器响应
function DialogModelWidget:OnDialogTimer(e)
	
	-- 每次推进周器时间未到
	local nCurTime = luaGetTickCount()
	if (nCurTime - self.m_nPreStartTime < self.SceneDialogTimes) then
		return
	end
	
	-- 推进对白
	self:TaskSceneDialogProcess()
end

------------------------------------------------------------
-- 推进对白
function DialogModelWidget:TaskSceneDialogProcess()
	
	if self.m_nCurDialogID <= 0 then
		self:KillSceneDialogTimer()
		return
	end
	local pSchemeInfo = IGame.rktScheme:GetSchemeInfo(SCENEDIALOG_CSV, self.m_nCurDialogID)
	if not pSchemeInfo then
		self:KillSceneDialogTimer()
		return
	end

	self.m_nCurDialogID = pSchemeInfo.nNextDialogID or 0
	local nEndFlag = pSchemeInfo.nBeEnd or 0
	if self.m_nCurDialogID <= 0 or nEndFlag == 1 then
		self:KillSceneDialogTimer()
		return
	end

	self:ShowCurSceneDialogInfo(self.m_nCurDialogID)
	
end

------------------------------------------------------------
-- 显示当前对白ID信息
function DialogModelWidget:ShowCurSceneDialogInfo(nCurDialogID)
	
	local pSchemeInfo = IGame.rktScheme:GetSchemeInfo(SCENEDIALOG_CSV, nCurDialogID)
	if not pSchemeInfo then
		self:KillSceneDialogTimer()
		return
	end
	self.m_nPreStartTime = luaGetTickCount()
	self:SetTaskFormNPCType(pSchemeInfo)
	
	local szHeroName = GetHeroName() or ""
	self.Controls.ContextText.text = string.gsub(pSchemeInfo.strDialog , "#hero#",  szHeroName)
end



-- 显示NPC模型
function DialogModelWidget:DisplayNPC(NpcID)
	
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
	local pos = Vector3.New( (ptPos.x or -560),(ptPos.y or -100),(ptPos.z or -200))
	local scale = Vector3.New((tmpScale.xscale or 320),(tmpScale.yscale or 320),(tmpScale.zscale or 320))
	local nYAngle = pSchemeInfo.fYAngle or 180
	
	local param = {}
	param.entityClass = tEntity_Class_Monster
    param.layer = "UI"  -- 角色所在层
    param.Name = "DialogModel"   --角色实例名字
    param.Position = pos
	param.localScale  = scale  --因为使用canvas去绘制模型
	param.rotate = Vector3.New(0,nYAngle,0)	--模型旋转角度
	param.MoldeID =  info.lResID			--模型ID
	param.ParentTrs = self.Controls.m_ObjectDisplay.transform		--父节点
	param.UID = 1		-- UID
	
	self.m_UIGameObject = UICharacterHelp:new()
	self.m_UIGameObject:Create(param)
	self.m_UIGameObjectID = NpcID
	self.Controls.TaskNameText.text = info.szName

end



--展示模型
function DialogModelWidget:ShowModel(npcid,nVocation,resID)
	
	local param = {}
	local ResID = nil
	local disModel = UICharacterHelp:new()
	if nVocation == nil and resID == nil then 
		return
	end 
	local actorlist = IGame.FormManager:GetActorList()	
	local formatData = nil
	if npcid ~= nil then 
		ResID =resID
		param.entityClass = tEntity_Class_Monster
		param.nVocation = nil
		
		local pSchemeInfo = IGame.rktScheme:GetSchemeInfo(CONFIGRESOURCE, ResID)
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
			-- 显示npc模型
		end
		local pos = Vector3.New( (ptPos.x or -560),(ptPos.y or -100),(ptPos.z or -200))
		local scale = Vector3.New((tmpScale.xscale or 320),(tmpScale.yscale or 320),(tmpScale.zscale or 320))
		local nYAngle = pSchemeInfo.fYAngle or 180
		param.localScale  = scale  --因为使用canvas去绘制模型
		param.rotate = Vector3.New(0,nYAngle,0)	--模型旋转角度
	else
		ResID = gEntityVocationRes[nVocation]
		param.entityClass = tEntity_Class_Person
		param.nVocation = nVocation
		for i ,data in pairs(actorlist) do
			if data.nProfession == nVocation then
				formatData = data.formatData
				break
			end
		end
		param.localScale  =  DIALOG_ROLE_MODEL_SCALE_POS[nVocation]  --因为使用canvas去绘制模型
		param.rotate = DIALOG_ROLE_MODEL_ROTATE[nVocation]	--模型旋转角度
		param.Position =DIALOG_ROLE_MODEL_POS[nVocation]
	end
	param.layer = "UI"  -- 角色所在层
	param.UID = -1		
	param.ParentTrs = self.Controls.m_ObjectDisplay.transform	
	param.formInfo = formatData
	param.MoldeID = ResID
    param.Name = "DialogModel"   --角色实例名字
	self.m_UIGameObject = UICharacterHelp:new()
	self.m_UIGameObject:Create(param)
end

-- 显示玩家模型实体
function DialogModelWidget:DisplayPlayer(nYAngle)
	
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
	local hero =GetHero()
	if hero == nil then 
		return
	end
	local nvoctaion = hero:GetNumProp(CREATURE_PROP_VOCATION)
	self:ShowModel(nil,nvoctaion,nil)
end

------------------------------------------------------------
-- 显示当前对白ID信息
function DialogModelWidget:SetTaskFormNPCType(pSchemeInfo)
	
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
function DialogModelWidget:ShowSceneDialog(npcid,dialog_content,dialog_id,linkstr)
	
	self.m_linkstr = linkstr
	if dialog_id <= 0 then
		self.m_nPreStartTime = luaGetTickCount()
		self.m_nCurDialogID = 0
		self:DisplayNPC(npcid)
		local szName = GetHeroName() or ""
		self.Controls.ContextText.text = string.gsub( tostring(dialog_content or ""), "#hero#", szName)
		return
	end
	
	self.m_nCurDialogID = dialog_id
	local pSchemeInfo = IGame.rktScheme:GetSchemeInfo(SCENEDIALOG_CSV, self.m_nCurDialogID)
	if not pSchemeInfo then
		return
	end
	self.BeEnd = pSchemeInfo.nBeEnd
	self:ShowCurSceneDialogInfo(self.m_nCurDialogID)
	if pSchemeInfo.nNextDialogID > 0 then
		if self.m_bSetTimer then
			self:KillSceneDialogTimer()
		end
		self:SetSceneDialogTimer()
	else
		self.m_nCurDialogID = 0
	end
end

------------------------------------------------------------
-- 跳过当前对白，推进任务
function DialogModelWidget:SkipDialog()
    self.m_nCurDialogID = 0
    self.m_nPreStartTime = 0
    self:OnClickContinueButton()
end
------------------------------------------------------------

return this