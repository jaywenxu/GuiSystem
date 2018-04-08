-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    许文杰
-- 日  期:    2017/09/22
-- 版  本:    1.0
-- 描  述:    红包按钮的控制
local MainRedPacketWindow = UIWindow:new
{
    windowName = "MainRedPacketWindow" ,
	m_haveDoEnable = false,
	m_currentPacketInfo = nil,
}

local GetNextRedPacketTime = 30

function MainRedPacketWindow:OnAttach(obj)
	UIWindow.OnAttach(self,obj)
	self.Controls.m_RedPacketBtn.onClick:AddListener(function() self:OnClickRedPacketBtn() end)
	self.UpdateRepacket =function() self:UpdateCurrentInfo() end

end

--local newPacket = {dwSerial = info.dwSerial, btType = info.btType, dwTime = os.time() + 30}
--刷新当前的红包信息
function MainRedPacketWindow:UpdateCurrentInfo(currentInfo)
	if currentInfo == nil then 
		if self:isLoaded() then 
			self:Hide()
		end
		
	else
		self.m_currentPacketInfo = currentInfo
		self:Show(true)
	end
end


function MainRedPacketWindow:OnDestroy()
	self.m_currentPacketInfo = nil
	UIWindow.OnDestroy(self)
end

--local newPacket = {dwSerial = info.dwSerial, btType = info.btType, dwTime = GetServerTimeSecond() + 30}
function MainRedPacketWindow:OnClickRedPacketBtn()
	local newPacketInfo = self.m_currentPacketInfo
	if  newPacketInfo == nil  then 
		return
	end
	IGame.RedEnvelopClient:OnRequestOpenRedenvelop(newPacketInfo.btType,newPacketInfo.dwSerial)
	
	IGame.RedEnvelopClient:RemoveCurrentRedPacket()
end

return MainRedPacketWindow
