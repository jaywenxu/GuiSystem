-------------------------------------------------------------------
-- 版  权:    (C) 深圳冰川网络技术有限公司 2008 - All Rights Reserved
-- 创建人:    方称称
-- 日  期:    2017/06/08
-- 版  本:    1.0
-- 描  述:    货运任务窗口
-------------------------------------------------------------------

local FreightTaskGridCellClass = require( "GuiSystem.WindowList.Task.FreightTask.FreightTaskGridCell" )
local PrizeGridCellClass = require( "GuiSystem.WindowList.Task.TaskPrizeGridCell" )

-- 填装按钮的三个状态：填装、采集、购买、已填装
FreightTaskWindow_FillBtnState_Fill = 1
FreightTaskWindow_FillBtnState_Collect = 2
FreightTaskWindow_FillBtnState_Buy = 3
FreightTaskWindow_FillBtnState_Completed = 4

local FreightTaskWindow = UIWindow:new
{
	windowName = "FreightTaskWindow",
    m_cachedFreightTaskInfo = nil ,
	m_gridInfo = {},      --[1] = { gridId =  ,goodId = , num = , bangong = , yinliang = , exp = , factor = , isCollect = , monsterId = , mapId = , x = , y = z, state = }
	m_gridCell = {},
	m_clickGridId = 1,				-- 被选中的格子id
	m_clickGoodId,					-- 被选中的物品id
	m_fillBtnState = FreightTaskWindow_FillBtnState_Fill,		-- 填装按钮的状态  1：去购买  2：采集  3：填装（物品够的时候）
	m_completeNum = 0,
	m_helpedDBID = nil,				-- nil：正常的填装界面     not nil:帮助者界面
	m_helpedServerId,
	m_helpNum,						-- 帮助次数
	m_expIcon,						-- 整个任务完成的经验奖励
	m_bangongIcon,					-- 整个任务完成的帮贡丹奖励
	m_boxIcon,						-- 整个任务完成的箱子奖励
	m_bangongTxt,					-- 单个采集可获得的帮贡奖励
	m_expTxt,						-- 单个采集可获得的经验奖励
	m_yinliangTxt,					-- 单个采集可获得的银两奖励
    
    m_btnGrayState = {},            -- 按钮灰置状态 1:leftbtn 2:centerbtn 3 rightBtn 用于记录当前的状态，为了解决置灰异步的问题   
    m_reqHelpCDTime = {},           -- 求助cd [gridId] = reqHelpTime
    
    m_timerCallBack,				-- 倒计时定时器
	m_leftTime,						-- 剩余时间（秒）
	m_timer = -1,					--精确计时时刻变量
}
local FreightTaskID = 100 -- 货运任务ID
local FreightTaskHelpCDTime = 60
local this = FreightTaskWindow

function FreightTaskWindow:Init()
	
end

function FreightTaskWindow:OnAttach(obj)
	UIWindow.OnAttach(self,obj)
	
	self.Controls.m_closeBtn.onClick:AddListener( handler(self,self.CloseCallback) )
	self.Controls.m_completeBtn.onClick:AddListener( handler(self,self.CompleteCallback) )
	
	self.Controls.m_iconBtn.onClick:AddListener( handler(self,self.RightIconBtnCallback) )
	self.Controls.m_rightBtn.onClick:AddListener( handler(self,self.FillCallback) )
	self.Controls.m_leftBtn.onClick:AddListener( handler(self,self.HelpCallback) )
	self.Controls.m_centerBtn.onClick:AddListener( handler(self,self.FillCallback) )
	self.Controls.m_hideDetailBtn.onClick:AddListener( handler(self,self.HideDetailCallback) )
	self.Controls.m_detailBtn.onClick:AddListener( handler(self,self.DetailCallback) )
	for i = 1,8 do
		local cellObj = self.Controls.m_grid.transform:Find("Cell" .. i).gameObject
		cellObj:SetActive(true)
		self.m_gridCell[i] = FreightTaskGridCellClass:new()
		self.m_gridCell[i]:Attach(cellObj)
		self.m_gridCell[i]:SetParentWindow(self)
	end
	
	-- 经验奖励图标
	local exprRewardCellObj = self.Controls.m_expIcon.gameObject
	self.m_expIcon = PrizeGridCellClass:new()
	self.m_expIcon:Attach(exprRewardCellObj)
	
	-- 帮贡奖励图标
	local rewardCellObj = self.Controls.m_bangongIcon.gameObject
	self.m_bangongIcon = PrizeGridCellClass:new()
	self.m_bangongIcon:Attach(rewardCellObj)
	
	-- 宝箱奖励图标
	local rewardCellObj = self.Controls.m_boxIcon.gameObject
	self.m_boxIcon = PrizeGridCellClass:new()
	self.m_boxIcon:Attach(rewardCellObj)

    if nil ~= self.m_cachedFreightTaskInfo then
        self:DisplayInfo( self.m_cachedFreightTaskInfo )
        self.m_cachedFreightTaskInfo = nil
    end
	
	--物品增加事件
	self.callback_OnEventAddGoods = function(event, srctype, srcid, eventdata) self:OnEventAddGoods(eventdata) end
	rktEventEngine.SubscribeExecute( EVENT_SKEP_ADD_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventAddGoods)
	--物品减少事件
	self.callback_OnEventRemoveGoods = function(event, srctype, srcid, eventdata) self:OnEventRemoveGoods(eventdata) end
	rktEventEngine.SubscribeExecute( EVENT_SKEP_REMOVE_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventRemoveGoods)
    --小退
    self.callback_OnExitSaveFinish = function(event, srctype, srcid, eventdata) self:OnExitSaveFinish() end
    rktEventEngine.SubscribeExecute(EVENT_SYSTEM_EXITSAVEFINISH, SOURCE_TYPE_SYSTEM, 0, self.callback_OnExitSaveFinish)
