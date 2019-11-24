Shader "Clouds/Test2"
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
        float s = 1.0 - sphere(p, 0.5) + f * 2.5;
        return saturate(s);
      }
      
      fixed4 frag(v2f i): SV_Target
      {
        float3 oCamPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
        float3 dir = normalize(i.oPos - oCamPos);
        float stepLength = 1.0 / _Iteration;
        float3 pos = i.oPos + dir * stepLength;
        float4 col = float4(1, 1, 1, 0);
        
        for (uint j = 0; j < _Iteration; j ++)
        {
          float fbmVal = fbm(pos*4 + _Time.y);
          float strength = 1 - length(pos)*2 + valNoise(pos*10+_Time.x)*0.3;
          //return fixed4((fixed3)strength,1);
          if (strength < 0)
          {
            pos += dir * stepLength;
            continue;
          }
          strength *= 1;
          fbmVal *= abs(strength);
          col.rgb = lerp(fbmVal, col.rgb, col.a);
          col.a += fbmVal*0.1;
          col.a = saturate(col.a);
          pos += dir * stepLength;
        }
        //この辺適当なので、暑さとか、密度みたいな値で透明度を最終的に決定する
        col.a *= col.rgb;
        col.a = 1 - pow(1 - col.a, 3);
        col.rgb =1;
        return col;
      }
      ENDCG
      
    }
  }
}
