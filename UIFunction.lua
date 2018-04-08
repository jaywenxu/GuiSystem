-- 界面操作相关的工具函数，简化界面操作代码
-- 不要在这里写逻辑
------------------------------------------------------------------------------
UIFunction = {
	m_Tweener = nil
}

local UI_ETC1_GRAY_MAT = GuiAssetList.GuiRootMaterialPath .. "UI_DefaultETC1_Gray.mat"
local RED_DOT_IMG_PATH = AssetPath.TextureGUIPath .."Common_frame/Common_hondian.png"

rkt.GResources.SetReleaseWaitTime( { UI_ETC1_GRAY_MAT , RED_DOT_IMG_PATH } , ReleaseWaitTime.RELEASE_WAIT_PERSISTENT )

------------------------------------------------------------------------------
-- 通过UIControl.windowName从GameObject上获取响应的lua绑定对象
-- obj 可以是 GameObject 或 Component
-- winName 必须是 继承UIControl对象设定的 windowName
------------------------------------------------------------------------------
function UIFunction.GetLuaControl( obj , winName )
    local behav = obj:GetComponent(typeof(UIWindowBehaviour))
    if nil == behav then
        return nil
    end
    local lua_obj = behav.LuaObject
    if nil == lua_obj then
        return nil
    end
    if lua_obj.windowName ~= winName then
        return nil
    end
    return lua_obj
end
------------------------------------------------------------------------------
-- 给一个图片设置图标(异步加载)
-- @param : image(UnityEngine.UI.Image)  图片控件
-- @param : spritePath(string)  图标的路径
------------------------------------------------------------------------------
function UIFunction.SetImageSprite( image , spritePath,callBack )
	if tolua.isnull( image ) or IsNilOrEmpty(spritePath) then
		uerror("UIFunction.SetImageSprite image is nil or spritePath is nil \n" .. debug.traceback())
		return
	end
	rkt.GResources.LoadAsync( spritePath , typeof(Sprite) ,
		function( path , asset , userData )
			if nil ~= asset and not tolua.isnull( image ) then
				image.sprite = asset
                rkt.AssetRefComponent.Assign(image.gameObject, typeof(Sprite), path)
				if callBack ~=nil then
					callBack()
				end
            else
                uerror( "load sprite error , path := " .. path )
			end
		end,"",AssetLoadPriority.GuiNormal)
end




------------------------------------------------------------------------------
-- 给一个图片设置Override材质(异步加载)
-- @param : image(UnityEngine.UI.Image|UnityEngine.UI.RawImage) 图片控件
-- @param : materialPath(string) 材质路径
function UIFunction.SetImageMaterial( image , materialPath,callBack )
	if tolua.isnull( image ) or IsNilOrEmpty(materialPath) then
		uerror("UIFunction.SetImageMaterial image or materialPath is nil\n" .. debug.traceback())
		return
	end
	rkt.GResources.LoadAsync( materialPath , typeof(Material) ,
		function( path , asset , userData )
			if nil ~= asset and not tolua.isnull( image ) then
				image.material = asset
                rkt.AssetRefComponent.Assign(image.gameObject, typeof(Material), path)
				if callBack ~=nil then
					callBack()
				end
            else
                uerror( "load material error , path := " .. path )
			end
		end,"",AssetLoadPriority.GuiNormal)	
end

--ADD XWJ此方法容易造成一个BUG，如果你在两个状态之间快速切换，因为异步加载的问题，可能最后是什么状态无法保证所以加个回调
------------------------------------------------------------------------------
-- 将一个图片置灰
-- @param : image(UnityEngine.UI.Image|UnityEngine.UI.RawImage) 图片控件
-- @param : gray(bool) 是否置灰
-- @param : clickable(bool) 是否可以点击
function UIFunction.SetImageGray( image , gray, callBack, clickable )
	if tolua.isnull( image ) then
		uerror("UIFunction.SetImageGray image image is nil \n" .. debug.traceback() )
		return
	end
    if gray then
        UIFunction.SetImageMaterial( image , UI_ETC1_GRAY_MAT,callBack )
    else
        image.material = nil
    end
	if clickable == nil then 
		UIFunction.SetButtonClickState(image,true)
	else
		UIFunction.SetButtonClickState(image,clickable)
	end
	