end

function FreightTaskWindow:Hide()
    self:StopTimer()
    UIWindow.Hide(self)
end

-- 增加物品处理
function FreightTaskWindow:OnEventAddGoods(eventdata)
	if not self:isShow() or not eventdata then
		return
	end
	
	local entity = IGame.EntityClient:Get(eventdata.uidGoods)
	if not entity then
		return
	end
	local goodId = entity:GetNumProp(GOODS_PROP_GOODSID)
	for k, v in pairs(self.m_gridInfo) do
		if v.goodId == goodId then
			self.m_gridCell[k]:SetGridData(self.m_gridInfo[k],self.m_helpedDBID)
			-- 如果是当前打开的格子更新状态
			if k == self.m_clickGridId then
				self.m_gridCell[k]:OnSelectChanged(true)
			end
		end
	end
end

-- 移除物品处理
function FreightTaskWindow:OnEventRemoveGoods(eventdata)
	if not self:isShow() or not eventdata then
		return
	end
	
	local goodId = eventdata.goodId
	for k, v in pairs(self.m_gridInfo) do
		if v.goodId == goodId or goodId == 0 then
			self.m_gridCell[k]:SetGridData(self.m_gridInfo[k],self.m_helpedDBID)
			-- 如果是当前打开的格子更新状态
			if k == self.m_clickGridId then
				self.m_gridCell[k]:OnSelectChanged(true)
			end
		end
	end
end

-- 关闭按钮
function FreightTaskWindow:CloseCallback()
	self:Hide()
end

-- 完毕提交按钮
function FreightTaskWindow:CompleteCallback()
	-- 检查是否有帮会
	local hero = GetHero()
	local clanId = hero:GetNumProp(CREATURE_PROP_CLANID)
	if clanId == 0 then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "请先加入帮会")
		return
	end
	
	if self.m_completeNum < 8 then
		local confirmCallBack = function ( )
			self:Hide()
			GameHelp.PostServerRequest("RequestFreightTaskGlobal_HuodongClick()")
		end
		local data = 
		{
			content = "你有尚未完成的订单，确定要完成任务吗？（完成所有订单可以获得更多奖励）",
			confirmCallBack = confirmCallBack,
		}	
		UIManager.ConfirmPopWindow:ShowDiglog(data)
	else
		self:Hide()
		GameHelp.PostServerRequest("RequestFreightTaskGlobal_HuodongClick()")
	end
end

-- 点击右边展示图标
function FreightTaskWindow:RightIconBtnCallback()
	local subInfo = {
		bShowBtnType	= 2, 		--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
	}
	UIManager.GoodsTooltipsWindow:SetGoodsInfo(self.m_gridInfo[self.m_clickGridId].goodId, subInfo )
end

