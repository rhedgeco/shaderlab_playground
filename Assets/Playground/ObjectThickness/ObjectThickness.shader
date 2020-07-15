// Renders the thickness of the object from the cameras perspective
// Useful for: Something probably lol

Shader "ShaderPlayground/ObjectThickness"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Cull Front
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float depth : DEPTH;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.depth = -UnityObjectToViewPos(v.vertex).z;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float d = i.depth;
                return fixed4(0,0,0,-d);
            }
            ENDCG
        }
        
        GrabPass { "_BackDepth" }
        
        Pass
        {
            Cull Back
            ZWrite On
            
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
    
            #include "UnityCG.cginc"
    
            struct appdata
            {
                float4 vertex : POSITION;
            };
    
            struct v2f
            {
                float depth : DEPTH;
                float4 vertex : SV_POSITION;
                float4 grabCoord : TEXCOORD0;
            };
    
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.depth = -UnityObjectToViewPos(v.vertex).z;
                o.grabCoord = ComputeGrabScreenPos(o.vertex);
                return o;
            }
    
            sampler2D _MainTex;
            sampler2D _BackDepth;
    
            fixed4 frag (v2f i) : SV_Target
            {
                float ld = -tex2Dproj(_BackDepth, i.grabCoord).w;
                float d = i.depth;
                float t = ld - d;
                if(t < 0) return 0;
                return ld - d;
            }
            ENDCG
            
        }
    }
}
