--******************************************************************
--** 文件名:	QiyuWdt.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-11-2
--** 版  本:	1.0
--** 描  述:	奇遇系统
--** 应  用:  
--******************************************************************

local AdventureTypeClass = require("GuiSystem.WindowList.HuoDong.QiyuSystem.AdventureTypeItem")

local tTaskType = 
{
	"江湖奇遇",
	"人物奇遇",
	"历    练",
	"风    景",
}

local QiyuWidget = UIControl:new
{
	windowName	= "QiyuWidget",
	m_TypeTlgGroup = nil,
}

function QiyuWidget:Attach(obj)
	UIControl.Attach(self, obj)
	
	self.m_TypeTlgGroup = self.Controls.m_TypeGrid:GetComponent(typeof(ToggleGroup))
	
	self.unityBehaviour.onEnable:AddListener(handler(self, self.OnEnable))

	self:CreateTypeList()
end

function QiyuWidget:InitData()
	
end

function QiyuWidget:CreateTypeList()
	
	local callback = function(path , obj , idx)
		--TODO: 设置父对象
		obj.transform:SetParent(self.Controls.m_TypeGrid.transform, false)
		
		--TODO: 绑定脚本
		local item = AdventureTypeClass:new({})
		item:Attach(obj)
		
		--TODO: 设置ToggleGroup
		item:SetToggleGroup(self.m_TypeTlgGroup)
		
		--TODO: 设置SelectCallback
		item:SetSelectCallback(handler(self, self.SwitchType))
		
		--TODO: 设置ItemData
		item:SetItemData(obj)
		
	end
	
	for k, v in pairs(tTaskType) do
		rkt.GResources.FetchGameObjectAsync(GuiAssetList.Adventure.AdventureTypeItem ,callback, k, AssetLoadPriority.GuiNormal)
	end
end

function QiyuWidget:OnEnable()
	
end

function QiyuWidget:SwitchType(on)
	print("[QiyuWidget:SwitchType]", tostring(on))
	
	--TODO: 收拢当前类型
	
	--TODO: 展开选中类型
	
end

return QiyuWidget


