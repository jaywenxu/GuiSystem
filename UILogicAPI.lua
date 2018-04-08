--/******************************************************************
---** 文件名:	UILogicAPI.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	周加财
--** 日  期:	2017-01-07
--** 版  本:	1.0
--** 描  述:	UI逻辑类
--** 应  用:  	封装游戏API,由UI层调用逻辑层
--******************************************************************


UILogicAPI = {}

local this = UILogicAPI

function UILogicAPI.OnLogin(account, pwd, IP, port)

	IGame.LoginForm.SetGatewayAddress(IP, 9000)
	IGame.LoginForm.StartLogin(account, pwd)
end
-- 注册命令
function UILogicAPI.OnRegister(dwPartnerID,  szAccount,  strPassword,  strRealyName,  strID,  strVertifyCode, GatewayIP)

    IGame.LoginForm.SetGatewayAddress(GatewayIP, 9000)
    IGame.LoginForm.StartRegister(dwPartnerID,szAccount,strPassword,strRealyName,strID,strVertifyCode,Function.GetMacAddress())
end


-- 从角色选择界面进入游戏
function UILogicAPI.OnEnterGame( strActorName)
   IGame.SelectActorForm:RequestSelectActor(strActorName)
end

-- channel参考：EMChatTable
function UILogicAPI.GetChatMsg(ChatMsg, ChannelTable)
    return IGame.ChatClient.GetChatMsg(ChatMsg, ChannelTable)
end

function UILogicAPI.GetLatestChatMsg(ChatMsg, ChannelTable)
    return IGame.ChatClient.GetLatestChatMsg( ChatMsg, ChannelTable)
end

function UILogicAPI.GetMainHUDChatMsgList(ChatMsg)

    return IGame.ChatClient.GetMainHUDChatMsgList( ChatMsg)
end

function UILogicAPI.GetChatMsgByIndex(chatMsg,Index)

    return IGame.ChatClient.GetChatMsgByIndex(chatMsg, Index)
end

function UILogicAPI.SetChatMsgByIndex(chatMsg, Index)

    return IGame.ChatClient.SetChatMsgByIndex(chatMsg, Index)
end

-- 请求更新角色的活动列表
function UILogicAPI.RequestActorTaskList()

    Help_TaskAssist.GetTimesMgr().RequestActorTaskList();
end


function UILogicAPI.ShowBgTexture(isOn)
    
	UISystemManager.SetTexture(isOn)
end

function UILogicAPI.ShowContextMenu(dbid, Pos_x, Pos_y, TargetName, type)
    GlobalGame.Instance.ControlManager.GetContextMenu().ContextMenuMouseRightClickShow(dbid, Pos_x, Pos_y, TargetName, type)
end

function UILogicAPI.OnCreateActor(actorContext)
    GlobalGame.Instance.SelectActorForm.CreateActor(actorContext)
end

-- 判断是是否可显示寄售按钮
function UILogicAPI.CanShowConsignBtn()

	local nUserLevel = IGame.GetHero().GetNumProp((CREATURE_PROP_LEVEL))

	if nUserLevel < 100 then
		return false
	end


	return true
end

-- 获取地图NPC配置
function UILogicAPI.GetNPCNavigatorInfo(lMapID, type)
        local list = FacadeAPI.GetSchemeCenter().GetMapNavigator().GetMapNavigatorListByMapID(lMapID, type)
        return list;
end

function UILogicAPI.GetMapNavigationInfo()
    return FacadeAPI.GetSchemeCenter().GetMapNavigationInfo().GetMapNavigationInfo()
end
-- 获取活动系统控制模块
function UILogicAPI.GetTaskAssistController()
        return GlobalGame.Instance.ControlManager.GetTaskAssistController()
end

-- 获取活动基础数据
function UILogicAPI.GetTaskAssistList(flag)

	return IGame.GetSchemeCenter().GetSchemeTaskAssist().GetRecordSet(flag)
end

-- 获取活动次数、时间数据
function UILogicAPI.GetTaskAssistTimes(pdbid, taskid)
	return 0
end                                        