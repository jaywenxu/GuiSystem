-------------------------------------------------------------------
-- @Author: XieXiaoMei
-- @Date:   2017-08-16 10:48:04
-- @Vers:	1.0
-- @Desc:	系统红点管理类
--[[ 
**使用步骤:
	1.增加模块的的红点存储表，如：FriendEmail表，表包含EventSrcID事件ID，Layout红点布局信息
	
	2.更新模块红点状态，如：SysRedDotsMgr.UpdateSysRedDot("FriendEmail", "好友", true, "MainMidBottom", "好友") ，
	改变[FriendEmail]表的"好友"红点状态为true，并且更新[MainMidBottom]表的的"好友"状态，如果标记改变将会发出2个红点更新事件

	3.在UI界面中监听系统的红点更新事件，并且刷新。在事件回调中可以使用SysRedDotsMgr.RefreshRedDot方法，如：
	function FriendEmailWindow:RefreshRedDot(_, _, _, evtData)
		local redDotObjs = 
		{
			["邮件"] = self.m_TabToggles[TabToggles.Email],
			["好友"] = self.m_TabToggles[TabToggles.Friend]
		}
		SysRedDotsMgr.RefreshRedDot(redDotObjs, "FriendEmail", evtData)　--刷新红点
	end
]]


SysRedDotsMgr = {}

-------------------------------------------------------------------
-- 红点显示位置
local LayoutPos = 
{
	RightTop    = 1,
	RightBottom = 2,
	LeftTop     = 3,
	LeftBottom  = 4
}

-------------------------------------------------------------------
-- 主界面右上界面
SysRedDotsMgr.MainRightTop =
{
	EventSrcID = REDDOT_UI_EVENT_MAIN_RIGHT_TOP,

	Layout =
	{
		["福利"] = {flag = false, pos = LayoutPos.RightTop},
		["摆摊"] = {flag = false, pos = LayoutPos.RightTop},
		["活动"] = {flag = false, pos = LayoutPos.RightTop},
	}
}

-------------------------------------------------------------------
-- 主界面中下界面
SysRedDotsMgr.MainMidBottom = 
{
	EventSrcID = REDDOT_UI_EVENT_MAIN_MID_BOTTOM,

	Layout =
	{
		["好友"] = {flag = false, pos = LayoutPos.RightTop},
	}
}

-- 主界面右下界面
SysRedDotsMgr.MainRightBottom = 
{
	EventSrcID = REDDOT_UI_EVENT_MAIN_RIGHT_BOTTOM,

	Layout =
	{
		["帮会"] = {flag = false, pos = LayoutPos.RightTop},
	}
}

-------------------------------------------------------------------
-- 摆摊界面
SysRedDotsMgr.Exchange =
{
	EventSrcID = REDDOT_UI_EVENT_EXCHANGE,

	Layout =
	{
		["出售"] = {flag = false, pos = LayoutPos.RightTop},
	}
}

-------------------------------------------------------------------
-- 好友邮件界面
SysRedDotsMgr.FriendEmail =
{
	EventSrcID = REDDOT_UI_EVENT_FRIEND_EMAIL,

	Layout =
	{
		["邮件"] = {flag = false, pos = LayoutPos.RightTop},
		["好友"] = {flag = false, pos = LayoutPos.RightTop},
	}
}

-------------------------------------------------------------------
-- 福利界面
SysRedDotsMgr.Welfare =
{
	EventSrcID = REDDOT_UI_EVENT_WELRARE,

	Layout =
	{
		["每日签到"] = {flag = false, pos = LayoutPos.RightTop},
		["奖励找回"] = {flag = false, pos = LayoutPos.RightTop},
		["升级礼包"] = {flag = false, pos = LayoutPos.RightTop},
		["七天登录"] = {flag = false, pos = LayoutPos.RightTop},
	}
}



-------------------------------------------------------------------
-- 帮会ClanOwnWindow窗口红点
SysRedDotsMgr.ClanOwnWindow =
{
	EventSrcID = REDDOT_UI_EVENT_CLAN_OWNWINDOW,

	Layout =
	{
		["成员"] = {flag = false, pos = LayoutPos.RightTop},
--		["建筑"] = {flag = false, pos = LayoutPos.RightTop},
	}
}

-- 帮会ClanMembersWdt界面红点
SysRedDotsMgr.ClanMembersWdt =
{
	EventSrcID = REDDOT_UI_EVENT_CLAN_MEMBERSWDT,

	Layout =
	{
		["红包"] = {flag = false, pos = LayoutPos.RightTop},
		["帮会管理"] = {flag = false, pos = LayoutPos.RightTop},
	}
}

-- 帮会管理
SysRedDotsMgr.ClanManager =
{
	EventSrcID = REDDOT_UI_EVENT_CLAN_MANAGER,

	Layout =
	{
		["帮会申请"] = {flag = false, pos = LayoutPos.RightTop},
	}
}

