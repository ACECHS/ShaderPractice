Shader "Custom/DistortionMask(BillBoard)"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_Depth("Depth",float) = 0 
    }
    SubShader
    {
		Tags{
			 "RenderType" = "Transparent"
			 "Queue" = "Transparent+1"
			 "DisableBatching" = "True"//批处理会合并模型，造成物体本地坐标丢失，所以忽视批处理
			}
		Zwrite Off
		Cull Off
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
				float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
				float4 scrPos : TEXCOORD1;
            };

            sampler2D _MainTex;
			sampler2D _CameraDepthTexture;
            float4 _MainTex_ST;
			float _Depth;

            v2f vert (appdata v)
            {
				//公告牌实现
                v2f o;
				float3 center = float3(0, 0, 0);
				float3 viewer = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
				float3 normalDir = normalize(viewer - center);
				float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);
				float3 rightDir = normalize(cross(upDir, normalDir));
				upDir = normalize(cross(normalDir, rightDir));
				float3 centerOff = v.vertex.xyz - center;
				v.vertex.xyz = center + rightDir * centerOff.x + center + upDir * centerOff.y + center + normalDir * centerOff.z;

				o.pos = UnityObjectToClipPos(v.vertex);
				//获得当前裁剪坐标对应的屏幕坐标，后面用于采样背景深度纹理的uv
				o.scrPos = ComputeScreenPos(o.pos);
				//计算当前顶点的摄像机空间的深度既视锥体深度，范围为[Near,Far]，将该值返回到o.scrPos.z，该函数需用在顶点着色器中
				//等同-UnityObjectToViewPos(v.vertex).z，用于后续同背景深度比较
				COMPUTE_EYEDEPTH(o.scrPos.z);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 采样深度纹理并将其转换为线性
				float Zbuffer = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)));
				float Z = i.scrPos.z;
				//比较深度纹理，_Depth用于缓冲因遮挡而导致的扰动效果突变的现象，将遮挡关系变为alpha值影响片元可见性，完成自定义的深度测试
				float alpha = smoothstep( -_Depth , _Depth , Zbuffer-Z );
                fixed4 col = tex2D(_MainTex, i.uv)*alpha;
                return col;
            }
            ENDCG
        }
    }
}