end

-- 将gameObject所有的Image,rawImage组件置灰
function UIFunction.SetImgComsGray( gameObject , gray)
	local types = {typeof(Image), typeof(RawImage)}
	UIFunction.SetComsGray(gameObject, gray, types)
end

-- 将gameObject所有的子节点（图片、字体）组件置灰
function UIFunction.SetAllComsGray( gameObject , gray )
	local types = {typeof(Image), typeof(RawImage), typeof(Text)}
	UIFunction.SetComsGray(gameObject, gray, types)
end


-- 置灰gameObject下的子组件
-- @ param:
--		gameObject 	: 根节点
--		gray 		: 是否置灰
--		cTypes		：类型,如{ typeof(Image), typeof(Text)}
-- 		clickable	: clickable(bool) 是否总是可以点击
function UIFunction.SetComsGray( gameObject , gray , cTypes)
	local setComsMat = function (material)
		if tolua.isnull( gameObject ) then
			return
		end

		for k, ctype in pairs(cTypes)do
			local coms = gameObject:GetComponentsInChildren(ctype, true)
			for i = 0 , coms.Length - 1 do 
				coms[i].material = material
                rkt.AssetRefComponent.Assign(coms[i].gameObject, typeof(Material), path)
			end
		end
	end

	if gray then		
		rkt.GResources.LoadAsync( UI_ETC1_GRAY_MAT , typeof(Material) ,
			function( path , asset , userData )
				if nil ~= asset then
					setComsMat(asset)
		        else
		            uerror( "load material error , path := " .. path )
				end
		end,"",AssetLoadPriority.GuiNormal)	
	else
		setComsMat(nil)
	end
	
end


-- 置灰gameObject和其下的子组件
-- @ param:
--		gameObject 	: 根节点
--		gray 		: 是否置灰

function UIFunction.SetComsAndChildrenGray(obj , gray, callBack)
	local setComsMat = function (material)
		if tolua.isnull( obj ) then
			return
		end
		local coms = obj:GetComponentsInChildren(typeof(UnityEngine.UI.Graphic), true)
		for i = 0 , coms.Length - 1 do 
			coms[i].material = material
			rkt.AssetRefComponent.Assign(coms[i].gameObject, typeof(Material), path)
		end
		
	end
	local graphic = obj:GetComponent(typeof(UnityEngine.UI.Graphic))
	if graphic ~=nil then 
		if gray then 
			UIFunction.SetImageMaterial( graphic , UI_ETC1_GRAY_MAT)
			
		else
			graphic.material = nil
		end
	end
	if gray then		
		rkt.GResources.LoadAsync( UI_ETC1_GRAY_MAT , typeof(Material) ,
			function( path , asset , userData )
				if nil ~= asset then
					setComsMat(asset)
					if callBack ~= nil then 
						callBack()
					end
		        else
		            uerror( "load material error , path := " .. path )
				end
		end,"",AssetLoadPriority.GuiNormal)	
	else
		setComsMat(nil)
	end
	
end


--检测频繁点击
function UIFunction.CheckOftenClick(lastClickTime,indexTime,desc)
	local allowTime = lastClickTime + indexTime
	local currentTime = Time.realtimeSinceStartup
	if allowTime < currentTime then
		return true 
	else
		local tips = desc or "请不要频繁点击"
		IGame.ChatClient:addSystemTips(TipType_Operate, InfoPos_ActorUnder, tips)
		return false
		
	end
end

---
---
------------------------------------------------------------------------------
--给一个RawImage设置图标
function UIFunction.SetRawImageSprite(rawImage , spritePath, callBack)
	if tolua.isnull( rawImage ) or IsNilOrEmpty(spritePath) then
		uerror("UIFunction.SetRawImageSprite rawImage or spritePath is nil\n" .. debug.traceback())
		return
	end
	rkt.GResources.LoadAsync( spritePath , typeof(UnityEngine.Texture) ,
		function( path , asset , userData )
			if nil ~= asset and not tolua.isnull( rawImage ) then
				rawImage.texture = asset
                rkt.AssetRefComponent.Assign(rawImage.gameObject, typeof(UnityEngine.Texture), path)
				if callBack ~=nil then
					callBack()
				end
            else
                uerror( "load Texture error , path := " .. path )
			end
		end,"",AssetLoadPriority.GuiNormal)	