-- 填充按钮
function FreightTaskWindow:FillCallback()
	if self.m_clickGridId == nil then
		return
	end
	if self.m_fillBtnState == FreightTaskWindow_FillBtnState_Fill then
		-- 检查是否有帮会
		local hero = GetHero()
		local clanId = hero:GetNumProp(CREATURE_PROP_CLANID)
		if self.m_helpedDBID then  -- 如果是帮助者
			GameHelp.PostServerRequest("RequestFreightIsCanHelpFill(" .. self.m_clickGridId .. "," .. self.m_helpedDBID .. "," .. self.m_helpedServerId .. ")")
		else
			GameHelp.PostServerRequest("RequestFreightFillGrid(" .. self.m_clickGridId ..")")
		end
	elseif self.m_fillBtnState == FreightTaskWindow_FillBtnState_Collect then
		toMapLocAndCollectFreight(self.m_gridInfo[self.m_clickGridId].mapId, self.m_gridInfo[self.m_clickGridId].x, self.m_gridInfo[self.m_clickGridId].y,
							self.m_gridInfo[self.m_clickGridId].z, self.m_gridInfo[self.m_clickGridId].monsterId,
							self.m_gridInfo[self.m_clickGridId].goodId,self.m_gridInfo[self.m_clickGridId].num)
		self:Hide()
	elseif self.m_fillBtnState == FreightTaskWindow_FillBtnState_Buy then
		local subInfo = {
			bShowBtnType	= 2, 	--是否显示按钮(0:不显示,1:显示按钮, 2显示获取途径)
		}
		UIManager.GoodsTooltipsWindow:SetGoodsInfo(self.m_gridInfo[self.m_clickGridId].goodId,subInfo)
	end
end

-- 帮助按钮
function FreightTaskWindow:HelpCallback()
	-- 检查是否有帮会
	local hero = GetHero()
	local clanId = hero:GetNumProp(CREATURE_PROP_CLANID)
	if clanId == 0 then
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "请先加入帮会")
		return
	end
	if self.m_completeNum < 5 then
		return
	end
    
    -- 检查一下求助cd
    local helpTime = self.m_reqHelpCDTime[self.m_clickGridId] or 0
    local curTime = os.time()
    local cdTime = FreightTaskHelpCDTime - (curTime - helpTime)
    if cdTime > 0 then
        IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, "你刚刚进行了求助，请".. cdTime .."s后再试。")
        return
    end
    self.m_reqHelpCDTime[self.m_clickGridId] = curTime
	GameHelp.PostServerRequest("RequestFreightHelpBtn(" .. self.m_clickGridId ..")")
end

-- 帮助信息按钮
function FreightTaskWindow:DetailCallback()
	UIManager.CommonGuideWindow:ShowWindow(20)
	--self.Controls.m_detailContent.gameObject:SetActive(true)
end

-- 隐藏帮助信息按钮
function FreightTaskWindow:HideDetailCallback()
	self.Controls.m_detailContent.gameObject:SetActive(false)
end

-- 显示货运任务信息
function FreightTaskWindow:RequestInfo()
	GameHelp.PostServerRequest("RequestFreightInfo()")
end

-- 显示货运
function FreightTaskWindow:DisplayInfo(freightTaskInfo)
	if freightTaskInfo == nil or type(freightTaskInfo) ~= 'table' then
		uerror("货运任务信息错误")
		return
	end

    if not self:isLoaded() then
        self.m_cachedFreightTaskInfo = freightTaskInfo
        return
    end

	self.m_gridInfo = freightTaskInfo.gridInfo
	self.m_helpedDBID = freightTaskInfo.helpedDBID
	self.m_helpedServerId = freightTaskInfo.helpedServerId
	self.m_helpNum = freightTaskInfo.helpNum			-- 帮助的次数
	-- 如果是帮助者界面
	if freightTaskInfo.helpedDBID then
		self.Controls.m_helpTxt.gameObject:SetActive(true)
		self.Controls.m_helpTxt.text = "今日已帮助填" .. self.m_helpNum .. "/3"
	else
		-- 完成按钮设置为true
		self.Controls.m_helpTxt.gameObject:SetActive(false)
	end
	
	-- 完成的订单数量
	local completeNum = 0
	for i = 1,8 do
		self.m_gridCell[i]:SetGridData(self.m_gridInfo[i],self.m_helpedDBID)
		if self.m_gridInfo[i].state == 1 then
			completeNum = completeNum + 1
			local pTask = IGame.TaskSick:GetAvailableTaskListByID(FreightTaskID)
			local nGoodID = self.m_gridInfo[i].goodId
			if pTask and type(pTask.itemList) == "table" then
				pTask.itemList[nGoodID] = 0
			end
		end
	end
	
	-- 如果完成订单数大于5则
	if completeNum >= 5 and not self.m_helpedDBID then
		self.Controls.m_completeBtn.interactable = true
		UIFunction.SetAllComsGray(self.Controls.m_completeBtn.gameObject,false)
	else
		self.Controls.m_completeBtn.interactable = false
		UIFunction.SetAllComsGray(self.Controls.m_completeBtn.gameObject,true)
	end
	self.m_completeNum = completeNum
	
	-- 奖励信息
	self.m_expIcon:SetPrizeInfoEx(9001,freightTaskInfo.exp)
	self.m_bangongIcon:SetPrizeExEx(freightTaskInfo.bangongId,freightTaskInfo.bangongNum)
	self.m_boxIcon:SetPrizeExEx(freightTaskInfo.boxId,freightTaskInfo.boxNum)
    
    self:SetLeftTime(freightTaskInfo.leftTime)
	
	-- 自动选中一个格子
	self:AutoSelectGrid()
