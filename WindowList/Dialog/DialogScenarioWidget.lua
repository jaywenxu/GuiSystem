------------------------------------------------------------
-- DialogModelWindow 的子窗口,不要通过 UIManager 访问
-- 剧情对话
------------------------------------------------------------

------------------------------------------------------------
local DialogScenarioWindget = UIControl:new
{
	windowName = "DialogScenarioWindget",
	m_npcid = 0,
	m_taskid = 0,
	m_linkstr = "",
	m_UIGameObject = nil,
	m_UIGameObjectID = 0,
}

local this = DialogScenarioWindget   -- 方便书写


------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function DialogScenarioWindget:Attach( obj )
	UIControl.Attach(self,obj)

	return self
end

function DialogScenarioWindget:OnDestroy()
	
	self:ClearCurGmaeObject()
end

-- 删除当前的object
function DialogScenarioWindget:ClearCurGmaeObject()
	
	if self.m_UIGameObject then
		self.m_UIGameObject:Destroy()
	end
	self.m_UIGameObject = nil
	self.m_UIGameObjectID = 0
end

function DialogScenarioWindget:SetParentWindow(win)
	self.m_ParentWindow = win
end

function DialogScenarioWindget:OnCloseWindow()

	self:ClearCurGmaeObject()
	self:ClearDialogInfo()
end

-- 显示NPC模型
function DialogScenarioWindget:DisplayNPC(npcid)
	
	local info = IGame.rktScheme:GetSchemeInfo(MONSTER_CSV,npcid)
	if not info then
		uerror("[DialogModelWidget]:DisplayNPC 找不到指定Npc: "..npcid)
		return false
	end
	-- 模型相同，不用再显示
	if self.m_UIGameObjectID == npcid then
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
    param.Name = "ScenarioModel"   --角色实例名字	
    param.Position = pos
	param.localScale  = scale  --因为使用canvas去绘制模型
	param.rotate = Vector3.New(0,nYAngle,0)	--模型旋转角度
	param.MoldeID =  info.lResID			--模型ID
	param.ParentTrs = self.Controls.m_ObjectDisplay.transform		--父节点
	param.UID = 1		-- UID
	
	self.m_UIGameObject = UICharacterHelp:new()
	self.m_UIGameObject:Create(param)
	self.m_UIGameObjectID  = npcid
end

-----------------------------------------------------------
-- 清空任务npc对话数据
function DialogScenarioWindget:ClearDialogInfo()

	self.m_npcid = 0
end
------------------------------------------------------------
-- 显示npc对白信息
function DialogScenarioWindget:ShowDialog(npcid,contentText)
	
	self.m_npcid = npcid
	local npcinfo = NPC_TABLE[npcid]	
	if not npcinfo then
		return
	end
	local musicid = npcinfo["music_id"]
	if musicid and musicid > 0 then
		-- 播放音乐
		-- playsound(musicid)
	end
		
	-- 显示npc默认对白
	self.Controls.NameText.text = tostring(npcinfo.name)
	
	local szName = GetHeroName() or ""
	-- 对白内容
	if contentText ~= nil and contentText ~= "" then
		self.Controls.DialogContent.text = "　　" .. string.gsub( contentText, "#hero#", szName )
	else
		if npcinfo["dialog"] ~= nil and npcinfo["dialog"][1] ~= nil then
			self.Controls.DialogContent.text = "　　" .. string.gsub( (tostring(npcinfo["dialog"][1]) or ""), "#hero#", szName )
		end
	end
	
	self:DisplayNPC(npcid)
	
end
------------------------------------------------------------

return this