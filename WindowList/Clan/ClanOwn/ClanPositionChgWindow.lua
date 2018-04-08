-- 帮派职位变更界面
-- @Author: XieXiaoMei
-- @Date:   2017-04-18 09:36:19
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-08-24 18:05:08

local ClanPositionChgWindow = UIWindow:new
{
	windowName        = "ClanPositionChgWindow",

	m_Member = nil,
	m_SelTitleIdx = 0,
}

local TitleToggles = -- 职位toggls
{
	Host    = 1,
	SubHost = 2,
	Elder   = 3,
	Peterxs = 4,
	Elite   = 5,
	Mass    = 6,
	Captain = 7,
}

local pos = ClanSysDef.ClanPositions
local tlg = TitleToggles
local TitleServerMap = -- toggle与服务器宏对应映射 popedom：职位权限ID，identify: 职位标记
{
	[tlg.Host]    = { popedom = emClanPopedom_AppointShaikh, 	identify = pos.Host },
	[tlg.SubHost] = { popedom = emClanPopedom_AppointUnderboss, identify = pos.SubHost }, 
	[tlg.Elder]   = { popedom = emClanPopedom_AppointElder, 	identify = pos.Elder }, 
	[tlg.Peterxs] = { popedom = emClanPopedom_AppointDM, 		identify = pos.Peterxs },
	[tlg.Elite]   = { popedom = emClanPopedom_AppointElite, 	identify = pos.Elite },
	[tlg.Mass]    = { popedom = -1, 							identify = pos.Mass },
	[tlg.Captain] = { popedom = emClanPopedom_AppointCaptain , 	identify = pos.Captain },
}

------------------------------------------------------------
function ClanPositionChgWindow:Init()
end


function ClanPositionChgWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)

	local controls = self.Controls

	controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	controls.m_BackBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	controls.m_AppointBtn.onClick:AddListener(handler(self, self.OnBtnAppointClicked))

	local Toggles = {
		controls.m_HostTgl,
		controls.m_SubHostTgl,
		controls.m_ElderTgl,
		controls.m_PeterxsTgl,
		controls.m_EliteTgl,
		controls.m_MassTgl,
		controls.m_CaptainTgl,
	}
	controls.Toggles = Toggles

	for i, tgl in ipairs(Toggles) do
		tgl.onValueChanged:AddListener(function ()
			self:OnTogglesChanged(i)
		end)
	end

	rktEventEngine.SubscribeExecute( EVENT_CLAN_UPDATEMEMBER, SOURCE_TYPE_CLAN, 0, self.OnMemberUpdateEvt, self )

	self:RefreshUI()
end


function ClanPositionChgWindow:ShowWindow(member)
	
	-- 数据赋值优先
	-- 在OnAttach中使用数据时可能还没有初始化
	self.m_Member = member
	
	UIWindow.Show(self)
	
	if not self:isLoaded() then
		return
	end

	self:RefreshUI()
end

function ClanPositionChgWindow:OnDestroy()
	rktEventEngine.UnSubscribeExecute( EVENT_CLAN_UPDATEMEMBER , SOURCE_TYPE_CLAN, 0, self.OnMemberUpdateEvt, self )

	UIWindow.OnDestroy(self)

	table_release(self)
end

-- 界面刷新
function ClanPositionChgWindow:RefreshUI()
	local controls = self.Controls
	local clanPosStrs = ClanSysDef.ClanPositionStrs
	local posCurCntPropIDs = ClanSysDef.PosCurCntPropIDs

	local name = self.m_Member.szName
	local position = clanPosStrs[self.m_Member.nIdentity]
	local str = string.format("%s<color=#597993FF> 当前为[%s]</color>", name, position)
	controls.m_RoleCurPosTxt.text = str

	local clanClient = IGame.ClanClient
	local clanCurLvCfg = clanClient:GetClanLevelInfo() --当前等级帮派配置
		
	local PosMaxCntCfgKeys = --职位最大数量本地配置字段
	{
		[TitleToggles.SubHost] = "nUnderbossNum" ,
		[TitleToggles.Elder]   = "nElderNum" ,
		[TitleToggles.Peterxs] = "nDepartmentManagerNum"  ,
		[TitleToggles.Elite]   = "nEliteNum"  ,
		[TitleToggles.Captain] = "nCaptainNum" ,
	}

	local isHasPopedom = handler(IGame.ClanClient, IGame.ClanClient.HasAppointPopedom)

	for idx, tgl in ipairs(controls.Toggles) do 
		local bHasRepPopedom = isHasPopedom(TitleServerMap[idx].identify)
		local img = tgl.transform:GetComponent(typeof(Image))
		UIFunction.SetImageGray( img , not bHasRepPopedom )
		tgl.enabled  = bHasRepPopedom
		tgl.graphic.enabled = bHasRepPopedom

		local txt = tgl.transform:Find("Text"):GetComponent(typeof(Text))
		local identify = TitleServerMap[idx].identify
		local str = clanPosStrs[identify]
		if idx ~= TitleToggles.Mass then --群众不显示数量
			local curCnt = 1 -- 当前数量，由服务器下发
			local maxCnt = 1 -- 最大数量，度本地配置表
		
			if idx ~= TitleToggles.Host then --帮主数量均为1
				local propID = posCurCntPropIDs[identify]
				curCnt = clanClient:GetClanData(propID) or 0
				local maxKey = PosMaxCntCfgKeys[idx]
				maxCnt = clanCurLvCfg[maxKey]
			end
			str = string.format("%s(%d/%d)", str, curCnt, maxCnt)
		end
		
		txt.text = str
	end

end

-- 职位toggle选中事件
function ClanPositionChgWindow:OnTogglesChanged(idx)
	self.m_SelTitleIdx = idx
end

-- 任命按钮事件
function ClanPositionChgWindow:OnBtnCloseClicked()
	self:Hide()

	self.m_Member = nil
	self.m_SelTitleIdx = 0
end

-- 任命按钮事件
function ClanPositionChgWindow:OnBtnAppointClicked()
	if self.m_SelTitleIdx < 1 then
		print("the selected title index must than 0")
		return
	end

	if not self.m_Member then
		print("the member data can not equal nil")
		return
	end

	local identify = TitleServerMap[self.m_SelTitleIdx].identify
	IGame.ClanClient:AppointRequest(self.m_Member.dwPDBID, identify)
	self:Hide()
end


-- 成员更新事件
function ClanPositionChgWindow:OnMemberUpdateEvt()
	if not self:isShow() then
		return
	end

	local member = IGame.ClanClient:GetClan():GetMemberByID(self.m_Member.dwPDBID)
	if not isTableEmpty(member) then
		self.m_Member = member
		self:RefreshUI()
	end
end

return ClanPositionChgWindow
------------------------------------------------------------

