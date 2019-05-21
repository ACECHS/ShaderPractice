Shader "Custom/Distortion(GrabPass)"
{
	Properties
	{
		_DistortStrength("热扰动强度",Range(0,1)) = 0.5
		_DistortVelocity("热扰动速率",Range(0,1)) = 0.5
		_XDensity("噪声密度(水平)",float) = 1
		_YDensity("噪声密度(竖直)",float) = 1
		_NoiseTex("噪声贴图",2D) = "white"{} 
		_Mask("噪声遮罩",2D) = "Black"{}

	}
    SubShader
    {   
		Tags{
			 "RenderType" = "Transparent"
			 "Queue" = "Transparent+1"
			 "DisableBatching"="True"//批处理会合并模型，造成物体本地坐标丢失，公告牌效果失效，所以忽视批处理
			}
		Zwrite Off
		GrabPass{"_GrabTex"}//获取当前屏幕图像，并存入_GrabTex纹理
		Cull Off

        Pass
        { 
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct v2f
            {
                float4 pos : SV_POSITION;
				float4 grabPos : TEXCOORD0;
				float4 uv : TEXCOORD1;
            };

            sampler2D _GrabTex;
			sampler2D _NoiseTex;
			sampler2D _Mask;
			float _XDensity;
			float _YDensity;
			float4 _NoiseTex_ST;
			fixed _DistortStrength;
			fixed _DistortVelocity;

            v2f vert (appdata_base v)
            {
                v2f o;
				//广告牌实现
				float3 center = float3(0, 0, 0);
				float3 viewer = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
				float3 normalDir = normalize(viewer - center);
				float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);
				float3 rightDir = normalize(cross(upDir, normalDir));
				upDir = normalize(cross(normalDir, rightDir));
				float3 centerOff = v.vertex.xyz - center;
				float3 localPos = center + rightDir * centerOff.x + center + upDir * centerOff.y + center + normalDir * centerOff.z;
				//热扰动实现
				o.pos = UnityObjectToClipPos(float4(localPos,1));
				o.grabPos = ComputeGrabScreenPos(o.pos);//获得当前裁剪坐标对应的屏幕坐标，后面用于采样抓取纹理的uv
				//通过缩放纹理控制噪声纹理密度，改变扰动密集感
				_NoiseTex_ST.xy *=float2(_XDensity,_YDensity);
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _NoiseTex);//这是用于采样噪声的有缩放变化的uv
				o.uv.zw = v.texcoord;//这是用于采样_Mask贴图的正常uv
				o.uv.xy -= _Time.y * _DistortVelocity;//根据时间因素在uv上不断变化从而获得流动的噪点值，增加热扰动流动感
                return o;
            }

			fixed4 frag(v2f i) : SV_Target
			{
				float2 offset = tex2D(_NoiseTex,i.uv.xy).xy;//采样噪声，获得rg两个通道上的值作为两个方向上的偏移量
				offset = (offset - 0.5) * 2* _DistortStrength;//原取得的值在0到1，重映射到-1到1，增加扰动方向的随机感，并用_DistortStrength更改采样偏移距离，控制扰动强度
				i.grabPos.xy += tex2D(_Mask, i.uv.zw).x*offset;//采样偏移量乘上采样遮罩的值，该值为0到1，既遮罩白色部分正常扰动，黑色部分无扰动，中间灰色则为过度
				fixed4 color = tex2Dproj(_GrabTex,i.grabPos);//偏移后的屏幕坐标去采样抓取的屏幕纹理
			    return color;
				 
            }
            ENDCG
        }
    }
}