-- 红包分页红点
SysRedDotsMgr.RedPacketPage =
{
	EventSrcID = REDDOT_UI_EVENT_REPACKET_PAGE,

	Layout =
	{
		["世界红包"] = {flag = false, pos = LayoutPos.RightTop},
		["帮会红包"] = {flag = false, pos = LayoutPos.RightTop},
		["队伍红包"] = {flag = false, pos = LayoutPos.RightTop},
	}
}

-- 活动界面红点
SysRedDotsMgr.ActivePage =
{
	EventSrcID = REDDOT_UI_EVENT_ACTIVITY_PAGE,

	Layout =
	{
		["活跃"] = {flag = false, pos = LayoutPos.RightTop},
	}
}

--------------------------------------------------------------------
-- 获取系统红点标记，无子布局所以，遍历获取全组标记
-- @ systemKey	: 模块索引, 如："Exchange"
-- @ layoutKey	: 子布局索引, 如："出售"
function SysRedDotsMgr.GetSysFlag(systemKey, layoutKey)
	local system = SysRedDotsMgr[systemKey]
	if isTableEmpty(system) then
		uerror("system can't be nil!", systemKey)
		return false
	end

	local flag = false

	if not layoutKey then -- 获取全组标记
		for k, v in pairs(system.Layout) do
			flag = v.flag or flag
		end
	else -- 获取单个标记
		flag = system.Layout[layoutKey] and system.Layout[layoutKey].flag or flag
	end
	
	return flag
end

---------------------------------------------------------------------
-- 更新模块红点
-- @ systemKey	: 模块索引, 如："Exchange"
-- @ layoutKey	: 子布局索引, 如："出售"
-- @ flag		: 标记, true or false
-- @ affectSysKey		: 被影响的界面模块索引, 如："MainRightTop"，不发送被影响界面事件则不传
-- @ affectLayoutKey	: 被影响的界面子布局索引, 如："摆摊"
function SysRedDotsMgr.UpdateSysRedDot(systemKey, layoutKey, flag, affectSysKey, affectLayoutKey)
	local system = SysRedDotsMgr[systemKey]
	if isTableEmpty(system) then
		uerror("system can't be nil!", systemKey)
		return
	end

	-- 系统内提醒，flag状态不同则更新
	local layout = system.Layout[layoutKey]
	if layout then 
		layout.flag = flag
			
		local evtData = {flag = flag, layout = layoutKey}
		rktEventEngine.FireEvent(EVENT_UI_REDDOT_UPDATE, SOURCE_TYPE_SYSTEM, system.EventSrcID, evtData) -- 发出系统更新红点事件

		-- 被影响的界面红点更新
		if affectSysKey and SysRedDotsMgr[affectSysKey] then

			system = SysRedDotsMgr[affectSysKey]
			local layout = system.Layout[affectLayoutKey]
			
			local bMainUISysFlag = SysRedDotsMgr.GetSysFlag(systemKey)

			if layout.flag ~= bMainUISysFlag then 
				layout.flag = bMainUISysFlag
				
				evtData = {flag = flag, layout = affectLayoutKey}
				rktEventEngine.FireEvent(EVENT_UI_REDDOT_UPDATE, SOURCE_TYPE_SYSTEM, system.EventSrcID, evtData)  -- 发出主界面更新红点事件
			end
		end

	end

end

-- ---------------------------------------------------------------------
-- -- 刷新红点
-- -- @ redDotObjs	: 要显示红点的UI对象数组，如: redDotObjs = {["邮件"] = toggle1, ["好友"] = toggle2}
-- -- @ systemKey	: 模块索引, 如："FriendEmail"
-- -- @ evtData	: 单个红点的刷新事件数据 如：evtData = {flag = true, layout = "邮件"}
-- function SysRedDotsMgr.RefreshRedDot(redDotObjs, systemKey, evtData)
-- 	-- 如果evtData是空，则刷新全部红点
-- 	if isTableEmpty(evtData) then
-- 		for name, obj in pairs(redDotObjs) do
-- 			local flag = SysRedDotsMgr.GetSysFlag(systemKey, name)
-- 			UIFunction.ShowRedDotImg(obj.transform, flag)
-- 		end
-- 	else
-- 		-- 有evtData，则刷新单个红点
-- 		local obj = redDotObjs[evtData.layout]
-- 		if obj then
-- 			UIFunction.ShowRedDotImg(obj.transform, evtData.flag)
-- 		end
-- 	end
-- end

