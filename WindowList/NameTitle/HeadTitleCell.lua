local HeadTitleCell = UIControl:new
{
    windowName = "HeadTitleCell" ,
	
}

function HeadTitleCell:Attach(obj)
	
	UIControl.Attach(self,obj)
end

function HeadTitleCell:RefreshHead(headInfo)
	if self.transform == nil then 
		return
	end
	if headInfo == nil  then 
		self.transform.gameObject:SetActive(false)
	else
		local sprite  = self.Controls.headSprite
		
		if sprite ~=nil then 
			local path = GuiAssetList.GuiRootTexturePath.."HeadTitleIcon/"..headInfo.Path
			UIFunction.SetImageSprite(sprite,path)

			local LightSprite = self.Controls.lightSprite
			if LightSprite ~= nil then 
				
				local color =Color.New(0,0,0,0)
				color:FromHexadecimal( headInfo.color , 'A' )
	
				color = Color.New(color.r,color.g,color.b,0)

				LightSprite.color =color
				local doTweens =self.transform:GetComponentsInChildren(typeof(DG.Tweening.DOTweenAnimation))
				
				for i=0,doTweens.Length-1 do
					if doTweens[i].animationType == DG.Tweening.Core.DOTweenAnimationType.Fade then 
	
					doTweens[i].endValueFloat = headInfo.alphaVal
					doTweens[i]:CreateTween()
						
					end
		
					doTweens[i]:DORestart(true )
				end
				self.transform.gameObject:SetActive(true)
			end
		end

	end
	
end

function HeadTitleCell:Recycle()
	if self.transform ~= nil and self.transform.gameObject then
		rkt.GResources.RecycleGameObject( self.transform.gameObject )
	end
end

return HeadTitleCell