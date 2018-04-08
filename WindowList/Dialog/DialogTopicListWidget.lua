------------------------------------------------------------
-- DialogScenarioWindow 的子窗口,不要通过 UIManager 访问
-- 剧情对话
------------------------------------------------------------


local DialogTopicListCellClass = require( "GuiSystem.WindowList.Dialog.DialogTopicListCell" )
------------------------------------------------------------
local DialogTopicListWidget = UIControl:new
{
	windowName = "DialogTopicListWidget",
	m_npc = 0,
	m_npcid = 0,
	m_topiclist = {},
    m_confitSize = nil,
}

local this = DialogTopicListWidget   -- 方便书写


------------------------------------------------------------
-- UIWindowBehaviour 序列化关联的对象
------------------------------------------------------------
function DialogTopicListWidget:Attach( obj )
	UIControl.Attach(self,obj)
	self.Controls.Scroll = self.Controls.TopicListAreaScroll:GetComponent(typeof(UnityEngine.UI.ScrollRect))
	self.Controls.ToggleGroup = self.Controls.TopicListArea.transform:GetComponent(typeof(ToggleGroup))

    self.m_confitSize = self.Controls.TopicListArea:GetComponent(typeof(rkt.UIFitControlSize))

	return self
end

function DialogTopicListWidget:OnDestroy()
	
	
end

function DialogTopicListWidget:SetParentWindow(win)
	self.m_ParentWindow = win
end


function DialogTopicListWidget:OnCloseWindow()
	self:ClearTopicInfo()
	self:RecoveryTopicCell()
end

-----------------------------------------------------------
-- 清空任务npc对话数据
function DialogTopicListWidget:ClearTopicInfo()

	self.m_npc = 0
	self.m_npcid = 0
	self.m_topiclist = {}
    self.m_confitSize = nil
end

-----------------------------------------------------------
-- 回收对话单元
function DialogTopicListWidget:RecoveryTopicCell()
	
	if self.Controls.TopicListArea.transform  then
		local nCount = self.Controls.TopicListArea.transform.childCount
		if nCount >= 1 then
			local tmpTable = {}
			for i = 1, nCount, 1 do
				table.insert(tmpTable,self.Controls.TopicListArea.transform:GetChild(i-1).gameObject)
			end
			for i, v in pairs(tmpTable) do
				rkt.GResources.RecycleGameObject(v)
			end
		end
	end
end

------------------------------------------------------------
-- 显示npc对白信息
function DialogTopicListWidget:ShowTopicList(npc,npcid,topiclist)
	
	if not topiclist  then
		return
	end
	self:ClearTopicInfo()
	
	self.transform.gameObject:SetActive(false)	
	
    if nil == self.Controls.Scroll then 
		self.Controls.Scroll = self.Controls.TopicListAreaScroll:GetComponent(typeof(UnityEngine.UI.ScrollRect))
	end
    
	self.m_npc = npc
	self.m_npcid = npcid
	copy_table(self.m_topiclist, topiclist)
	
	local ntopic = 0
	-- 回收
	self:RecoveryTopicCell()
    if self.m_confitSize == nil then 
	    self.m_confitSize = self.Controls.TopicListArea:GetComponent(typeof(rkt.UIFitControlSize))
	end
    if self.m_confitSize ~= nil then 
        self.m_confitSize.enabled =true
	end
	 self.Controls.Scroll.verticalNormalizedPosition=0
    local tableCount = table_count(self.m_topiclist)
	self.Controls.Scroll.movementType = UnityEngine.UI.ScrollRect.MovementType.Clamped 
	for i,v in pairs(self.m_topiclist) do
		
		rkt.GResources.FetchGameObjectAsync( GuiAssetList.DialogTopicListCell ,
		function ( path , obj , ud )
            if nil == self.Controls.TopicListArea.transform.gameObject then   -- 判断U3D对象是否已经被销毁
                rkt.GResources.RecycleGameObject(obj)
                return
            end
                
            obj.transform:SetParent(self.Controls.TopicListArea.transform,false)
            local itemtask = DialogTopicListCellClass:new({})
            itemtask:Attach(obj)
            itemtask:SetItemInfo(v)
            if self.Controls.TopicListArea.transform.childCount == tableCount then
				rktTimer.SetTimer(function()  self.Controls.Scroll.verticalNormalizedPosition =1 end ,30,1,"")
            end
		end , i , AssetLoadPriority.GuiNormal )
		ntopic = ntopic + 1
	end
    
	if table_count(self.m_topiclist) > 5 then 
		self.Controls.Scroll.movementType = UnityEngine.UI.ScrollRect.MovementType.Elastic
        self.m_confitSize.enabled =false
        self.Controls.m_bg.sizeDelta= Vector2.New(371,384)
        self.Controls.m_moreTopic.gameObject:SetActive(true)
    else
        self.Controls.m_moreTopic.gameObject:SetActive(false)
	end
        
	if ntopic > 0 then
		self.transform.gameObject:SetActive(true)
	end
end
------------------------------------------------------------

return this