---------------------------------------------------------------------
-- 刷新红点
-- @ redDotObjs	: 要显示红点的UI对象数组，如: redDotObjs = {["邮件"] = toggle1, ["好友"] = toggle2}
-- @ systemKey	: 模块索引, 如："FriendEmail"
-- @ evtData	: 单个红点的刷新事件数据 如：evtData = {flag = true, layout = "邮件"}
function SysRedDotsMgr.RefreshRedDot(redDotObjs, systemKey, evtData)

	local function ShowRedDot(objs, flag)
		if type(objs) == "table" and #objs > 0 then  -- 多个对象
			for _, obj in pairs(objs) do
				UIFunction.ShowRedDotImg(obj.transform, flag)
			end
		else -- 单个对象
			UIFunction.ShowRedDotImg(objs.transform, flag)
		end
	end

	-- 如果evtData是空，则刷新全部红点
	if isTableEmpty(evtData) then
		for name, objs in pairs(redDotObjs) do
			local flag = SysRedDotsMgr.GetSysFlag(systemKey, name)
			ShowRedDot(objs, flag)
		end
	else
		-- 有evtData，则刷新单个红点
		local objs = redDotObjs[evtData.layout]
		if objs then
			ShowRedDot(objs, evtData.flag)
		end
	end
end

-------------------------------------------------------------------
-- 一个模块对一个表，表里有子界面的树形结构,例如下面的SysRedDotsMgr.ClanBuilding
-- 流程：Show(true)->未初始化->注册事件和UI节点
									--|
			 -->已经初始化--> --> 申请下发数据并检查状态 --> 刷新界面--> 根据检查结果刷新红点提示
-------------------------------------------------------------------
SysRedDotsMgr.ClanBuilding = 
{
	Layout =
	{
		["帮会"] = {
			CheckEventID = REDDOT_UI_EVENT_CLAN,
			CheckSourceID = SOURCE_TYPE_CLAN, TYPEID = 1,
			flag = false, pos = LayoutPos.RightTop,
			["建筑分页"] = {
				CheckEventID = REDDOT_UI_EVENT_CLAN_BUILDING,
				CheckSourceID = SOURCE_TYPE_CLAN, TYPEID = 2,
				flag = false, pos = LayoutPos.RightTop,
				["福利按钮"] = {
					CheckEventID = REDDOT_UI_EVENT_CLAN_WELFARE,
					CheckSourceID = SOURCE_TYPE_CLAN, TYPEID = 2,
					flag = false, pos = LayoutPos.RightTop,
					["礼包领取"] = {
						CheckEventID = REDDOT_UI_EVENT_CLAN_GIFT,
						CheckSourceID = SOURCE_TYPE_CLAN, TYPEID = 3,
						flag = false, pos = LayoutPos.RightTop,
					},
					["工资领取"] = {
						CheckEventID = REDDOT_UI_EVENT_CLAN_WAGE,
						CheckSourceID = SOURCE_TYPE_CLAN, TYPEID = 4,
						flag = false, pos = LayoutPos.RightTop
					},
				}
			}
		}
	}
}

---------------------------------------------------------------------
-- 界面初始化后，注册事件和UI节点，和表的值绑定
-- @ subTable	: 模块布局(表)的内的某一层级子表引用
-- @ layoutName	: 上个参数所引用的子表内某个字段名称,类型-String,指向一个子表
-- @ recHintObj	: 接收红点提示的UI节点,是一个GameObject、Transform或者Image(RawImage)
-- @ objName	: 给定接收红点提示的UI节点的名称，用于index到上边参数所引用的表
-- @ checkMethod: 检查数据是否应该显示红点的方法(委托)
function SysRedDotsMgr.Register(subTable, layoutName, recHintObj, objName, checkMethod)	
	local layout = subTable[layoutName]
	subTable[layoutName][objName] = recHintObj
	if not subTable[layoutName].objArray then
		subTable[layoutName].objArray = {}
	end
	local function IsInObjArray(objArray, obj)
		local result = false
		--print(tableToString(objArray))
		table_remove_match(objArray,function (o)
			return tolua.isnull( o )
		end)
		for i=1, #objArray do
			if nil ~= objArray[i] and obj ~= nil then
				if objArray[i].gameObject.name == obj.gameObject.name then
					result = true
				end
			end
		end
		return result
	end
	local objArray = subTable[layoutName].objArray
	if not IsInObjArray(objArray, recHintObj) then
		table.insert(objArray, recHintObj)
	end
	rktEventEngine.SubscribeExecute(layout.CheckEventID, layout.CheckSourceID, 0, checkMethod)
end

function SysRedDotsMgr.Cancel(subTable, layoutName, objName, checkMethod)
	local layout = subTable[layoutName]
	layout[objName] = nil
	if nil ~= layout.objArray then
		layout.objArray = {}
	end
	rktEventEngine.UnSubscribeExecute(layout.CheckEventID, layout.CheckSourceID, 0, checkMethod)
end

