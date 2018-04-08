
local pickUpItemClass =  require("GuiSystem.WindowList.Chicking.PickUpItem")

local PickUpItemWindow = UIWindow:new
{
	windowName = "PickUpItemWindow" ,
	m_listItem={},
	m_serverInfo=nil,
	m_UID = nil,
}

function PickUpItemWindow:OnAttach( obj )
	UIWindow.OnAttach(self,obj)
	if self.m_serverInfo ~= nil then 
		self:RefreshUI(self.m_UID, self.m_serverInfo )
	end
	self.Controls.onePickUpBtn.onClick:AddListener(function() self:OnePickUp() end)
	self.Controls.closeBtn.onClick:AddListener(function() self:OnCickCloseBtn() end)
end

--关闭界面
function PickUpItemWindow:OnCickCloseBtn()
	self:Hide()
end

--一键拾取
function PickUpItemWindow:OnePickUp()
	GameHelp.PostServerRequest("RequestPubgPickGood(1,"..tostringEx(self.m_UID)..")")
end


function PickUpItemWindow:OnDestroy()
	
	self.m_listItem ={}
	self.m_serverInfo = nil
	self.m_UID = nil
	UIWindow.OnDestroy(self)
end

function PickUpItemWindow:RefreshUI(nUID, info)
	self.m_UID = nUID
	self.m_serverInfo = info
	if self:isLoaded() then 
		local itemCount = #info
		local currentCount = #self.m_listItem
		for i=1,itemCount do
			if i > currentCount then 
				rkt.GResources.FetchGameObjectAsync(GuiAssetList.ChickingItem.PickUpItem,
				function(path , obj , ud )
					if obj == nil then 
						return
					end
					if self.transform == nil then 
						rkt.GResources.RecycleGameObject(obj)
					end
					obj:SetActive(true)
					obj.transform:SetParent(self.Controls.m_itemParentTrs,false) 
					local pickItem = pickUpItemClass:new()
					table.insert(self.m_listItem,pickItem)
					pickItem:Attach(obj)
					pickItem:RefreshUI(self.m_serverInfo[i],i,self.m_UID)
				end,i, AssetLoadPriority.GuiNormal)
			else
				self.m_listItem[i].transform.gameObject:SetActive(true)
				self.m_listItem[i]:RefreshUI(info[i],i,self.m_UID)
			end
		end
		
		for i=itemCount+1,currentCount do 
			self.m_listItem[i].transform.gameObject:SetActive(false)
		end
	end
	
end

return PickUpItemWindow