end

-- 选中格子
function FreightTaskWindow:AutoSelectGrid()
	-- 帮助者界面
	if self.m_helpedDBID then
		for i = 1,8 do
			if self.m_gridInfo[i].state == 2 then
				self.m_clickGridId = i
				self.m_gridCell[self.m_clickGridId]:SetSelect(true)
				return
			end
		end
		
		-- 如果没有找到选中的格子
        if self.m_clickGridId then
            self.m_gridCell[self.m_clickGridId]:OnSelectChanged(true)
        end
	else   -- 正常界面
		-- 可填装
		for i = 1,8 do
			if self.m_gridInfo[i].state ~= 1 then
				local goodId = self.m_gridInfo[i].goodId
				local needNum = self.m_gridInfo[i].num
				local hero = GetHero()
				local packetPart = hero:GetEntityPart(ENTITYPART_PERSON_PACKET)
				local ownNum = packetPart:GetGoodNum(goodId)
				if ownNum >= needNum then
					self.m_clickGridId = i
					self.m_gridCell[self.m_clickGridId]:SetSelect(true)
					return
				end
			end
		end
		
		-- 未填装
		for i = 1,8 do
			if self.m_gridInfo[i].state ~= 1 then
				local goodId = self.m_gridInfo[i].goodId
				local needNum = self.m_gridInfo[i].num
				local hero = GetHero()
				local packetPart = hero:GetEntityPart(ENTITYPART_PERSON_PACKET)
				local ownNum = packetPart:GetGoodNum(goodId)
				if ownNum < needNum then
					self.m_clickGridId = i
					self.m_gridCell[self.m_clickGridId]:SetSelect(true)
					return
				end
			end
		end
		-- 如果没有找到选中的格子
		self.m_clickGridId = 1
		self.m_gridCell[self.m_clickGridId]:SetSelect(true)
	end
end

-- i : 第几个格子
function FreightTaskWindow:GridOnClick( i,imgPath,frameImgPath,state,needNum,ownNum,name )
	self.m_clickGridId = i
	self.m_clickGoodId = self.m_gridInfo[i].goodId
	if imgPath then
		UIFunction.SetImageSprite( self.Controls.m_showGoodIcon , imgPath )
	end
	
	if frameImgPath then
		UIFunction.SetImageSprite( self.Controls.m_showGoodFrame , frameImgPath )
	end
	
	if name then
		self.Controls.m_showGoodNameTxt.text = name
	end
	
	-- 奖励显示
	local bangong = NumToWan(self.m_gridInfo[i].bangongCount)
	local exp = NumToWan(self.m_gridInfo[i].exp)
	local yinliang = NumToWan(self.m_gridInfo[i].yinliang)
	self.Controls.m_bangongTxt.text = bangong
	self.Controls.m_expTxt.text = exp
	self.Controls.m_yinliangTxt.text = yinliang
	
	if state ~= 1 then
		if needNum > ownNum then
			self.Controls.m_showGoodTxt.text = "<color=#E4595A>" .. ownNum .. "/" .. needNum .. "</color>"
		else
			self.Controls.m_showGoodTxt.text = "<color=#597993>" .. ownNum .. "/" .. needNum .. "</color>"
		end
	else
		self.Controls.m_showGoodTxt.text = "<color=#597993>已填装</color>"
		self.m_fillBtnState = FreightTaskWindow_FillBtnState_Completed
	end
	
	if self.m_helpedDBID then
		-- 帮助者界面
		self:RightShowHelpPattern(state, needNum, ownNum)
	else 
		-- 正常界面
		if self.m_gridInfo[i].isCollect ~= 0 then
			-- 采集订单
			self:RightShowCollectPattern(state, needNum, ownNum)
		else
			-- 普通订单
			self:RightShowNormalPattern(state, needNum, ownNum)
		end
	end
