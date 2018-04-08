-- 休息室条目元素
-- @Author: XieXiaoMei
-- @Date:   2017-06-07 15:22:00
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-09-12 17:27:16

------------------------------------------------------------
local LoungeCell = UIControl:new
{
	windowName 	= "LoungeCell",
	m_ActID 	= 0,
}

local this = LoungeCell
------------------------------------------------------------

-- 附加初始化
function LoungeCell:Attach(obj)
	UIControl.Attach(self,obj)

	self:AddListener( self.Controls.m_ApplyBtn , "onClick" , self.OnBtnApplyClicked , self )
end

-- 设置填充数据
function LoungeCell:SetData(data, idx, timeID)
	local controls = self.Controls

	local bApllyIng = (tonumber(data.TimeID) == timeID )

	local today = os.date("*t")
	local startTime = split_string(data.StartTime, ":")
	local startHour = tonumber(startTime[1])
	local startMin = tonumber(startTime[2])
	
	local bOverdue = true
	if startHour > today.hour then
		bOverdue = false
	elseif startHour == today.hour and startMin >= today.min then
		bOverdue = false
	end

	local str = bOverdue and "已结束" or "未开始"

	controls.m_ActIDTxt.text = idx
	
	
	local preTime = split_string(data.PreStartTime, ":")
	local strStartTime = startTime[1]..":"..startTime[2]
	local strPreTime = preTime[1]..":"..preTime[2] 
	controls.m_ApplyTimeTxt.text = strPreTime .." - ".. strStartTime
	controls.m_StartTimeTxt.text = strStartTime

	local str = bApllyIng and "参 加" or str
	controls.m_StateTxt.text = str

	controls.m_ApplyBtn.enabled = bApllyIng
	if bApllyIng then
		UIFunction.SetImageGray(controls.m_BtnImg , not bApllyIng )
	end
	
	local bActOver = false
	local color = UIFunction.ConverRichColorToColor("9C6F57")
	
	if str == "已结束"  then
		bActOver = true
		color = Color.red
	
	elseif str == "未开始" then
		bActOver = true
		color = UIFunction.ConverRichColorToColor("5A7693")
	end
	controls.m_ApplyBtn.gameObject:SetActive(not bActOver)
	controls.m_StateTxt.color = color

	self.m_ActID = tonumber(data.ActID)
end

-- 报名
function LoungeCell:OnBtnApplyClicked()
	if self.m_ActID < 1 then
		return
	end

	GameHelp.PostServerRequest("RequestReadyRoom_Enter("..self.m_ActID..")")	

	UIManager.LoungeWindow:Hide()
end

-- 回收
function LoungeCell:Recycle()
	rkt.GResources.RecycleGameObject(self.transform.gameObject)

	self.m_ActID = 0
end

-- 销毁
function LoungeCell:OnDestroy()
	UIControl.OnDestroy(self)

	self.m_ActID = 0
end

return this