end
------------------------------------------------------------------------------

--设置头衔
--[[local headInfo ={
		Path = "city_title_jinglei.png",
		color = "ffffffff",
		alphaVal = 0.8
	}--]]
function UIFunction.SetHeadTitle(parent,headInfo,callBack)
	local cellClass = require("GuiSystem.WindowList.NameTitle.HeadTitleCell")
	local cell = cellClass:new({})
	rkt.GResources.FetchGameObjectAsync(GuiAssetList.HeadTitleCell.UguiHeadTitleCell,function(path , obj , ud )
		if nil == obj then 
			uerror("prefab is nil : " .. path )
			return
		end
        if tolua.isnull( parent ) then
            rkt.GResources.RecycleGameObject( obj )
            return
        end
		obj.transform:SetParent(parent,false) 
		cell:Attach(obj)
		cell:RefreshHead(headInfo)
		
		if callBack then
			callBack()
		end
	end,nil,AssetLoadPriority.GuiNormal )
	return cell
		
end

------------------------------------------------------------------------------
--给一个RawImage设置图标
function UIFunction.SetNGUISprite(Sprite2D , spritePath,callBackFun)
	if tolua.isnull( Sprite2D ) or IsNilOrEmpty(spritePath) then
		uerror("UIFunction.SetNGUISprite  or spritePath is nil\n" .. debug.traceback())
		return
	end
	rkt.GResources.LoadAsync( spritePath , typeof(Sprite) ,
		function( path , asset , userData )
			if nil ~= asset and not tolua.isnull( Sprite2D ) then
				Sprite2D.sprite2D = asset
                rkt.AssetRefComponent.Assign(Sprite2D.gameObject, typeof(Sprite), path)
                if callBackFun ~= nil then 
                    callBackFun()
                end
            else
                uerror( "load NGUISprite   error , path := " .. path )
			end
		end,"",AssetLoadPriority.GuiNormal)	
end
------------------------------------------------------------------------------
--设置指定物体（gameobject）Transform组件DOLocalMoveX动画的时间（Duration）
--以及移动增量X（TO X）并且触发动画在指定时间（Duration）内移动指定的增量（X）
-- @param : gameObj (GameObject) 需要动画的游戏物体
-- @param : duration(float) 持续时间
-- @param : xIncrement(float) X轴移动增量
-- @param : completeCallback(callback) complete事件回调
-- @return: tweener 返回管理当前动画的Tweener对象
function UIFunction.DOTweenLocalMOVEX(gameObj , duration , xIncrement , completeCallback)
	local beginPosition = gameObj.transform.localPosition
	local tweener = gameObj.transform:DOLocalMoveX(beginPosition.x + xIncrement,duration,false)
	tweener:SetEase(DG.Tweening.Ease.Linear)
	if completeCallback ~= nil then
		tweener:OnComplete(completeCallback)
	end
	return tweener
end
------------------------------------------------------------------------------
--设置指定物体（gameobject）Transform组件DOLocalMoveY动画的时间（Duration）
--以及移动增量Y（TO Y）并且触发动画在指定时间（Duration）内移动指定的增量（Y）
-- @param : gameObj (GameObject) 需要动画的游戏物体
-- @param : duration(float) 持续时间
-- @param : yIncrement(float) Y轴移动增量
-- @param : completeCallback(callback) complete事件回调
-- @return: tweener 返回管理当前动画的Tweener对象
function UIFunction.DOTweenLocalMOVEY(gameObj , duration , yIncrement , completeCallback)
	local beginPosition = gameObj.transform.localPosition
	local tweener = gameObj.transform:DOLocalMoveY(beginPosition.y + yIncrement,duration,false)
	tweener:SetEase(DG.Tweening.Ease.Linear)
	if completeCallback ~= nil then
		tweener:OnComplete(completeCallback)
	end
	return tweener
