-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    刘翠立
-- 日  期:    2017/02/19
-- 版  本:    1.0
-- 描  述:    侠客行点赞礼包窗口
-------------------------------------------------------------------

local XiaKeXingBagWindow = UIWindow:new
{
	windowName		= "XiaKeXingBagWindow",	
	m_ItemUID		= nil,
	m_MsgText		= "",
}

------------------------------------------------------------
function XiaKeXingBagWindow:Init()
	self.XiaKeXingBagInputWidget = require( "GuiSystem.WindowList.XiaKeXingBag.XiaKeXingBagInputWidget" )
end

------------------------------------------------------------
function XiaKeXingBagWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	self.XiaKeXingBagInputWidget:Attach( self.Controls.m_Input_Widget.gameObject )
	self.XiaKeXingBagInputWidget:Hide()
	
	-- 监听关闭按钮
	self.Controls.m_CloseBtn.onClick:AddListener(handler(self, self.OnBtnCloseClicked))
	
	-- 监听发送按钮
	self.Controls.m_SendBtn.onClick:AddListener(handler(self, self.OnBtnSendClicked))
	--UIFunction.AddEventTriggerListener( self.transform , EventTriggerType.PointerClick , function( eventData ) self:OnCloseTriggleClick(eventData) end )

	for i=1,4 do
		self.Controls["MsgToggle"..i] = self.Controls.m_ToggleGrop:Find("MsgToggle ("..i..")")
		self.Controls["MsgToggleTog"..i] = self.Controls["MsgToggle"..i]:GetComponent(typeof(Toggle))
		self.Controls["MsgToggleTog"..i].onValueChanged:AddListener(function (on)
			self:OnMsgToggleChanged(i, on)
		end)
		self.Controls["MsgToggleLable"..i.."Label"] = self.Controls["MsgToggle"..i]:Find("Checkmark/Label"):GetComponent(typeof(Text))
		self.Controls["MsgToggleLable"..i.."Label"].text = XIAKEXING_BAG_MSG[i]
		self.Controls["MsgToggleLable"..i.."Label1"] = self.Controls["MsgToggle"..i]:Find("Background/Label1"):GetComponent(typeof(Text))
		self.Controls["MsgToggleLable"..i.."Label1"].text = XIAKEXING_BAG_MSG[i]
	end
    -- 默认选择第一个
    self.Controls["MsgToggleTog1"].isOn = true
	self:Refresh()
	
    return self
end

function XiaKeXingBagWindow:OnBtnCloseClicked()
	self:Hide()
end

function XiaKeXingBagWindow:OnCloseTriggleClick(eventData)
	self:Hide()
	rkt.UIAndTextHelpTools.PassThroughPointerClickEvent( eventData )
end

-- 发送按钮
function XiaKeXingBagWindow:OnBtnSendClicked()
	local szMsg	= self.m_MsgText
	if szMsg == "" then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "编辑你想说的话，才能点击发送按钮")
		return
	end
	
	local ExtendInfo = self:GetExtendInfo()
	if ExtendInfo and not IGame.FriendClient:IsFriend(ExtendInfo.LeaderPDBID) then
        self:AddFriend()
		return
	end
	local nGoodUID	= self.m_ItemUID
	GameHelp.PostServerRequest("RequestXiaKeXing_OpenBag("..nGoodUID..",'"..szMsg.."')")
	
	self:Hide()
end

-- 设置物品的UID
function XiaKeXingBagWindow:SetItemUID(ItemUID)
	self.m_ItemUID = ItemUID
	self:Refresh()
end

function XiaKeXingBagWindow:OnMsgToggleChanged(i,on)
	if i == 4 then
		-- 选择自定义的时候，如果是还没编辑的就将保存的内容置为空 否则拷贝一下
		if self.Controls["MsgToggleLable4Label"].text ~= XIAKEXING_BAG_MSG[4] then
			self.m_MsgText = self.Controls["MsgToggleLable4Label"].text
		else
			self.m_MsgText = ""
		end
		self.XiaKeXingBagInputWidget:Show()
	else
		self.m_MsgText = XIAKEXING_BAG_MSG[i]
		self.XiaKeXingBagInputWidget:Hide()
	end
	
end

function XiaKeXingBagWindow:Refresh()
	if not self:isLoaded() or not self.m_ItemUID then
		return
	end
	local pEntity = IGame.EntityClient:Get(self.m_ItemUID)
	if not pEntity then
		return
	end
	local extendBuff  = pEntity:GetExtendBuff()
	if not extendBuff or type(extendBuff) ~= 'string' then
		uerror("[XiaKeXingBagWindow:Refresh]extendBuff error")
		return
	end
	local ExtendBuff = ByteBuffer(extendBuff)
	local ExtendInfo = ExtendBuff:ReadStruct("SLeechdomExtend_XiKeXingBag")
	cLog(tostringEx(ExtendInfo),"red")
	
	self.Controls.m_TitleText.text = "你要对 <color=#a077df>"..ExtendInfo.szLeaderName.."</color> 说："
end

function XiaKeXingBagWindow:GetExtendInfo()
	local pEntity = IGame.EntityClient:Get(self.m_ItemUID)
	if not pEntity then
		return
	end
	local ExtendBuff = ByteBuffer(pEntity:GetExtendBuff())
	local ExtendInfo = ExtendBuff:ReadStruct("SLeechdomExtend_XiKeXingBag")
	return ExtendInfo
end

function XiaKeXingBagWindow:SetToggleText(text)
	self.m_MsgText = text
	self.Controls["MsgToggleLable4Label"].text = text
	self.Controls["MsgToggleLable4Label1"].text = text
    self:OnBtnSendClicked()
end

function XiaKeXingBagWindow:AddFriend()
	local ExtendInfo = self:GetExtendInfo()
    local confirmCallBack = function ( )
        IGame.FriendClient:OnRequestAddFriend(ExtendInfo.LeaderPDBID)
    end
    local data = 
    {
        content = "只能向好友送礼物，是否立即添加<color=#a077df>" .. ExtendInfo.szLeaderName .. "</color>为好友",
        confirmCallBack = confirmCallBack,
    }	
    UIManager.ConfirmPopWindow:ShowDiglog(data)
end

return XiaKeXingBagWindow