end

-- 帮助者界面(帮助模式)
function FreightTaskWindow:RightShowHelpPattern(state, needNum, ownNum)
	-- 只显示中间的按钮
	self:SetRightShowLeftButton(false)
	self:SetRightShowCenterButton(true)
	self:SetRightShowRightButton(false)
    
    self.Controls.m_bangZhuIcon.gameObject:SetActive(true)
	if self.m_helpNum >= 3 then
		-- 帮助超过三次，不能再帮助
		self.Controls.m_centerBtn.interactable = false
		self:SetButtonGray(self.Controls.m_centerBtn, true, 2)
	else
		if state ~= 1 then 
			-- 未填装完成
			if needNum > ownNum then
				self.m_fillBtnState = FreightTaskWindow_FillBtnState_Buy
			else
				self.m_fillBtnState = FreightTaskWindow_FillBtnState_Fill
			end
			self:SetButtonGray(self.Controls.m_centerBtn, false, 2)
		else
			self.Controls.m_centerBtn.interactable = false
            self:SetButtonGray(self.Controls.m_centerBtn, true, 2)
		end
	end
end

-- 采集界面(采集模式)
function FreightTaskWindow:RightShowCollectPattern(state, needNum, ownNum)
	-- 只显示中间的按钮
	self:SetRightShowLeftButton(false)
	self:SetRightShowCenterButton(true)
	self:SetRightShowRightButton(false)
	
	if state ~= 1 then
		-- 未填装完成
		if needNum > ownNum then
			-- 采集
			self.Controls.m_collectIcon.gameObject:SetActive(true)
			self.m_fillBtnState = FreightTaskWindow_FillBtnState_Collect
		else
			-- 填货
			self.Controls.m_centerFillIcon.gameObject:SetActive(true)
			self.m_fillBtnState = FreightTaskWindow_FillBtnState_Fill
		end
        self:SetButtonGray(self.Controls.m_centerBtn, false, 2)
	else
		-- 已填装
		self.Controls.m_centerFillIcon.gameObject:SetActive(true)
		self.Controls.m_centerBtn.interactable = false
        self:SetButtonGray(self.Controls.m_centerBtn, true, 2)
	end
end

-- 普通物品
function FreightTaskWindow:RightShowNormalPattern(state, needNum, ownNum)
	-- 隐藏中间的按钮
	self:SetRightShowLeftButton(true)
	self:SetRightShowCenterButton(false)
	self:SetRightShowRightButton(true)
	
	-- 左侧按钮显示
	if self.m_completeNum < 5 then
		-- 完成5个以下 求助显示灰置
		self.Controls.m_helpIcon.gameObject:SetActive(true)
		self.Controls.m_leftBtn.interactable = false
        self:SetButtonGray(self.Controls.m_leftBtn, true, 1)
	else
		-- 完成5个以上订单寻求帮助
		if state ~= 1 then
			self.Controls.m_helpCount.gameObject:SetActive(true)
            self:SetButtonGray(self.Controls.m_leftBtn, false, 1)
		else
			self.Controls.m_helpIcon.gameObject:SetActive(true)
			self.Controls.m_leftBtn.interactable = false
            self:SetButtonGray(self.Controls.m_leftBtn, true, 1)
		end
		self.Controls.m_helpCountTxt.text = (self.m_helpNum or 0) .. "/3"
	end
	
	-- 右侧按钮显示
	if state ~= 1 then
		if needNum > ownNum then
			-- 去购买
			self.Controls.m_gouMaiIcon.gameObject:SetActive(true)
			self.m_fillBtnState = FreightTaskWindow_FillBtnState_Buy
		else
			-- 填货
			self.Controls.m_rightFillIcon.gameObject:SetActive(true)
			self.m_fillBtnState = FreightTaskWindow_FillBtnState_Fill
		end
        self:SetButtonGray(self.Controls.m_rightBtn, false, 3)
	else
		self.Controls.m_rightFillIcon.gameObject:SetActive(true)
		self.Controls.m_rightBtn.interactable = false
        self:SetButtonGray(self.Controls.m_rightBtn, true, 3)
	end