end
------------------------------------------------------------------------------
--设置指定物体（gameobject）Transform组件DOLocalMoveZ动画的时间（Duration）
--以及移动增量Z（TO Z）并且触发动画在指定时间（Duration）内移动指定的增量（Z）
-- @param : gameObj (GameObject) 需要动画的游戏物体
-- @param : duration(float) 持续时间
-- @param : zIncrement(float) Z轴移动增量
-- @param : completeCallback(callback) complete事件回调
-- @return: tweener 返回管理当前动画的Tweener对象
function UIFunction.DOTweenLocalMOVEZ(gameObj , duration , zIncrement , completeCallback)
	local beginPosition = gameObj.transform.localPosition
	local tweener = gameObj.transform:DOLocalMoveZ(beginPosition.z + zIncrement,duration,false)
	tweener:SetEase(DG.Tweening.Ease.Linear)
	if completeCallback ~= nil then
		tweener:OnComplete(completeCallback)
	end
	return tweener
end
------------------------------------------------------------------------------
--设置指定物体（gameobject）Transform组件DOLocalMove动画的时间（Duration）
--以及移动增量Vec3（TO）并且触发动画在指定时间（Duration）内移动指定的增量（Vec3）
-- @param : gameObj (GameObject) 需要动画的游戏物体
-- @param : duration(float) 持续时间
-- @param : vIncrement(Vector3) 移动增量
-- @param : completeCallback(callback) complete事件回调
-- @return: tweener 返回管理当前动画的Tweener对象
function UIFunction.DOTweenLocalMOVE(gameObj , duration , vIncrement , completeCallback)
	local beginPosition = gameObj.transform.localPosition
	local tweener = gameObj.transform:DOLocalMove(beginPosition + vIncrement,duration,false)
	tweener:SetEase(DG.Tweening.Ease.Linear)
	if completeCallback ~= nil then
		tweener:OnComplete(completeCallback)
	end
	return tweener
end
------------------------------------------------------------------------------
--设置指定物体

------------------------------------------------------------------------------
--设置物体的Transform组件旋转到指定的位置
--@param gameObj: 需要旋转的物体
--@param to     : 旋转到的角度
--@param duration: 持续时间
function UIFunction.DOTweenLocalRotate(gameObj, to, duration)
	if gameObj == nil or to == nil or duration == nil then
		return
	end
	local tweener = gameObj.transform:DOLocalRotate(to, duration,DG.Tweening.RotateMode.Fast)
	tweener:SetEase(DG.Tweening.Ease.Linear)
	
end
------------------------------------------------------------------------------
--将场景中的坐标映射到地图Image坐标
--@param : args 需要传进的参数：一个table，包括：场景坐标（Vector2），地图宽高，Image宽高
--@return：返回一个Vector3 表示UI Image相对坐标
function UIFunction:WorldCoordinateToMapImage(args)
	if args == nil then
		return nil
	end
	local posX = args.posX
	local posZ = args.posY
	local mapWidth = args.mapWidth
	local mapHeight = args.mapHeight
	local imageWidth = args.imageWidth
	local imageHeight = args.imageHeight
	
	if mapWidth == 0 or mapHeight == 0 then
		return;
	end
	local oneDivideMapWidth = 1 / mapWidth;
    local oneDivideMapHeight = 1 / mapHeight;
	
	local xProportion = posX * oneDivideMapWidth
    local yProportion = posZ * oneDivideMapHeight
	local xOffset = xProportion * imageWidth
    local yOffset = yProportion * imageHeight
	
	return Vector3.New(xOffset,yOffset,0)
	
end
------------------------------------------------------------------------------
-- 给EventTrigger添加一个事件回调
function UIFunction.AddEventTriggerListener( target , triggerType , handler )
    local trigger = target:GetComponent(typeof(EventTrigger))
    if nil == trigger then
        return
    end
    local entry = ToLuaX.List_Find( trigger.triggers , function(item) return item.eventID == triggerType end)
    if nil == entry then
        entry = EventTrigger.Entry.New()
        entry.eventID = triggerType
        trigger.triggers:Add(entry)
    end
    entry.callback:AddListener(handler)
end
------------------------------------------------------------------------------
-- 给EventTrigger删除一个事件回调
function UIFunction.RemoveEventTriggerListener( target , triggerType , handler )
    local trigger = target:GetComponent(typeof(EventTrigger))
    if nil == trigger then
        return
    end
    local entry = ToLuaX.List_Find( trigger.triggers , function(item) return item.eventID == triggerType end)
    if nil == entry then
        return
    end
    entry.callback:RemoveListener(handler)
end
------------------------------------------------------------------------------

