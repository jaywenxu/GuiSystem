--/******************************************************************
--** 文件名:    CanSetGemTypeItem.lua
--** 版  权:    (C)  深圳冰川网络技术有限公司
--** 创建人:    林春波
--** 日  期:    2017-06-19
--** 版  本:    1.0
--** 描  述:    交易窗口-摆摊部件-搜索部件-大类型图标
--** 应  用:  
--******************************************************************/

local GemInfoCellClass = require( "GuiSystem.WindowList.CommonWindow.GemInfoCell" )
-- [类型] = 信息 
local GemTypeInfo = {
    [1] = {
            ImgPath = AssetPath.TextureGUIPath .. "Icon_Baoshi/baoshi_1.png",
            TypeDes = "攻击",
        },
    [2] = {
            ImgPath = AssetPath.TextureGUIPath .. "Icon_Baoshi/baoshi_2.png",
            TypeDes = "防御",
        },
    [3] = {
            ImgPath = AssetPath.TextureGUIPath .. "Icon_Baoshi/baoshi_3.png",
            TypeDes = "生命",
        },
    [4] = {
            ImgPath = AssetPath.TextureGUIPath .. "Icon_Baoshi/baoshi_4.png",
            TypeDes = "命中",
        },
    [5] = {
            ImgPath = AssetPath.TextureGUIPath .. "Icon_Baoshi/baoshi_5.png",
            TypeDes = "躲闪",
        },
    [6] = {
            ImgPath = AssetPath.TextureGUIPath .. "Icon_Baoshi/yuanshi_1.png",
            TypeDes = "元素",
        },
    [7] = {
            ImgPath = AssetPath.TextureGUIPath .. "Icon_Baoshi/yuanshi_2.png",
            TypeDes = "忽抗",
        },
    [8] = {
            ImgPath = AssetPath.TextureGUIPath .. "Icon_Baoshi/kangshi_1.png",
            TypeDes = "金抗",
        },
    [9] = {
            ImgPath = AssetPath.TextureGUIPath .. "Icon_Baoshi/kangshi_2.png",
            TypeDes = "木抗",
        },
    [10] = {
            ImgPath = AssetPath.TextureGUIPath .. "Icon_Baoshi/kangshi_3.png",
            TypeDes = "水抗",
        },
    [11] = {
            ImgPath = AssetPath.TextureGUIPath .. "Icon_Baoshi/kangshi_4.png",
            TypeDes = "火抗",
        },
    [12] = {
            ImgPath = AssetPath.TextureGUIPath .. "Icon_Baoshi/kangshi_5.png",
            TypeDes = "土抗",
        },
}

local AddIconAssetPath = AssetPath.TextureGUIPath .. "Common_frame/Common_jiahao.png"

local GEM_CELL_WIDTH        = 516   -- GemCell宽
local GEM_CELL_HEIGHT       = 160   -- GemCell高
local EXP_BTN_HEIGHT        = 70    -- ExpandBtn高度
local INVALID_GEM_GOODID    = 0     -- 无效的宝石物品ID

local CanSetGemTypeItem = UIControl:new
{
    windowName = "CanSetGemTypeItem",
    
    m_nGemType          = nil,      -- Gem类型    
	m_IsInUnfold        = false,    -- 是否在展开状态的标识:boolean
    m_nDiffLevelGemNum  = 0,        -- 相同类型不同宝石类型的数量
    m_nShowHeight       = 0,        -- 整个控件显示高度（隐藏算0）
    m_bIsRefreshed      = false,
    
    m_fExpandBtnClicked_CalBak  = nil,          -- 父控件Class
    m_onExpandBtnClick          = nil,          -- 拓展按钮
    m_fOnCellSelected_CalBak    = nil,          -- Cell被选中回调函数
    m_fOnHeightChanged_CalBak   = nil,          -- 高度改变时回调函数
    
	m_ListGemCellItem = {},				-- 拥有该类型的所有宝石
}

function CanSetGemTypeItem:Attach(obj)
    UIControl.Attach(self,obj)
    
    self.m_onExpandBtnClick = function() self:OnExpandBtnClicked() end
    self.Controls.m_expandBtn.onClick:AddListener(self.m_onExpandBtnClick)
end

-- 设置展开按钮被点击回调函数
function CanSetGemTypeItem:SetExpandBtnClickedCalBak( CalBakFunc )
    self.m_fExpandBtnClicked_CalBak = CalBakFunc