end

-- 设置按钮灰置 1leftbtn 2centerbtn 3rightbtn
function FreightTaskWindow:SetButtonGray(btn, flag, btnPos)
	if (flag and not self.m_btnGrayState[btnPos]) or (not flag and self.m_btnGrayState[btnPos]) then
        UIFunction.SetAllComsGray(btn.gameObject, flag)
        self.m_btnGrayState[btnPos] = flag
	end
end


-- 设置按钮状态
function FreightTaskWindow:SetRightShowLeftButton(flag)
	if not flag then
		self.Controls.m_leftBtn.gameObject:SetActive(false)
		self.Controls.m_leftBtn.interactable = false
	else
		self.Controls.m_leftBtn.gameObject:SetActive(true)
		-- 隐藏计数的求助
		self.Controls.m_helpCount.gameObject:SetActive(false)
		-- 隐藏不计数的求助
        self.Controls.m_helpIcon.gameObject:SetActive(false)
		self.Controls.m_leftBtn.interactable = true
	end
end

-- 设置按钮状态
function FreightTaskWindow:SetRightShowCenterButton(flag)
	if not flag then
		self.Controls.m_centerBtn.gameObject:SetActive(false)
		self.Controls.m_centerBtn.interactable = false
	else
		self.Controls.m_centerBtn.gameObject:SetActive(true)
		-- 按钮下的三个图标都隐藏
		self.Controls.m_collectIcon.gameObject:SetActive(false)
		self.Controls.m_centerFillIcon.gameObject:SetActive(false)
		self.Controls.m_bangZhuIcon.gameObject:SetActive(false)
		self.Controls.m_centerBtn.interactable = true
	end
end

-- 设置按钮状态
function FreightTaskWindow:SetRightShowRightButton(flag)
	if not flag then
		self.Controls.m_rightBtn.gameObject:SetActive(false)
		self.Controls.m_rightBtn.interactable = false
	else
		self.Controls.m_rightBtn.gameObject:SetActive(true)
		-- 按钮下的两个图标都隐藏
		self.Controls.m_rightFillIcon.gameObject:SetActive(false)
        self.Controls.m_gouMaiIcon.gameObject:SetActive(false)
		self.Controls.m_rightBtn.interactable = true
	end
end

-- 显示剩余时间
function FreightTaskWindow:SetLeftTime(leftTime)
    self.m_leftTime = leftTime
    self.m_timer = luaGetTickCount()
    if self.m_timerCallBack then
        rktTimer.KillTimer(self.m_timerCallBack)
    end
	self.m_timerCallBack = function() --倒计时timer
		local curTime = luaGetTickCount()
		local passTime = curTime - self.m_timer		
		self.m_timer = curTime
		self.m_leftTime = self.m_leftTime - passTime / 1000
		if self.m_leftTime < 0 then
			self:StopTimer()
			return
		end
        -- 分钟向上取整
		self.Controls.m_timeTxt.text =  GetCDTime(self.m_leftTime+59, 6, 1) .. "后过期"
	end
    -- 第一次主动调用
    self.m_timerCallBack()
	rktTimer.SetTimer(self.m_timerCallBack, 1000, -1, "FreightTaskWindow")
end

-- 关闭定时器
function FreightTaskWindow:StopTimer()
	if self.m_timerCallBack ~= nil then
		rktTimer.KillTimer(self.m_timerCallBack)
        self.m_timer = nil
        self.m_leftTime = nil
		self.m_timerCallBack = nil
	end
end

-- 小退
function FreightTaskWindow:OnExitSaveFinish()
    self.m_reqHelpCDTime = {}
end

function FreightTaskWindow:OnDestroy()
	--物品增加事件
	rktEventEngine.UnSubscribeExecute( EVENT_SKEP_ADD_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventAddGoods)
    self.callback_OnEventAddGoods = nil
	--物品减少事件
	rktEventEngine.UnSubscribeExecute( EVENT_SKEP_REMOVE_GOODS, SOURCE_TYPE_SKEP, 0, self.callback_OnEventRemoveGoods)
    self.callback_OnEventRemoveGoods = nil
    --小退
    rktEventEngine.SubscribeExecute(EVENT_SYSTEM_EXITSAVEFINISH, SOURCE_TYPE_SYSTEM, 0, self.callback_OnExitSaveFinish)
    self.callback_OnExitSaveFinish = nil
    
    self.m_btnGrayState = {}
end

return FreightTaskWindow