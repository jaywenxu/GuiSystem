--*******************************************************************
--** 文件名:	RedPacketDetailWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	何水大
--** 日  期:	2017-09-19
--** 版  本:	1.0
--** 描  述:	红包详细信息界面
--** 应  用:  
--*******************************************************************
local RedPacketDetailWindow = UIWindow:new
{
	windowName = "RedPacketDetailWindow",
	m_NeedUpdate = false,
}

function RedPacketDetailWindow:OnAttach(obj)
    UIWindow.OnAttach(self, obj)
	
	self.m_EnhancedListView = self.Controls.m_scrollView.gameObject:GetComponent(typeof(EnhancedListView))
	self.m_EnhancedScroller = self.Controls.m_scrollView.gameObject:GetComponent(typeof(EnhancedScroller))
	self:AddListener(self.m_EnhancedListView, "onGetCellView", self.OnGetCellView, self)
	self:AddListener(self.m_EnhancedListView, "onCellViewVisiable", self.OnCellViewVisiable, self)
	self.m_EnhancedScroller.scrollerScrollingChanged = handler(self, self.OnEnhancedScrollerScrol)
	self:AddListener(self.Controls.closeBtn, "onClick", self.OnCloseClick, self)

	self.TweenAnim = self.Controls.m_allUI:GetComponent(typeof(DG.Tweening.DOTweenAnimation))
	
	if self.m_NeedUpdate == true then
		self.m_NeedUpdate = false
		self:ShowUI()
	end
end

function RedPacketDetailWindow:OpenShowPanel(value)
	self:Show(true)
	self.packetValue = value
	self:RefreshUI()
end

function RedPacketDetailWindow:RefreshUI()
	if self:isLoaded() then
		self:ShowUI()
	else
		self.m_NeedUpdate = true
	end
end

function RedPacketDetailWindow:ShowUI()
	if not self:isLoaded() then
        self.m_NeedUpdate = true
        return
    end
	
	self.TweenAnim:DORestart(true) 
	
	local value = self.packetValue
	UIFunction.SetHeadImage(self.Controls.m_sendIcon, value.dwSenderFaceID)
	print("红包头像ID:" .. value.dwSenderFaceID)
	self.Controls.m_sendName.text = value.szSenderName .. "的红包"
	self.Controls.m_totalMoney.text = tostringEx(value.dwTotalMoney)
	self.Controls.m_totalNum.text = value.nCount.."/"..value.dwTotalRedEnvelopNum.."个"
	self.Controls.m_tips.text = value.szBlessWords
	
	local pdbid = GetHeroPDBID()
	local btState = value.btState
	if btState == emType_Redenvelop_State_God then
		for _,v in pairs(value.smallRedEnvelop) do
			if v.dwPDBID == pdbid then
				self.Controls.m_getNum.text = "你抢到"..v.nValue.."银两!"
				break
			end
		end
	elseif 	btState == emType_Redenvelop_State_Miss then
		self.Controls.m_getNum.text = "抢光啦！"
	elseif 	btState == emType_Redenvelop_State_CannotGet then
		self.Controls.m_getNum.text = "你没有权限领取！"
	end
	
	self.m_EnhancedListView:SetCellCount(value.nCount, true)
end

--item创建时调用
function RedPacketDetailWindow:OnGetCellView(goCell)
	goCell.gameObject.transform.localPosition = Vector3.New(0,0,0)
	local enhancedCell = goCell:GetComponent(typeof(EnhancedListViewCell))
	goCell:SetActive(true)
end

--刷新item时调用
function RedPacketDetailWindow:OnRefreshCellView(goCell)
	local index = tonumber(split_string(goCell.name, " ")[2]) + 1
	local packet = self.packetValue.smallRedEnvelop[index]
	local name = goCell:Find("name"):GetComponent(typeof(Text))
	local num = goCell:Find("num"):GetComponent(typeof(Text))
	local best = goCell:Find("best"):GetComponent(typeof(Image))
	name.text = packet.szName
	num.text = tostringEx(packet.nValue)
	if self.packetValue.dwBestID == packet.dwPDBID then
		best.gameObject:SetActive(true)
	else
		best.gameObject:SetActive(false)
	end
end

--item可见时调用
function RedPacketDetailWindow:OnCellViewVisiable(goCell)
	local index = tonumber(split_string(goCell.name, " ")[2]) + 1
	local packet = self.packetValue.smallRedEnvelop[index]
	local name = goCell.transform:Find("name"):GetComponent(typeof(Text))
	local num = goCell.transform:Find("num"):GetComponent(typeof(Text))
	local best = goCell.transform:Find("best"):GetComponent(typeof(Image))
	name.text = packet.szName
	num.text = tostringEx(packet.nValue)
	if self.packetValue.dwBestID == packet.dwPDBID then
		best.gameObject:SetActive(true)
	else
		best.gameObject:SetActive(false)
	end
end

--Scroll 滚动时调用
function RedPacketDetailWindow:OnEnhancedScrollerScrol(scroller, scrolling)
	
end

function RedPacketDetailWindow:OnCloseClick()
	self:Hide()
	self.isInit = false
end

function RedPacketDetailWindow:OnDestroy()
	UIWindow.OnDestroy(self)
end

return RedPacketDetailWindow