end

-- 设置Cell被点击回调函数
function CanSetGemTypeItem:SetGemCellClickedCalBak( CalBakFunc )
    self.m_fOnCellSelected_CalBak = CalBakFunc
end

-- 设置Grid高度改变回调函数
function CanSetGemTypeItem:SetGridHeightChangedCalBak( CalBakFunc )
    self.m_fOnHeightChanged_CalBak = CalBakFunc
end

-- 展开按钮被点击
-- @bForceFold 强制折叠
function CanSetGemTypeItem:OnExpandBtnClicked( bForceFold )
    cLog("OnExpandBtnClicked", "green")
    if nil ~= self.m_fExpandBtnClicked_CalBak then
        self.m_fExpandBtnClicked_CalBak(self.m_nGemType)
    end
    
    if self.m_IsInUnfold or bForceFold then
        self:CellGridFold()
    else
        self:CellGridUnfold()
    end
    -- 更新Grid的高度
	self:UpdateGridHeight()
end

-- CellGrid收起
function CanSetGemTypeItem:CellGridFold()
    self.Controls.m_CanSetGemGrid.gameObject:SetActive(false)
    self.Controls.m_expBtnArrow.transform.localRotation = Vector3.New(0,0,0)
    self.m_IsInUnfold = false
end
-- CellGrid展开
function CanSetGemTypeItem:CellGridUnfold()
    self.Controls.m_CanSetGemGrid.gameObject:SetActive(true)
    self.Controls.m_expBtnArrow.transform.localRotation = Vector3.New(180,0,0)
    self.m_IsInUnfold = true
end

-- 宝石被点击
function CanSetGemTypeItem:GemCellClicked( GemCellClass, on )
    if nil ~= self.m_fOnCellSelected_CalBak then
        self.m_fOnCellSelected_CalBak( GemCellClass.m_CellInfo )
    end
end

function CanSetGemTypeItem:IsRefreshFinished()
    if not self.transform then
        return false
    end
    local bIsRefreshed = true
    for nKey, cItem in pairs(self.m_ListGemCellItem) do
        bIsRefreshed = bIsRefreshed and cItem:isLoaded()
        if not bIsRefreshed then
            return bIsRefreshed
        end
    end
    return bIsRefreshed
end

-- 更新Grid
-- @nGemType: 当前宝石类型
-- @tFitGemsList: 可镶嵌物品列表
-- @bIsExpand: 是否展开
function CanSetGemTypeItem:UpdateGridInfo(nGemType, tFitGemsList, bIsExpand)
    if not self.transform then
        return
    end
    if nil == nGemType or nil == GemTypeInfo[nGemType] then
        cLog("CanSetGemTypeItem:UpdateGridInfo 获取类型信息失败 nGemType = " .. tostring(nGemType), "Red")
        return
    end
    
    self.m_nGemType = nGemType
    if bIsExpand then
        self:CellGridUnfold()
    else
        self:CellGridFold()
    end
    self:HideAllGemCell()
    
    local pHero = GetHero()
	if pHero == nil then
		return
	end
    local packetPart = pHero:GetEntityPart(ENTITYPART_PERSON_PACKET)
    
    local totalNum = 0
    local childNum = 0
    local bHaveTuiJian = false
    for idx, gemInfo in pairs(tFitGemsList) do
        if gemInfo.nGemType == nGemType then
            -- 统计总数
            if nil ~= packetPart and nil ~= gemInfo.nGoodID then
                totalNum = totalNum + packetPart:GetGoodNum(gemInfo.nGoodID)
            end
            -- 该类型已经有推荐了，去掉低于它的
            if bHaveTuiJian and gemInfo.TuiJian then
                gemInfo.TuiJian = false
            end
            -- 设置Cell信息
            self:SetGemCellInfo(gemInfo, childNum)
            bHaveTuiJian = bHaveTuiJian or gemInfo.TuiJian
            childNum = childNum + 1
        end
    end
    if childNum == 0 then
        self:SetEmptyGridInfo(nGemType)
        childNum = childNum + 1
    end
    
	UIFunction.SetImageSprite(self.Controls.m_gemClassImg, GemTypeInfo[nGemType].ImgPath)
    local txtDes = GemTypeInfo[nGemType].TypeDes .. "("..totalNum..")"
    self.Controls.m_gemClassName.text = txtDes
    if bHaveTuiJian then
        self.Controls.m_expTuiJianRedDot.gameObject:SetActive(true)
    else
        self.Controls.m_expTuiJianRedDot.gameObject:SetActive(false)
    end
    
    self.m_nDiffLevelGemNum = childNum
    
    -- 更新图标的高度
	self:UpdateGridHeight()
