-- 单个联系人ceil元素
-- @Author: LiaoJunXi
-- @Date:   2017-07-27 9:16:21
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-07-27 12:05:08

local LinkmanCeil = UIControl:new
{
	windowName         = "LinkmanCeil",

	m_OnAvatarClickCallback = nil,
	m_AvatarCallback = nil,
	
	m_OnToggleCeilCallback = nil,
	m_SelectedCallback = nil,
	
	m_SelCellIdx  	   = 0
}

local this = LinkmanCeil

function LinkmanCeil:Attach( obj )
	UIControl.Attach(self, obj)

	-- 点击CEIL
	self.m_OnToggleCeilCallback = function(on) self:OnSelectChanged(on) end
    local toggle = self.transform:GetComponent(typeof(Toggle))
	toggle.onValueChanged:AddListener(self.m_OnToggleCeilCallback)
	self.Controls.toggle = toggle
	
	-- 点击AVATAR
	self.m_OnAvatarClickCallback = function() self:OnAvatarBtnClicked() end
	self.Controls.m_AvatarBtn.onClick:AddListener(self.m_OnAvatarClickCallback)
	
	-- 显示控件
	local tweener = self.transform:GetComponent(typeof(DOTweenAnimation))
	self.Controls.tweener = tweener
end

-- 设置ceil数据到显示
--[[struct tagFriendInfo
{
	DWORD           m_version;                          // 数据版本号
	int             m_pdbid;                            // 玩家角色ID	
	WORD            m_faceID;                           // 玩家头像ID
	BYTE			m_vocation;							// 玩家职业ID
	tchar           m_name[MAX_PERSONNAME_LEN];         // 玩家的名字
	DWORD			m_power;							// 玩家战斗力
	int				m_level;							// 玩家等级
	BYTE            m_business[MAX_BUSINESSICON_QTY];   // 业务图标
	BYTE			m_btHeadTitleID;					// 玩家头衔
	DWORD			clanID;								// 取帮会ID
	tchar			m_szClanName[CLAN_NAME_LEN];		// 帮会名
	BYTE			m_btOnline;							// 是否在线
	BYTE			byFriendDivideRelation;				// 好友之间的关系(分组)
	BYTE			byFriendPowerRelation;				// 好友之间的权限关系
	DWORD			dwContactTime;						// 最近联系时间
}--]]
function LinkmanCeil:SetCellData(idx, data)
	--print(debug.traceback("LinkmanCeil:SetCellData("..idx..")"))
	if not data then return end
	local controls = self.Controls

	controls.m_TitleTxt.text = ""
	if UIFunction.SetCellHeadTitle(data.m_btHeadTitleID, controls.m_Title, controls) then
		local pos = Vector3.New(131, 30, 0)
		controls.m_NameTxt.transform.localPosition = pos
	else
		local pos = Vector3.New(37, 30, 0)
		controls.m_NameTxt.transform.localPosition = pos
	end
	controls.m_NameTxt.text = data.m_name
	controls.m_LevTxt.text = data.m_level.."级"
	controls.m_JobTxt.text = GameHelp.GetVocationName(data.m_vocation)
	
	--print(controls.m_JobTxt.text.."("..data.m_name..")".."say: data.m_faceID = "..data.m_faceID)
--[[	if PERSON_VOCATION_LINGXIN == data.m_vocation then
		data.m_faceID = 2
	elseif data.m_faceID == 31 then
		data.m_faceID = 1
	end--]]
	UIFunction.SetHeadImage(controls.m_Avatar,data.m_faceID)
	--controls.m_Avatar:SetNativeSize()
	local nWindow = UIManager.FriendEmailWindow
	UIFunction.SetImageGray(controls.m_Avatar, data.m_btOnline ~= 1)

	self.m_SelCellIdx = idx
end

-- 显示红点
function LinkmanCeil:ShowOrHideRedDot (status)
	if nil == status then
		status = false
	end
	--print(debug.traceback(self.transform.gameObject.name.. "-><color=red>LinkmanCeil:ShowOrHideRedDot.state="..tostring(status).."</color>"))
	UIFunction.ShowRedDotImg(self.transform,status)
end

-- 设置选中回调
function LinkmanCeil:SetSelectCallback( func_cb )
	self.m_SelectedCallback = func_cb
end

-- 设置点中头像框回调
function LinkmanCeil:SetAvatarCallback( func_cb )
	self.m_AvatarCallback = func_cb
end

-- 设置toggle group
function LinkmanCeil:SetToggleGroup(toggleGroup)
    self.Controls.toggle.group = toggleGroup
end

-- 设置toggle group
function LinkmanCeil:SetToggleIsOn(on)
	local tgl = self.Controls.toggle
	if tgl ~= nil then
    	tgl.isOn = on
    end
end

-- 点击Ceil
function LinkmanCeil:OnSelectChanged(on)
	if nil ~= self.m_SelectedCallback and on then
		self.m_SelectedCallback(self.m_SelCellIdx)
	end
	self:ShowOrHideRedDot(false)
end

-- 点击头像ICON
function LinkmanCeil:OnAvatarBtnClicked()
	self.m_AvatarCallback(self.m_SelCellIdx)
end

function LinkmanCeil:OnBtnCloseClicked()
	self:Hide()
end

function LinkmanCeil:OnRecycle()
	self.Controls.toggle.onValueChanged:RemoveListener(self.m_OnToggleCeilCallback)
	self.Controls.m_AvatarBtn.onClick:RemoveListener(self.m_OnAvatarClickCallback)
	
	if self.Controls.headTitleCell then
		self.Controls.headTitleCell:Recycle()
	end
	
	self.m_SelectedCallback = nil

	UIControl.OnRecycle(self)

	table_release(self)
end

function LinkmanCeil:Disappear()
	--print("LinkmanCeil:Disappear()")
	self.Controls.tweener:DOPlayBackwards()
end

function LinkmanCeil:Appear()
	--print(debug.traceback("LinkmanCeil:Appear()"))
	self.Controls.tweener:DORestart(true)
end

function LinkmanCeil:OnDestroy()
	self.m_OnToggleCeilCallback = nil
	self.m_OnAvatarClickCallback = nil
	self.m_SelectedCallback = nil
	UIControl.OnDestroy(self)

	table_release(self)
end

return LinkmanCeil