--展示tips保证TIPS在Screen中并且在你点击的物体附近
--showState 显示还是隐藏
--TipsTrs Tips的recttransform
--OnClickTrs 点击的物体的transform
--offset 上下左右偏移
function UIFunction.ToolTipsShow(showState,tipsTrs,onClickTrs,offset)
	if false == showState then 
		tipsTrs.gameObject:SetActive(false)
	else
		if nil ~= tipsTrs and nil ~= onClickTrs then 
			tipsOffsetX = tipsTrs.sizeDelta.x*0.5
			tipsOffsetY = tipsTrs.sizeDelta.y*0.5
			local uiCamera = UIManager.FindUICamera()
			vec3 = uiCamera:WorldToScreenPoint(onClickTrs.position)
			if (vec3.x + (tipsOffsetX) + offset.x) <= UnityEngine.Screen.width then
                vec3.x = vec3.x + offset.x + tipsOffsetX
            else
                vec3.x = vec3.x - (offset.x + tipsOffsetX)
			end
            if (vec3.y + (tipsOffsetY ) + offset.y) <= UnityEngine.Screen.height then
                vec3.y = vec3.y + offset.y + tipsOffsetY 
            else
                vec3.y = vec3.y -(offset.y + tipsOffsetY )
			end
            v =  Vector3.New(((UnityEngine.Screen.width * 0.5) - (-vec3.x)) - UnityEngine.Screen.width, vec3.y - (UnityEngine.Screen.height * 0.5), 0);
			tipsTrs.anchoredPosition = v 
			tipsTrs.gameObject:SetActive(true)
		end
	end
	
end


--展示tips保证TIPS在Screen中并且在你点击的物体附近
--showState 显示还是隐藏
--TipsTrs Tips的recttransform
--OnClickTrs 点击的物体的transform
--offset 上下左右偏移
function UIFunction.ToolTipsShowPivotCent(showState,tipsTrs,onClickTrs,offset)
	if false == showState then 
		tipsTrs.gameObject:SetActive(false)
	else
		if nil ~= tipsTrs and nil ~= onClickTrs then 
			tipsOffsetX = tipsTrs.sizeDelta.x
			tipsOffsetY = tipsTrs.sizeDelta.y
			local uiCamera = UIManager.FindUICamera()
			vec3 = uiCamera:WorldToScreenPoint(onClickTrs.position)
			if (vec3.x + (tipsOffsetX) + offset.x) <= UnityEngine.Screen.width then
                vec3.x = vec3.x + offset.x + tipsOffsetX/2
            else
                vec3.x = vec3.x - (offset.x + tipsOffsetX/2)
			end
            if (vec3.y + (tipsOffsetY ) + offset.y) <= UnityEngine.Screen.height then
                vec3.y = vec3.y + offset.y + tipsOffsetY/2 
            else
                vec3.y = vec3.y -(offset.y + tipsOffsetY /2)
			end
            v =  Vector3.New(((UnityEngine.Screen.width * 0.5) - (-vec3.x)) - UnityEngine.Screen.width, vec3.y - (UnityEngine.Screen.height * 0.5), 0);
			tipsTrs.anchoredPosition = v 
			tipsTrs.gameObject:SetActive(true)
		end
	end
	
end

--设置头像Icon
function UIFunction.SetHeadImage(Image, HeadID, callBack)
	UIFunction.SetImageSprite(Image, gPersonHeadIconCfg[HeadID], callBack)
end

--此处的rgba为0-255
function UIFunction.GetColor(r,g,b,a)
	local color = Color.New(r,g,b,a)
	return color/255
end


