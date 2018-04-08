

-- 红包显示列表

------------------------------------------------------------
local RedPacketItem = UIControl:new
{
	windowName = "RedPacketItem",
	m_haveAttach =false
}

function RedPacketItem:Attach(obj, parent)
	UIControl.Attach(self, obj)
	if self.m_haveAttach ==true then 
		
	else
		
		self.m_haveAttach =true
		self.onClickOpen = function() self:OpenUp() end
		self.onClickDetail = function() self:OpenUp() end
		self.Controls.up_detail.onClick:AddListener(self.onClickDetail)
		self.Controls.up_open.onClick:AddListener(self.onClickOpen)
	
	end
  
	self.parent_ = parent
end

--打开红包
function RedPacketItem:OpenUp()
	IGame.RedEnvelopClient:OnRequestOpenRedenvelop(self.packet_type, 
		self.packet_data_up.dwSerial)
end

function RedPacketItem:OnRecycle()
	
	UIControl.OnRecyle(self)
end

function RedPacketItem:UpdateItem(type, ItemInfo)
	self.packet_type = nil
	
	if type == 1 then
		self.packet_type = emRED_ENVELOP_TYPE_WORLD
	elseif type == 2 then
		self.packet_type = emRED_ENVELOP_TYPE_CLAN
	else
		self.packet_type = emRED_ENVELOP_TYPE_TEAM
	end
	
	self.packet_data_up = ItemInfo
	
	self:ShowUI()
end

function RedPacketItem:OnDestroy()
	self.Controls.up_detail.onClick:RemoveListener(self.onClickOpen)
	self.Controls.up_open.onClick:RemoveListener(self.onClickDetail)
	self.m_haveAttach =false
	UIControl.OnDestroy(self)
	
end


-- 1:已抢光 2：已抢过 3：无权限 4:全部隐藏
function RedPacketItem:SetRedPacketState(state)
	if state == 1 then 
		self.Controls.HaveQiang.gameObject:SetActive(false)
		self.Controls.NoQuanXian.gameObject:SetActive(false)
		self.Controls.m_state.HaveOver.gameObject:SetActive(true)
	elseif state == 2 then 
		self.Controls.HaveQiang.gameObject:SetActive(true)
		self.Controls.NoQuanXian.gameObject:SetActive(false)
		self.Controls.HaveOver.gameObject:SetActive(false)
	elseif state == 3 then 
		self.Controls.HaveQiang.gameObject:SetActive(false)
		self.Controls.NoQuanXian.gameObject:SetActive(true)
		self.Controls.HaveOver.gameObject:SetActive(false)
	else
		self.Controls.HaveQiang.gameObject:SetActive(false)
		self.Controls.NoQuanXian.gameObject:SetActive(false)
		self.Controls.HaveOver.gameObject:SetActive(false)
	end
end

function RedPacketItem:ShowUI()
	local state = self.packet_data_up.btState
	if state == emType_Redenvelop_State_CanGet then
		self.Controls.up_no.gameObject:SetActive(true)
		self.Controls.up_done.gameObject:SetActive(false)
		self.Controls.up_name_1.text = self.packet_data_up.szSenderName
	else
		self.Controls.up_no.gameObject:SetActive(false)
		self.Controls.up_done.gameObject:SetActive(true)
		self.Controls.up_name_2.text = self.packet_data_up.szSenderName
		
		local szBlessWords = self.packet_data_up.szBlessWords
		local len = utf8.len(szBlessWords)
		if len > 10 then
			szBlessWords = utf8.sub(szBlessWords,1,11)
			szBlessWords = szBlessWords .. "..."
		end
		self.Controls.up_wish.text = szBlessWords
		
		if state == emType_Redenvelop_State_God then
			self:SetRedPacketState(2)
		elseif state == emType_Redenvelop_State_Miss then
			self:SetRedPacketState(1)
		elseif state == emType_Redenvelop_State_CannotGet then
			self:SetRedPacketState(3)
		else
			self:SetRedPacketState(4)
		end
	end
end


return RedPacketItem