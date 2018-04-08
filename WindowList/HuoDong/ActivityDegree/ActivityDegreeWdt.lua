--/******************************************************************
---** 文件名:	HuoDongWindow.Lua
--** 版  权:	(C)  深圳冰川网络技术有限公司
--** 创建人:	lj.zhou
--** 日  期:	2017-03-17
--** 版  本:	1.0
--** 描  述:	活跃度窗口
--** 应  用:  
--******************************************************************/

------------------------------------------------------------
local ActivityDegreeWdt = UIControl:new
{
	windowName = "ActivityDegreeWdt",
	m_BoxBtns = {},
}

local BoxValue = {
	Box_20 = 20,
	Box_40 = 40,
	Box_60 = 60,
	Box_80 = 80,
	Box_100 = 100,
}

local ImagePath = {
	AssetPath.TextureGUIPath.."Activity/Activity_icon_baoxiang1_1.png",
	AssetPath.TextureGUIPath.."Activity/Activity_icon_baoxiang1_2.png",
	AssetPath.TextureGUIPath.."Activity/Activity_icon_baoxiang1_3.png",
	AssetPath.TextureGUIPath.."Activity/Activity_icon_baoxiang2_1.png",
	AssetPath.TextureGUIPath.."Activity/Activity_icon_baoxiang2_2.png",
	AssetPath.TextureGUIPath.."Activity/Activity_icon_baoxiang2_3.png",
	AssetPath.TextureGUIPath.."Activity/Activity_icon_baoxiang2_1.png",
	AssetPath.TextureGUIPath.."Activity/Activity_icon_baoxiang2_2.png",
	AssetPath.TextureGUIPath.."Activity/Activity_icon_baoxiang2_3.png",
	AssetPath.TextureGUIPath.."Activity/Activity_icon_baoxiang3_1.png",
	AssetPath.TextureGUIPath.."Activity/Activity_icon_baoxiang3_2.png",
	AssetPath.TextureGUIPath.."Activity/Activity_icon_baoxiang3_3.png",
	AssetPath.TextureGUIPath.."Activity/Activity_icon_baoxiang4_1.png",
	AssetPath.TextureGUIPath.."Activity/Activity_icon_baoxiang4_2.png",
	AssetPath.TextureGUIPath.."Activity/Activity_icon_baoxiang4_3.png",
}

function ActivityDegreeWdt:Attach(obj)
	UIControl.Attach(self, obj)
	
	--唤醒 子控件	
	self:InitSubObjs()
	
	--注册窗口限时回调
    self.unityBehaviour.onEnable:AddListener(handler(self, self.OnEnable))
	
	--宝箱点击事件
	self.m_BoxBtns = {
		self.Controls.m_Box_20,
		self.Controls.m_Box_40,
		self.Controls.m_Box_60,
		self.Controls.m_Box_80,
		self.Controls.m_Box_100,
	}

	for i = ACTIVEBOX_START_INDEX, ACTIVEBOX_END_INDEX do
		self.m_BoxBtns[i].onClick:AddListener(function() self:OnBoxClick(i) end)
	end
			
	self:InitDisplay()
    
    self:SubscribeExecute()
end

function ActivityDegreeWdt:InitSubObjs()
	self.m_BoxRewardWidget = require("GuiSystem.WindowList.HuoDong.ActivityDegree.ActiveBoxWidget")
	self.m_BoxRewardWidget:Attach(self.Controls.m_BoxDesc.gameObject)

	self.m_TaskListWidget  = require("GuiSystem.WindowList.HuoDong.ActivityDegree.ActiveTaskWidget")
	self.m_TaskListWidget:Attach(self.Controls.m_ActivityList.gameObject)	
end

function ActivityDegreeWdt:SubscribeExecute()
	
	--人物属性更新监听
	self.callback_updateprop = function(_, _, _, eventdata) self:UpdateProp(_, _, _, eventdata) end
	rktEventEngine.SubscribeExecute(EVENT_ENTITY_UPDATEPROP, SOURCE_TYPE_PERSON, 0, self.callback_updateprop)

	--活动状态更新监听
	self.callback_UpdateTimes = function(_, _, _, eventdata) self:UpdateTimes(_, _, _, eventdata) end
	rktEventEngine.SubscribeExecute(EVENT_ACTIVITY_LIST_UPDATE, SOURCE_TYPE_ACTIVITY, 0, self.callback_UpdateTimes)
	
	--宝箱状态更新监听
	self.callback_UpdateStatus = function(_, _, _, eventdata) self:UpdateBoxStatus(_, _, _, eventdata) end
	rktEventEngine.SubscribeExecute(EVENT_ACTIVE_BOX_STATUS_UPDATE, SOURCE_TYPE_ACTIVITY, 0, self.callback_UpdateStatus)

