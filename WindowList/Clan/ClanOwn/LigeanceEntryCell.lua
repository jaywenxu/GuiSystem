-- 领地战斗入口Cell
-- @Author: XieXiaoMei
-- @Date:   2017-04-12 16:43:41
-- @Last Modified by:   Administrator
-- @Last Modified time: 2017-08-18 19:14:30

------------------------------------------------------------
local LigeanceEntryCell =  UIControl:new
{
	windowName = "LigeanceEntryCell",
	
	m_ID       = nil, --领地ID

	m_EnterBtnClickCallBack = nil,

	m_IsConvoke = false, --召集操作

	m_LastConvokeTimestamp = 0, --最后一次召集操作的时间搓
}

local this = LigeanceEntryCell

------------------------------------------------------------
-- 初始化
function LigeanceEntryCell:Attach(obj)
	UIControl.Attach(self,obj)

	self.m_EnterBtnClickCallBack = handler(self, self.OnBtnEnterClicked)
	self.Controls.m_EnterBtn.onClick:AddListener(self.m_EnterBtnClickCallBack)
end

------------------------------------------------------------
-- 设置数据
function LigeanceEntryCell:SetData(data)
	local controls = self.Controls

	local ligeCfg = IGame.rktScheme:GetSchemeInfo(LIGEANCE_CSV, data.nID)
	if not ligeCfg then
		cLog("本地配置不能为空 id:".. data.nID, "red")
		return
	end

	controls.m_NameTxt.text = ligeCfg.szName

	local bAttack = data.byAttack == 1 -- 0:守  1：攻
	controls.m_AttatckFlag.gameObject:SetActive(bAttack)
	controls.m_DefenceFlag.gameObject:SetActive(not bAttack)
	
	local iconImg = controls.m_IconImg
	UIFunction.SetImageSprite(iconImg  , GuiAssetList.GuiRootTexturePath ..ligeCfg.icon, function ()
		-- 根据领地等级动态调整ICON的大小，等级越大图标越大
		local lv = ligeCfg.nLevel + 1  
		local scale = 0.6 + lv / 10 + 0.05
		iconImg.transform.localScale = Vector3.New(scale, scale, 1)
	end)

	local bShowBtn = true
	local str = "进入"
	local imgFile = "Common_frame/Common_button_er_huang.png"
	local fightLigeID = IGame.LigeanceEctype:GetLigeanceID() 
	if fightLigeID == data.nID then
		bShowBtn = false

		if IGame.ClanClient:IsClanShaikhID() then 
			str = "召集"
			imgFile = "Common_frame/Common_button_er_lv.png"
			self.m_IsConvoke = true

			bShowBtn = true
		end
	end
	controls.m_BtnTxt.text = str
	UIFunction.SetImageSprite(controls.m_BtnImg, GuiAssetList.GuiRootTexturePath .. imgFile)
	controls.m_EnterBtn.gameObject:SetActive(bShowBtn)

	self.m_ID = data.nID
end

------------------------------------------------------------
-- 自身销毁
function LigeanceEntryCell:OnDestroy()
	UIControl.OnDestroy(self)

	table_release(self) 
end

------------------------------------------------------------
-- 回收自身
function LigeanceEntryCell:Recycle()
	self.Controls.m_EnterBtn.onClick:RemoveListener(self.m_EnterBtnClickCallBack)

	rkt.GResources.RecycleGameObject(self.transform.gameObject)

	self.m_LastConvokeTimestamp = 0
end

------------------------------------------------------------
-- 进入战场按钮回调
function LigeanceEntryCell:OnBtnEnterClicked()

	if self.m_IsConvoke then -- 召集
		if os.time() - self.m_LastConvokeTimestamp < 60 then
			local str = "请不要频繁召集！"
			IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, str)
			return 
		end
		IGame.Ligeance:RequestClanCall(self.m_ID)
		self.m_LastConvokeTimestamp = os.time()
	else
		IGame.Ligeance:RequestWarEnter(self.m_ID)
	end

	UIManager.LigeanceEntryWindow:Hide()
end

return this

