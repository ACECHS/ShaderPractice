Shader "Customt/Distortion(PostEffect)"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
		_NoiseTex("Base (RGB)", 2D) = "Black" {}//默认给黑色，也就是不会偏移
	}
		SubShader
	{
		Zwrite Off
		Cull Off

		Pass
		{
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag
			#include "UnityCG.cginc"

			uniform sampler2D _MainTex;
			uniform sampler2D _NoiseTex;
			uniform sampler2D _MaskTex;
			uniform float _DistortStrength;
			uniform float _DistortVelocity;
			uniform float _XDensity;
			uniform float _YDensity;
			



			fixed4 frag(v2f_img i) : SV_Target
			{
				//通过缩放纹理控制噪声纹理密度，改变扰动密集感
				float2  _NoiseUV = i.uv*float2(_XDensity,_YDensity);
				//根据时间因素从而获得不断变化的噪点值，增加热扰动流动感
				float2 offset = tex2D(_NoiseTex, _NoiseUV -_Time.y * _DistortVelocity).xy;
				//原取得的值在0到1，重映射到-1到1，增加扰动方向的随机感，并用_DistortStrength更改采样偏移距离，控制扰动强度
				offset = (offset - 0.5) * 2 * _DistortStrength;
				//采样偏移量乘上采样遮罩的值，该值为0到1，既遮罩白色部分正常扰动，黑色部分无扰动，中间灰色则为过度
				i.uv += offset*tex2D(_MaskTex, i.uv).x;
				return tex2D(_MainTex, i.uv);
			}
			ENDCG
		}
	}
}
