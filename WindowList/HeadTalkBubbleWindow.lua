--头顶泡泡窗口
------------------------------------------------------------
local HeadTalkBubbleWindow = UIWindow:new
{
	windowName = "HeadTalkBubbleWindow",
	
	--	entityView = nil,talkStr = nil,entityUid = nil 

	bubbleCellList =
	{
		
	}

}

local ContentSizeFitter = require("UnityEngine.UI.ContentSizeFitter")
local keepTime = 5000 --2s 

local cellWidth = 320

function HeadTalkBubbleWindow:OnAttach(obj)
	UIWindow.OnAttach(self,obj)
	self:SetParentAndShow(obj)
	self.DestoryEntityFun =function(event, srctype, srcid, eventData) self:DestoryEntity(eventData) end  
	self.BubbleCellLoad = function(path , obj , uid) self:BubbleCellLoaded(path , obj , uid) end
	local count =#self.bubbleCellList
	
	for k,v in pairs(self.bubbleCellList) do 
		self:ShowTalkStrWithUid(k,v.text)
	end
	
	
end

function HeadTalkBubbleWindow:DestoryEntity(eventData)
	local obj = self.bubbleCellList[eventData]
	self:RecyleBubbleItem(obj)
end

--挂载
function HeadTalkBubbleWindow:SetParentAndShow(obj)
	UIManager.AttachToLayer( obj , UIManager._BackgroundLayer ) 
	obj.transform:SetAsLastSibling()
end


function HeadTalkBubbleWindow:ShowTalkStrWithUid(uid,Str,stayTime)
	if self.bubbleCellList[tostring(uid)] == nil then 
		self.bubbleCellList[tostring(uid)] ={}
	else
		self:RecyleBubbleItem(self.bubbleCellList[tostring(uid)].obj)
	end
	keepTime = stayTime or keepTime
	local entityView = rkt.EntityView.GetEntityView(uid)
	self.bubbleCellList[tostring(uid)].text = Str
	self.bubbleCellList[tostring(uid)].uid = uid
	self:Show()
	if self:isLoaded() then 
		rkt.GResources.FetchGameObjectAsync( GuiAssetList.BubbleCell ,self.BubbleCellLoad, tostring(uid) , AssetLoadPriority.GuiNormal )
	end
end



function HeadTalkBubbleWindow:BubbleCellLoaded(path , obj , uid)

	if nil == obj then
        return
    end
    local str = self.bubbleCellList[uid].text
    if nil == str then
        rkt.GResources.RecycleGameObject(obj)
        return
    end
	local entityView = rkt.EntityView.GetEntityView(self.bubbleCellList[uid].uid)
	if entityView == nil then 
		return
	end
	
	self.bubbleCellList[uid].obj = obj
	obj.transform:SetParent(self.transform,false)
	local worldPosToScreen = UIWorldPositionToScreen.Get(obj)
	worldPosToScreen.UICamera = UIManager.FindUICamera()
	local heroHeight = 0
	if nil ~= entityView then
		heroHeight = entityView:GetFloat(EntityPropertyID.EntityHeight)
	end
	rktEventEngine.SubscribeExecute( EVENT_ENTITY_DESTROYENTITY , SOURCE_TYPE_PERSON , 	uid, self.DestoryEntity, self)
	local height =  UIManager.NameTitleWindow:GetNameMaxHeight(uid)
	local offsetY = heroHeight + height + 0.2
	worldPosToScreen.WorldOffset = Vector3.New(0, offsetY , 0 )
	worldPosToScreen.WorldTransform = entityView.transform
	local text = obj.transform:Find("Text"):GetComponent(typeof(Text))
	local rect = rkt.UIAndTextHelpTools.GetRichTextSize(text,str)
	local fiter = text.transform:GetComponent(typeof(ContentSizeFitter))
	local chatText,FunText,maxHeight = RichTextHelp.AsysSerText(str,Chat_Emoji_High)

	if rect.y <= (maxHeight+maxHeight/2 )then 
		fiter.horizontalFit = ContentSizeFitter.FitMode.PreferredSize 
		text.transform.sizeDelta = Vector2.New(rect.x,rect.y)
	else
		fiter.horizontalFit = ContentSizeFitter.FitMode.Unconstrained
		text.transform.sizeDelta = Vector2.New(cellWidth,rect.y)
	end
	text.text= str
	if obj ~= nil then 
		local anim = obj:GetComponent(typeof(DG.Tweening.DOTweenAnimation))
		if anim ~= nil then 
			anim:DORestart(false)
		end
		local timeDuring = anim.duration + anim.delay
		rktTimer.SetTimer( function() self:RecyleBubbleItem(obj) end,tonumber(timeDuring*1000) ,1,"")
	end 
end




function HeadTalkBubbleWindow:RecyleBubbleItem(obj)
	if obj ~= nil then 
		rkt.GResources.RecycleGameObject(obj)
	end 
end

function HeadTalkBubbleWindow:OnDestroy()
		local count = #self.bubbleCellList
		for i=1,count do 
			self:RecyleBubbleItem(self.bubbleCellList[i].obj)
		end
		self.bubbleCellList ={}
		if self.entityView ~=nil then 
			rktEventEngine.UnSubscribeExecute( EVENT_ENTITY_DESTROYENTITY , SOURCE_TYPE_PERSON , self.entityView.EntityId, self.DestoryEntity, self)
		end
	
		UIWindow.OnDestroy(self)
end

return HeadTalkBubbleWindow