end

-- 设置不同级别宝石信息
function CanSetGemTypeItem:SetGemCellInfo( GemInfo, nCellIndex )
    if nil == GemInfo or nil == GemInfo.nGoodID then
        cLog("设置CanSetGemCell失败 GemInfo信息不全：" .. tostringEx(GemInfo), "red")
        return
    end
        
    local objGemCell = self.m_ListGemCellItem[GemInfo.nGoodID]
    if nil == objGemCell then
        self.m_ListGemCellItem[GemInfo.nGoodID] = GemInfoCellClass:new()
        objGemCell = self.m_ListGemCellItem[GemInfo.nGoodID]
    
        if nil == objGemCell.transform then
            -- 没有则创建
            rkt.GResources.FetchGameObjectAsync( GuiAssetList.Forge.GemInfoCell,
            function ( path , obj , ud )
                
                obj.transform:SetParent(self.Controls.m_CanSetGemGrid.transform, false)
                obj.transform.sizeDelta = Vector2.New(GEM_CELL_WIDTH, GEM_CELL_HEIGHT) -- 设置cell高宽
                obj.transform:SetSiblingIndex( nCellIndex ) -- 设置Cell在Grid中的index
                
                local pToggleGroup = self.Controls.m_CanSetGemGrid.transform:GetComponent(typeof(ToggleGroup))
                objGemCell:Attach( obj )
                objGemCell:SetItemCellSelectedCallback( function( GemCellClass, on ) self:GemCellClicked( GemCellClass, on ) end )
                objGemCell:SetToggleGroup( pToggleGroup )
                
                objGemCell:SetCellInfo( GemInfo )
                
                -- 展开的时候，加载完成需要重新计算一下高度
                if self.m_IsInUnfold then
                    self:UpdateGridHeight()
                end
                
            end , GemInfo.nGoodID, AssetLoadPriority.GuiNormal )
        end
    else
        if objGemCell.transform then
            objGemCell:SetCellInfo(GemInfo)
        end
    end
end

-- 设置无该类型的宝石时的信息
function CanSetGemTypeItem:SetEmptyGridInfo(nGemType)
    if nil == nGemType then
        return
    end
    
    local objGemCell = self.m_ListGemCellItem[ INVALID_GEM_GOODID ]
    if nil == objGemCell then
        self.m_ListGemCellItem[ INVALID_GEM_GOODID ] = GemInfoCellClass:new()
        objGemCell = self.m_ListGemCellItem[ INVALID_GEM_GOODID ]
        if nil == objGemCell.transform then
            -- 没有则创建
            rkt.GResources.FetchGameObjectAsync( GuiAssetList.Forge.GemInfoCell,
            function ( path , obj , ud )
                
                obj.transform:SetParent(self.Controls.m_CanSetGemGrid.transform, false)
                obj.transform.sizeDelta = Vector2.New(GEM_CELL_WIDTH, GEM_CELL_HEIGHT) -- 设置cell高宽
                
                local pToggleGroup = self.Controls.m_CanSetGemGrid.transform:GetComponent(typeof(ToggleGroup))
                objGemCell:Attach( obj )
                objGemCell:SetToggleGroup( pToggleGroup )
                self:SetEmptyGrid_ItemCellInfo(nGemType)
                
                -- 展开的时候，加载完成需要重新计算一下高度
                if self.m_IsInUnfold then
                    self:UpdateGridHeight()
                end
                
            end, nil, AssetLoadPriority.GuiNormal )
        end
    else
        self:SetEmptyGrid_ItemCellInfo(nGemType)
    end
end

