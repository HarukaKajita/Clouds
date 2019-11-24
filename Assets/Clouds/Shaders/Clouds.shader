Shader "Clouds/Test"
{
  Properties
  {
    [IntRange] _Iteration ("Iteration", Range(0, 128)) = 48
    [IntRange] _ShadowIteration ("Shadow Iteration", Range(0, 128)) = 8
  }
  SubShader
  {
    Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
    Blend SrcAlpha OneMinusSrcAlpha
    
    Pass
    {
      CGPROGRAM
      
      #pragma vertex vert
      #pragma fragment frag
      #pragma multi_compile_fog
      #include "UnityCG.cginc"
      #include "Noise.cginc"
      
      struct appdata
      {
        float4 vertex: POSITION;
        float2 uv: TEXCOORD0;
      };
      
      struct v2f
      {
        float2 uv: TEXCOORD0;
        float4 vertex: SV_POSITION;
        float3 oPos: OBJPOS;
      };
      
      uint _Iteration;
      uint _ShadowIteration;
      
      v2f vert(appdata v)
      {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = v.uv;
        o.oPos = v.vertex;
        return o;
      }
      
      float sphere(float3 pos, float r)
      {
        return length(pos) - r;
      }
      
      float map(float3 p)
      {
        float f = fbm(p * 100);
        float s = 1.0 - sphere(p,0.5) + f * 2.5;
        return saturate(s);
      }
      
      fixed4 frag(v2f i): SV_Target
      {
        float3 oCamPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
        float3 oLightDir = normalize(mul((float3x3)unity_WorldToObject, _WorldSpaceLightPos0));
        float3 dir = normalize(oCamPos - i.oPos);
        float stepLength = 1.0 / _Iteration;
        float shadowStepLength = 1.0 / _ShadowIteration;
        float3 pos = i.oPos + dir * stepLength;
        float4 col = float4(0, 0, 0, 1);
        float density = 0;
        
        for (uint j = 0; j < _Iteration; j ++)
        {
          float d = map(pos);
          float sphereDist = sphere(pos, 0.5);
          if(sphereDist > 0) {
              pos += dir * stepLength;
              break;
          }
          if (d > 0.001)
          {
            float3 lpos = pos + oLightDir * shadowStepLength;//
            float shadow = 0;//
            for (uint k = 0; k < _ShadowIteration; k ++)
            {
              lpos += oLightDir * shadowStepLength;
              shadow += map(lpos);
            }
            density = saturate(d / _Iteration * 20);
            float s = exp(-shadow / _ShadowIteration * 3);
            col.rgb = (float3)s * density * col.a;
            col.a = 1 - density;
          }
          pos += dir * stepLength;
        }
        return col;
      }
      ENDCG
      
    }
  }
}