end

function ActivityDegreeWdt:UnSubscribeExecute()
   
    rktEventEngine.UnSubscribeExecute(EVENT_ENTITY_UPDATEPROP, SOURCE_TYPE_PERSON, 0, self.callback_updateprop)
	rktEventEngine.UnSubscribeExecute(EVENT_ACTIVITY_LIST_UPDATE, SOURCE_TYPE_ACTIVITY, 0, self.callback_UpdateTimes)    
    rktEventEngine.UnSubscribeExecute(EVENT_ACTIVE_BOX_STATUS_UPDATE, SOURCE_TYPE_ACTIVITY, 0, self.callback_UpdateStatus)

end

function ActivityDegreeWdt:OnEnable()
	
	self:UpdateBoxInfo()

	self.m_TaskListWidget:ReloadData()
end

function ActivityDegreeWdt:InitDisplay()
	
	local nCurActive = GetHero():GetNumProp(CREATURE_PROP_ACTIVITY)
    
	self.Controls.m_Fill.fillAmount = nCurActive / 100
	self.Controls.m_CurValue.text = tostring(nCurActive)
	
	self.m_BoxRewardWidget:SetIWidgetInfo(ACTIVEBOX_STEP_VALUE)
	
	self:UpdateBoxInfo()
end

function ActivityDegreeWdt:OnBoxClick(Idx)
	if Idx < ACTIVEBOX_START_INDEX or Idx > ACTIVEBOX_END_INDEX then
		return
	end
	
	local status = IGame.ActivityList:GetBoxStatus(Idx)
	
	local nValue = Idx * ACTIVEBOX_STEP_VALUE
	self.m_BoxRewardWidget:SetIWidgetInfo(nValue)

	local nCurActive = GetHero():GetNumProp(CREATURE_PROP_ACTIVITY)
	if nCurActive < nValue then
		return
	end

	GameHelp.PostServerRequest("RequestActiveBox("..Idx..")")
end

function ActivityDegreeWdt:UpdateProp(_, _, _, MsgData)
    -- 检查是不是活跃度更新
	for i = 1, MsgData.nPropCount do
		if MsgData.propData[i].nPropID == CREATURE_PROP_ACTIVITY then
            
            self.Controls.m_Fill.fillAmount = GetHero():GetNumProp(CREATURE_PROP_ACTIVITY) / 100
            
            self.Controls.m_CurValue.text = tostring(GetHero():GetNumProp(CREATURE_PROP_ACTIVITY))
            
            self:UpdateBoxInfo()
		end
	end 
end

function ActivityDegreeWdt:UpdateTimes()
	
	self.m_TaskListWidget:ReloadData()
end

function ActivityDegreeWdt:UpdateBoxStatus()
	self:UpdateBoxInfo()
end

function ActivityDegreeWdt:UpdateBoxInfo()
       
	local nCurActive = GetHero():GetNumProp(CREATURE_PROP_ACTIVITY)
	
	for i = ACTIVEBOX_START_INDEX, ACTIVEBOX_END_INDEX do 
		local path  = ""
		
        local status = IGame.ActivityList:GetBoxStatus(i)
		if 0 ~= status then
			path = ImagePath[i*3]
		else
			if nCurActive >= i * ACTIVEBOX_STEP_VALUE then
				path = ImagePath[i*3 - 1]
			else
				path = ImagePath[i*3 - 2]
			end
		end
		        
		local image = self.m_BoxBtns[i].transform:Find("Icon"):GetComponent(typeof(Image))
		UIFunction.SetImageSprite(image, path)
	end
end

function ActivityDegreeWdt:OnDestroy()
    
    self:UnSubscribeExecute()
    
    self.m_BoxBtns ={}
    
	UIControl.OnDestroy(self)  
end

return ActivityDegreeWdt