function CanSetGemTypeItem:SetEmptyGrid_ItemCellInfo(nGemType)
    local EmptyCellClass = self.m_ListGemCellItem[ INVALID_GEM_GOODID ]
    if nil == EmptyCellClass or nil == EmptyCellClass.transform then
        return
    end
    
    local tmpGoodCell = EmptyCellClass.Controls.GoodCell
    if nil == tmpGoodCell or tmpGoodCell.windowName ~= "CommonGoodCell" then
        return
    end
	tmpGoodCell:ChildSetActive("QualityBg",false)
	tmpGoodCell:ChildSetActive("BindIcon",false)
	tmpGoodCell:ChildSetActive("Count",false)
	tmpGoodCell:ChildSetActive("Select",false)
	tmpGoodCell:ChildSetActive("PuttedOn",false)
	tmpGoodCell:ChildSetActive("UpGrade",false)
	tmpGoodCell:ChildSetActive("ForgeFull",false)
    
    tmpGoodCell:ChildSetActive("MainBg",true)
    tmpGoodCell:SetNullEquipIconImg( AddIconAssetPath )
    tmpGoodCell:SetItemGoodIcon( GemTypeInfo[nGemType].ImgPath )
    
    tmpGoodCell:SetItemCellPointerClickCallback( function() self:OnAddCellClicked() end )
    
    local txtDes = "<color=#2D2D2DFF>"..GemTypeInfo[nGemType].TypeDes .. "宝石</color>"
    EmptyCellClass.Controls.m_GemName.text = txtDes
    

    local tmpGemPropID = ""
    local pHero = GetHero()
	if nil ~= pHero then
        local forgePart = pHero:GetEntityPart(ENTITYPART_PERSON_FORGE)
        if nil ~= forgePart then
            local nVocation = pHero:GetNumProp(CREATURE_PROP_VOCATION)	-- 获取职业
            tmpGemPropID = forgePart.m_SettingCfgCenter:GetGemPropID_KeyGemType_KeyVocation(nGemType, nVocation)
        end
    end
    
    local propDes = ""
    if nil == tmpGemPropID or "" == tmpGemPropID then
        propDes = "<color=#FF7800FF>？？？</color>"
    else
        propDes = "<color=#2D2D2DFF>"..GameHelp.PropertyName[tmpGemPropID].."</color><color=#FF7800FF> +？？？</color>"
    end
    EmptyCellClass.Controls.m_GemProp.text = propDes
    
    EmptyCellClass:Show()
end

-- 隐藏Grid下所有Cell
function CanSetGemTypeItem:HideAllGemCell()
    for ikey, cItem in pairs(self.m_ListGemCellItem) do
        if cItem.transform then
            cItem:Hide()
        end
    end
end

-- 更新图标的高度
function CanSetGemTypeItem:UpdateGridHeight()
	local oriSize = self.transform.sizeDelta
	oriSize.y = EXP_BTN_HEIGHT
    if self.m_IsInUnfold then
        oriSize.y = oriSize.y + self.m_nDiffLevelGemNum * GEM_CELL_HEIGHT
    end
    
	self.transform.sizeDelta = oriSize
    
    -- 父控件高度控制
    if self.m_fOnHeightChanged_CalBak then
        self.m_fOnHeightChanged_CalBak()
    end
end

-- 前往宝石合成
function CanSetGemTypeItem:OnAddCellClicked()
	UIManager.ForgeWindow:ChangeForgePage(true, 4)
    
    self:RefreshForgeConpound()
end

-- 刷新宝石合成界面数据
function CanSetGemTypeItem:RefreshForgeConpound()
    local tmpConWidget = UIManager.ForgeWindow.ForgeConpoundWidget
    if not tmpConWidget then
        return
    end
    
    if not tmpConWidget:isLoaded() then
		DelayExecuteEx(10,function ()
			self:RefreshForgeConpound()
		end)
		return
	end
    -- 定位到当前类型
    if tmpConWidget then
        tmpConWidget:SetGemTypeDropValue( self.m_nGemType - 1 )
    end
end

function CanSetGemTypeItem:OnRecycle()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnRecycle(self)
	
end

function CanSetGemTypeItem:OnDestroy()
	
	-- 清除数据
	self:CleanData()
	
	UIControl.OnDestroy(self)
	
end

-- 清除数据
function CanSetGemTypeItem:CleanData()
	
	self.Controls.m_expandBtn.onClick:RemoveListener(self.m_onExpandBtnClick)
	self.m_onExpandBtnClick = nil
    
    for ikey, cItem in pairs(self.m_ListGemCellItem) do
        if cItem.transform then
            cItem:Destroy()
        end
    end
    self.m_ListGemCellItem = {}
end

return CanSetGemTypeItem