------------------------------------------------------------------------------
-- 显示或隐藏红点图片，默认位置为右上角
--@ param : 
--		parentTf 	: 	父节点transform
--		isShow 		: 	是否显示
--		scaleTrans	:	闪烁动画(放大缩小反复)
function UIFunction.ShowRedDotImg(parentTf, isShow, scaleTrans)
	if not parentTf then
		return
	end

	local imgGo = parentTf:Find("RedDotImg")
	if not imgGo then
		if isShow then
			imgGo = GameObject.New("RedDotImg")
			local img = imgGo:AddComponent(typeof(Image))
			UIFunction.SetImageSprite( img , RED_DOT_IMG_PATH, function ()
				imgGo:SetActive(true)
				img:SetNativeSize()
			end)

			local transform = imgGo.transform
			transform.pivot = Vector2.New(0.75, 0.75)
			transform.anchorMax = Vector2.New(1, 1)
			transform.anchorMin = Vector2.New(1, 1)
			transform.localPosition = Vector3.New(0, 0, 0)
			transform:SetParent(parentTf, false)

			imgGo:SetActive(false)
		end
	else
		imgGo.gameObject:SetActive(isShow ~= nil and isShow == true)
	end
		
	if scaleTrans then
		local to = Vector3.New(0.8, 0.8, 1)
		if isShow then
			local tweener = parentTf:DOScale(to, 0.5)
			tweener:SetEase(DG.Tweening.Ease.InOutQuad)
			tweener:SetLoops(-1, DG.Tweening.LoopType.Yoyo)
			UIFunction.m_Tweener = tweener
		else
			local tweener = UIFunction.m_Tweener
			if tweener then tweener:Kill() end
			parentTf.localScale = Vector3.New (1,1,1);  
		end
	end
end

-- 获取品质对应的16进制颜色
-- @qualityType:品质类型:number
-- return 16进制的颜色字符串:string
function UIFunction.GetQualityHexadecimalColor(qualityType)
	
	if qualityType == 1 then 
		return "f6e5c7"
	elseif qualityType == 2 then 
		return "078301"
	elseif qualityType == 3 then
		return "0052c5"
	elseif qualityType == 4 then
		return "b708bd"
	else
		return "e80505"
	end
	
end


-- 获取带品质的名字
-- @oriName:没带颜色格式的名字
-- @qualityType:品质类型:number
-- return 带颜色格式的名字:string
function UIFunction.GetQualityName(oriName, qualityType)
	
	return string.format("<color=#%s>%s</color>", UIFunction.GetQualityHexadecimalColor(qualityType), oriName)
	
end

-- 将字符串颜色转换为真实颜色
-- @colorStr:颜色字符串:string
-- return 颜色:Color
function UIFunction.ConverRichColorToColor(colorStr)
	local clr = Color:New(1, 1, 1, 1)
    clr:FromHexadecimal(colorStr)
    return clr
end

-- 获取品质对应的颜色
-- @qualityType:品质类型:number
-- return 颜色:Color
function UIFunction.GetQualityColor(qualityType)
	
	local colorStr = GoodsNameColor[qualityType]
	colorStr = string.sub(colorStr, 1, #colorStr-2)
	return UIFunction.ConverRichColorToColor(colorStr)
	
end

------------------------------------------------------------------------------
-- 设置text组件颜色
-- @param:
--		gameObject 	: 对象
-- 		color 		: 颜色
function UIFunction.SetTxtComsColor(gameObject, color)
	local textComs = gameObject:GetComponentsInChildren(typeof(Text))
	for i = 0 , textComs.Length - 1 do 
		textComs[i].color = color
	end
end

------------------------------------------------------------------------------
-- 设置cell上的头衔
-- @param:
--		titleID 	: 头衔ID
-- 		parentTf 		: 头衔预设的父节点
function UIFunction.SetCellHeadTitle(titleID, parentTf, controls, callBack)

	local titleInfo = IGame.rktScheme:GetSchemeInfo(HEADTITLE_CSV,titleID)
	if not titleInfo then
		return false
	end

	local info =
	{
		Path= titleInfo.szIconPath,
		color = titleInfo.szColor,
		alphaVal = titleInfo.nLight
	}

	if not controls["headTitleCell"] then
		controls["headTitleCell"] = UIFunction.SetHeadTitle(parentTf, info, callBack)
	else
		controls["headTitleCell"]:RefreshHead(info)
	end	

	return true
end

--设置按钮的可点击 raycasttarget
function UIFunction.SetButtonClickState(obj,state)
	local Graphic = obj:GetComponent(typeof(UnityEngine.UI.Graphic))
	if Graphic ~= nil  then 
		Graphic.raycastTarget = state
	end
end

--还原图片原始尺寸
function UIFunction.SetImageNative(image)
	if tolua.isnull( image ) then
		uerror("UIFunction.SetImageNative image is nil  \n" .. debug.traceback())
		return
	end
	
	image:SetNativeSize()
end


