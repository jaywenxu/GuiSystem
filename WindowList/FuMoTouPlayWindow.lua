--/******************************************************************
--** 文件名:    FuMoTouPlayWindow.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-07-11
--** 版  本:    1.0
--** 描  述:    伏魔骰投掷界面
--** 应  用:  
--******************************************************************/

local FuMoTouPlayWindow = UIWindow:new
{
    windowName = "FuMoTouPlayWindow",	-- 窗口名称
    
	m_IsWindowInvokeOnShow = false,    	-- 窗口是否调用了OnWindowShow方法的标识:boolean
	m_IsTimerOpen = false,				-- 是否开启了定时器的标识:boolean
	m_HadCreateDice = false,			-- 是否已经创建了骰子的标识:number
	m_DiceResultPoint = {},				-- 骰子的结果点数:number

	m_RunTime = 0,						-- 骰子投掷已进行的时间:number
	
	m_DoAniTimerAction = nil,			-- 动画定时器的行为:function
	m_DoOnDiceStartAction = nil,		-- 投掷骰子开始的行为:function
	m_DoOnDiceEndAction = nil,			-- 投掷骰子结束的行为:function
	
	m_ArrDiceGo = {},					-- 骰子实体集合:table(GameObject)
}

function FuMoTouPlayWindow:Init()

	
	
end

function FuMoTouPlayWindow:OnAttach( obj )
	
    UIWindow.OnAttach(self, obj)
	
	self.m_DoOnDiceStartAction = function() self:OnDiceStart() end
	self.m_DoOnDiceEndAction = function() self:OnDiceEnd() end
	
    if self.m_IsWindowInvokeOnShow then
        self.m_IsWindowInvokeOnShow = false
        self:OnWindowShow()
    end
	
    return self
	
end


function FuMoTouPlayWindow:_showWindow()
	
    UIWindow._showWindow(self)
    if self:isLoaded() then
        self:OnWindowShow()
    else
        self.m_IsWindowInvokeOnShow = true
    end
	
end

-- 显示窗口
-- @diceResultPoint:骰子结果点数:number
function FuMoTouPlayWindow:ShowWindow(nNumber1,nNumber2,nNumber3)
	local total = nNumber1+ nNumber2+nNumber3
	if total <3 or total > 18 then
		uerror("服务器随机骰子点数有问题，不应该存在"..total.."点的点数!")
		return
	end
	self.m_DiceResultPoint={}
	table.insert(self.m_DiceResultPoint,nNumber1)
	table.insert(self.m_DiceResultPoint,nNumber2)
	table.insert(self.m_DiceResultPoint,nNumber3)
	
    UIWindow.Show(self, true)

end

-- 窗口每次打开执行的行为
function FuMoTouPlayWindow:OnWindowShow()
	
	if not self.m_HadCreateDice then
		-- 创建骰子
		self:CreateDice()
		return
	end
	
	-- 未创建完
	if #self.m_ArrDiceGo < 3 then
		return
	end
	
	-- 播放骰子动画
	self:PlayDice()
	
end

-- 创建骰子
function FuMoTouPlayWindow:CreateDice()
	
	if self.m_HadCreateDice then
		return
	end
	
	self.m_HadCreateDice = true
	
	local dicePath = "Assets/AssetFolder/CharacterAsset/Prefabs/Monster/monster/monster_SZ.prefab"
	for diceIdx = 1, 3 do
		rkt.GResources.FetchGameObjectAsync( dicePath ,
        function ( path , obj , ud )
			
			obj.transform:SetParent(self.Controls.m_TfDiceModelNode.transform, false)
			obj.transform.localScale = Vector3.one
			obj.gameObject:SetActive(false)
			obj.layer = LayerMask.NameToLayer("UI")
			
			table.insert(self.m_ArrDiceGo, obj)

			-- 创建完了
			if #self.m_ArrDiceGo == 3 then
				-- 播放骰子动画
				self:PlayDice()
			end
			
        end , "", AssetLoadPriority.GuiNormal)
	end	
	
end

-- 设置骰子的角度控制结果点数
function FuMoTouPlayWindow:SetDiceRotToControlResultPoint()
	
	local ARR_DICE_POINT_ANGLE = {}
	ARR_DICE_POINT_ANGLE[1] = Vector3.New(0, 0, 0)
	ARR_DICE_POINT_ANGLE[2] = Vector3.New(90, 0, 0)
	ARR_DICE_POINT_ANGLE[3] = Vector3.New(0, 90, 0)
	ARR_DICE_POINT_ANGLE[4] = Vector3.New(0, -90, 0)
	ARR_DICE_POINT_ANGLE[5] = Vector3.New(-90, 0, 0)
	ARR_DICE_POINT_ANGLE[6] = Vector3.New(0, 180, 0)
	
	-- 旋转设置
	for diceIdx	 = 1, 3 do
		local goDice = self.m_ArrDiceGo[diceIdx]
		local tfChild = goDice.transform:GetChild(0)
		local rot = ARR_DICE_POINT_ANGLE[self.m_DiceResultPoint[diceIdx]]
		tfChild.localRotation =  Quaternion.Euler(rot.x, rot.y, rot.z)
	end
	
end

-- 播放骰子动画
function FuMoTouPlayWindow:PlayDice()
	
	local ARR_DICE_ANI_NAME = 
	{
		"stand", "stand_01", "stand_02"
	}
	
	-- 设置骰子的角度控制结果点数
	self:SetDiceRotToControlResultPoint()
	
	for diceIdx = 1, 3 do
		local goDice = self.m_ArrDiceGo[diceIdx]
		goDice:SetActive(true)
		
		local animator = goDice:GetComponent("Animator")
		animator:Play(ARR_DICE_ANI_NAME[diceIdx])
	end
	
	--rktTimer.SetTimer(self.m_DoOnDiceStartAction, 1000, 1, "FuMoTouPlayWindow:OnDiceStart")
	rktTimer.SetTimer(self.m_DoOnDiceEndAction, 3000, 1, "FuMoTouPlayWindow:OnDiceEnd")
	
end

-- 投掷骰子开始执行的行为
function FuMoTouPlayWindow:OnDiceStart()
	
	print("OnDiceStart")
	
end
 

-- 投掷骰子结束执行的行为
function FuMoTouPlayWindow:OnDiceEnd()
	
	GameHelp.PostServerRequest("RequestFuMoTouSelect()")
	
	UIManager.FuMoTouPlayWindow:Hide()
	local total=0
	local cnt = #self.m_DiceResultPoint
	for i=1,cnt do 
		total = total + self.m_DiceResultPoint[i]
	end
	UIManager.FuMoTouResultWindow:ShowWindow(total)
	
end

function FuMoTouPlayWindow:OnDestroy()
	self.m_DiceResultPoint = {}				-- 骰子的结果点数:number
	self.m_ArrDiceGo = {}
	self.m_HadCreateDice =false
	UIWindow.OnDestroy(self)
end

return FuMoTouPlayWindow