-- 动态生成的列表，注册事件和UI节点，和表的值绑定
function SysRedDotsMgr.RegisterCreation(subTable, layoutName, checkMethod)
	local layout = subTable[layoutName]
	rktEventEngine.SubscribeExecute(layout.CheckEventID, layout.CheckSourceID, 0, checkMethod)
end

-- 界面刷新前，或在刷新时，立刻检查对应布局表内用于判定是否显示红点的方法,一般在得到判定
-- 结果，会调用SetVisible()来决定某一层级单独的红点状态，或在调用Assert()来决定所有和这个
-- TYPEID对应事件有关的节点的红点状态
function SysRedDotsMgr.Check(subTable, layoutName)
	local layout = subTable[layoutName]
	rktEventEngine.FireEvent(layout.CheckEventID, layout.CheckSourceID, 0, nil)
end

-- 设置某个UI节点的红点状态
-- @ subTable	: 模块布局(表)的内的某一层级子表引用
-- @ layoutName	: 上个参数所引用的子表内某个字段名称,类型-String,指向一个子表
-- @ objName	: 给定接收红点提示的UI节点的名称
-- @ visable	: 红点是否显示
function SysRedDotsMgr.SetVisible(subTable, layoutName, objName, visable)
	if isTableEmpty(subTable) then
		uerror("SysRedDotsMgr.SetVisible() return, as 'SubTable' is not exist!")
		return
	end
	local layout = subTable[layoutName]
	if (not layout) or (not layout[objName]) then return end
	layout.flag = visable
	local obj = layout[objName]
	UIFunction.ShowRedDotImg(obj.transform, visable)
end

-- 某个UI内的变化必定不会改变红点的状态，则直接显示对应状态的红点
function SysRedDotsMgr.Show(subTable, layoutName, objName)
	local layout = subTable[layoutName]
	if (not layout) or (not layout[objName]) then return end
	local obj = layout[objName]
	UIFunction.ShowRedDotImg(obj.transform, layout.flag)
end

-- 断言，当红点变化的条件满足时，改变所有与这个判定事件ID有关的UI节点上的红点状态
-- @ Module_Layout:模块布局(表),结构为 XXX.Layout,比如SysRedDotsMgr.ClanBuilding.Layout
-- @ subTable	: 模块布局(表)的内的某一层级子表引用
-- @ layoutName	: 上个参数所引用的子表内某个字段名称,类型-String,指向一个子表
-- @ visable	: 红点是否显示
function SysRedDotsMgr.Assert(Module_Layout, subTable, layoutName, visable)
	local nLayout = subTable[layoutName]
	local nTYPEID = nLayout.TYPEID
	
	local function doRefresh(layout)
		if layout.TYPEID == nTYPEID and 
			not isTableEmpty(layout.objArray) then
			for i=0,#layout.objArray do
				local obj = layout.objArray[i]
				if nil ~= obj then
					layout.flag = visable
					UIFunction.ShowRedDotImg(obj.transform, layout.flag)
				end
			end
		end
		for k,v in pairs(layout) do
			if nil ~= v and type(v) == "table" then
				doRefresh(v)
			end
		end 
	end
	
	-- 遍历全表
	for k,v in pairs(Module_Layout) do
		if nil ~= v and type(v) == "table" then
			doRefresh(v)
		end
	end
	--print(debug.traceback("<color=red>table content:</color> <color=white>" .. tableToString(Module_Layout) .. "</color>"))
end

function SysRedDotsMgr.ResetAllTable()
	cLog("SysRedDotsMgr.ResetAllTable!", "red")
	SysRedDotsMgr.ResetTable(SysRedDotsMgr.MainRightTop.Layout)
	SysRedDotsMgr.ResetTable(SysRedDotsMgr.MainMidBottom.Layout)
	SysRedDotsMgr.ResetTable(SysRedDotsMgr.MainRightBottom.Layout)
	SysRedDotsMgr.ResetTable(SysRedDotsMgr.Exchange.Layout)
	SysRedDotsMgr.ResetTable(SysRedDotsMgr.FriendEmail.Layout)
	SysRedDotsMgr.ResetTable(SysRedDotsMgr.Welfare.Layout)
	SysRedDotsMgr.ResetTable(SysRedDotsMgr.ClanOwnWindow.Layout)
	SysRedDotsMgr.ResetTable(SysRedDotsMgr.ClanMembersWdt.Layout)
	SysRedDotsMgr.ResetTable(SysRedDotsMgr.ClanManager.Layout)
	SysRedDotsMgr.ResetTable(SysRedDotsMgr.RedPacketPage.Layout)
	SysRedDotsMgr.ResetTable(SysRedDotsMgr.ClanBuilding.Layout)
end

function SysRedDotsMgr.ResetTable(t)
	for k, v in pairs(t) do	
		if type(v) == "boolean" then
			t[k] = false
		elseif type(v) == "table" then
			SysRedDotsMgr.ResetTable(v)
		end
	end
end