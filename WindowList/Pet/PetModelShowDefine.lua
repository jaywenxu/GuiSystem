--------------灵兽展示模型背景参数------------------------------
--add 许文杰 
--日期 ：2017-07-24
local PetModelShowDefine =
{
	BgParamArr = 
	{




		[0] = 
		{
			layer = "EntityGUI", -- 所在层
			Name = "ObjectDisplayPet" ,
			Position = Vector3.New( 1000 , 1000 , 0 ) ,
			RTWidth = 1120 , -- RenderTexture 宽
			RTHeight = 968, -- RenderTexture 高
			CullingMask = {"EntityGUI"},  -- 裁减列表，填 layer 的名称即可
			CamPosition = Vector3.New( 0 , 0 , 0 ) ,   -- 相机位置
			FieldOfView = 0 ,  -- 视野角度
			BackgroundColor = Color.black ,
			CameraRotate = Vector3.New(6.84,-180,0) ,
			CameraLight = true ,
			BackgroundImageInfo =
			{	
				[0] = 
				{
					BackgroundImage = AssetPath.TextureGUIPath.."RawImage/Common_zd_beijing.png", --背景图片（texture）
					UVs = 
					{   
						Vector4.New( 0 ,0.13888 , 0.583333, 0.902777),
					} ,
					name = "GameObject"	,
			
				},
				[1] = 
				{
					BackgroundImage = AssetPath.TextureGUIPath.."Pet_1/Pet_baobaotaizi.png", --背景图片（texture）
					zValue = 1,
					isSliced = true,
					isSprite =true,
					name = "GameObject1"	,
		
				},
				[2] = 
				{
					BackgroundImage = AssetPath.TextureGUIPath.."CommonBigFrame/Common__tuopan_di.png", --背景图片（texture）
					zValue =3,
					Vertices =
					{
						
						Vector4.New( -0.75535, -0.59583, 1 ,0.1625)
						
					},
					isSliced = false,
					isSprite =true,
					name = "GameObject2"	,
		
				},
				[3]=
				{
					BackgroundImage = AssetPath.TextureGUIPath.."Pet_1/pet_chonwu_tupan.png", --背景图片（texture）
					zValue = 9,
					Vertices =
					{
						
						Vector4.New( -0.30892, -0.214583, 0.5607 ,0.1625)
						
					},
					isSliced = false,
					isSprite =true,
					name = "GameObject3"	,

				},
				
			}
		},
		
		[1] = 
		{
			layer = "EntityGUI", -- 所在层
			Name = "ObjectDisplayPet" ,
			Position = Vector3.New( 1000 , 1000 , 0 ) ,
			RTWidth = 1120 , -- RenderTexture 宽
			RTHeight = 968, -- RenderTexture 高
			CullingMask = {"EntityGUI"},  -- 裁减列表，填 layer 的名称即可
			CamPosition = Vector3.New( 0 , 0 , 0 ) ,   -- 相机位置
			FieldOfView = 0 ,  -- 视野角度
			BackgroundColor = Color.black ,
			CameraRotate = Vector3.New(6.84,-180,0) ,
			CameraLight = true ,
			BackgroundImageInfo =
			{	
				[0] = 
				{
					BackgroundImage = AssetPath.TextureGUIPath.."RawImage/Common_zd_beijing.png", --背景图片（texture）
					UVs = 
					{   
						Vector4.New( 0 ,0.13888 , 0.583333, 0.902777),
					} ,
					name = "GameObject"	,
			
				},
				[1] = 
				{
					BackgroundImage = AssetPath.TextureGUIPath.."CommonBigFrame/Common_di_002.png", --背景图片（texture）
					zValue = 1,
					isSliced = true,
					isSprite =true,
					name = "GameObject1"	,
		
				},
				[2] = 
				{
					BackgroundImage = AssetPath.TextureGUIPath.."CommonBigFrame/Common__tuopan_di.png", --背景图片（texture）
					zValue =3,
					Vertices =
					{
						
						Vector4.New( -0.75535, -0.59583, 1 ,0.1625)
						
					},
					isSliced = false,
					isSprite =true,
					name = "GameObject2"	,
		
				},
				[3]=
				{
					BackgroundImage = AssetPath.TextureGUIPath.."Pet_1/pet_chonwu_tupan.png", --背景图片（texture）
					zValue = 9,
					Vertices =
					{
						
						Vector4.New( -0.30892, -0.214583, 0.5607 ,0.1625)
						
					},
					isSliced = false,
					isSprite =true,
					name = "GameObject3"	,
					
				},
			
			}
		},
		
		[2] = 
		{
			layer = "EntityGUI", -- 所在层
			Name = "ObjectDisplayPet" ,
			Position = Vector3.New( 1000 , 1000 , 0 ) ,
			RTWidth = 1120 , -- RenderTexture 宽
			RTHeight = 968, -- RenderTexture 高
			CullingMask = {"EntityGUI"},  -- 裁减列表，填 layer 的名称即可
			CamPosition = Vector3.New( 0 , 0 , 0 ) ,   -- 相机位置
			FieldOfView = 0 ,  -- 视野角度
			BackgroundColor = Color.black ,
			CameraRotate = Vector3.New(6.84,-180,0) ,
			CameraLight = true ,
			BackgroundImageInfo =
			{	
				[0] = 
				{
					BackgroundImage = AssetPath.TextureGUIPath.."RawImage/Common_zd_beijing.png", --背景图片（texture）
					UVs = 
					{   
						Vector4.New( 0.09635 ,0 , 0.9296875, 0.90648),
					} ,
					name = "GameObject"	,
			
				},
				[1] = 
				{
					BackgroundImage = AssetPath.TextureGUIPath.."CommonBigFrame/Common_di_002.png", --背景图片（texture）
					zValue = 1,
					isSliced = true,
					isSprite =true,
					name = "GameObject1"	,
		
				},
				[2] = 
				{
					BackgroundImage = AssetPath.TextureGUIPath.."CommonBigFrame/Common__tuopan_di.png", --背景图片（texture）
					zValue =3,
					Vertices =
					{
						
						Vector4.New( -1, -0.422, 0.25 ,0.3204),
						Vector4.New( 0, -0.422, 1 ,0.3204)
						
					},
					
					isSliced = false,
					isSprite =true,
					name = "GameObject2"	,
		
				},
				[3]=
				{
					BackgroundImage = AssetPath.TextureGUIPath.."Pet_1/pet_chonwu_tupan.png", --背景图片（texture）
					zValue = 9,
					Vertices =
					{
						
						Vector4.New( -0.816875, -0.113265, -0.208125 ,0.25612),
						Vector4.New( 0.25, -0.113265, 0.85875 ,0.25612)
						
					},
					
					isSliced = false,
					isSprite =true,
					name = "GameObject3"	,
					
				},
			}
		},
		
		[3] = 
		{
			layer = "EntityGUI", -- 所在层
			Name = "ObjectDisplayPet" ,
			Position = Vector3.New( 1000 , 1000 , 0 ) ,
			RTWidth = 1631 , -- RenderTexture 宽
			RTHeight = 956, -- RenderTexture 高
			CullingMask = {"EntityGUI"},  -- 裁减列表，填 layer 的名称即可
			CamPosition = Vector3.New( 0 , 0 , 0 ) ,   -- 相机位置
			FieldOfView = 0 ,  -- 视野角度
			BackgroundColor = Color.black ,
			CameraRotate = Vector3.New(6.84,-180,0) ,
			CameraLight = true ,
			BackgroundImageInfo =
			{	
				[0] = 
				{
					BackgroundImage = AssetPath.TextureGUIPath.."RawImage/Common_zd_beijing.png", --背景图片（texture）
					UVs = 
					{   
						Vector4.New( 0.09921 ,0.0148 , 0.94869, 0.949),
					} ,
					name = "GameObject"	,
			
				},
				[1] = 
				{
					BackgroundImage = AssetPath.TextureGUIPath.."CommonBigFrame/Common_di_002.png", --背景图片（texture）
					zValue = 1,
					isSliced = true,
					isSprite =true,
					name = "GameObject1"	,
		
				},
				[2] = 
				{
					BackgroundImage = AssetPath.TextureGUIPath.."CommonBigFrame/Common__tuopan_di.png", --背景图片（texture）
					zValue =3,
					Vertices =
					{
						
						Vector4.New( -1, -0.8389, -0.055 ,-0.0774),
						Vector4.New( -0.0557, -0.8389, 0.9395,-0.0774)
						
					},
					
					isSliced = false,
					isSprite =true,
					name = "GameObject2"	,
		
				},
				[3]=
				{
					BackgroundImage = AssetPath.TextureGUIPath.."Pet_1/pet_chonwu_tupan.png", --背景图片（texture）
					zValue = 9,
					Vertices =
					{
						
						Vector4.New( -0.83, -0.52, -0.299 ,-0.0954),
						Vector4.New( 0.115, -0.52, 0.64598 ,-0.0954)
						
					},
					
					isSliced = false,
					isSprite =true,
					name = "GameObject3"	,
					
				},
		
			}
		},
		[4] = 
		{
			layer = "EntityGUI", -- 所在层
			Name = "ObjectDisplayPet" ,
			Position = Vector3.New( 1000 , 1000 , 0 ) ,
			RTWidth = 1308 , -- RenderTexture 宽
			RTHeight = 957, -- RenderTexture 高
			CullingMask = {"EntityGUI"},  -- 裁减列表，填 layer 的名称即可
			CamPosition = Vector3.New( 0 , 0 , 0 ) ,   -- 相机位置
			FieldOfView = 0 ,  -- 视野角度
			BackgroundColor = Color.black ,
			CameraRotate = Vector3.New(6.84,-180,0) ,
			CameraLight = true ,
			BackgroundImageInfo =
			{	
				[0] = 
				{
					BackgroundImage = AssetPath.TextureGUIPath.."RawImage/Common_zd_beijing.png", --背景图片（texture）
					UVs = 
					{   
						Vector4.New( 0 ,0.0185 , 0.68125, 0.90463),
					} ,
					name = "GameObject"	,
			
				},
				[1] = 
				{
					BackgroundImage = AssetPath.TextureGUIPath.."CommonBigFrame/Common_di_002.png", --背景图片（texture）
					zValue = 1,
					isSliced = true,
					isSprite =true,
					name = "GameObject1"	,
		
				},
				[2] = 
				{
					BackgroundImage = AssetPath.TextureGUIPath.."CommonBigFrame/Common__tuopan_di.png", --背景图片（texture）
					zValue =3,
					Vertices =
					{
						
						Vector4.New( -0.10046, -0.5757, 1,0.1851),
						
						
					},
					
					isSliced = false,
					isSprite =true,
					name = "GameObject2"	,
		
				},
				[3]=
				{
					BackgroundImage = AssetPath.TextureGUIPath.."Pet_1/pet_chonwu_tupan.png", --背景图片（texture）
					zValue = 9,
					Vertices =
					{
						
						Vector4.New( 0.09125, -0.2526, 0.8381 ,0.1256),
					
						
					},
					
					isSliced = false,
					isSprite =true,
					name = "GameObject3"	,
					
				},
		
			}
		},
		
	}
}


return PetModelShowDefine