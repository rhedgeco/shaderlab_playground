// WARPS SPACETIME or rather the grab pass texture behind the black hole
// The shader has to be in the Transparent queue so the grab pass happens after everything renders behind it.
// Any "Geometry" objects that are rendered in front will also warp behind the black hole as they are picked up in the grab pass.
// Anything that must be rendered in front, and not be warped behind as well, must be at least in render queue 3000 and up.

Shader "ShaderPlayground/BlackHoleWarp"
{
    Properties
    {
        _Tint ("Tint", Color) = (1.0,0.75,0.75,1)
        _AngleWarp ("Angle Warp", Range(0,1)) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Transparent"}
        LOD 100

        GrabPass
        {
            "_GrabTexture"
        }

        Pass
        {
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
                float4 grabPassUV : TEXCOORD1;
                float3 hitPos : TEXCOORD2;
                float4 origin : TEXCOORD3;
                float4 originScreen : TEXCOORD4;
                float4 vertex : SV_POSITION;
            };

            sampler2D _GrabTexture;
            fixed4 _Tint;
            float _AngleWarp;
            
            // gets the intersection point between a line and a plane
            float3 intersectPoint(float3 lineDir, float3 linePos, float3 planeNormal, float3 planePos)
            {
                float3 posDelta = linePos - planePos;
                float t = dot(posDelta, planeNormal) / dot(lineDir, planeNormal);
                return linePos - (lineDir * t);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.hitPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.grabPassUV = ComputeGrabScreenPos(o.vertex);
                o.origin = mul(unity_ObjectToWorld, float4(0.0,0.0,0.0,1.0));
                o.originScreen = ComputeScreenPos(UnityObjectToClipPos(float4(0.0,0.0,0.0,1.0)));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 viewPos = _WorldSpaceCameraPos; // get the world space position of the camera
                float3 viewDir = i.hitPos - viewPos; // get the view direction vector with the view position and hit position
                
                float3 hitNormal = normalize(i.hitPos - i.origin); // get the normal of the position hit using a vector from the origin to the hit
                float angle = 1 + dot(hitNormal, normalize(viewDir)); // get the angle of the normal from the camera using the dot of the view diretion
                float horizonDist = (angle - _AngleWarp) / ( 1 - _AngleWarp); // get the distance from the 'event horizon' using the angle and warp amount
                float warpAmount = 1 - pow(horizonDist - 1, 8); // calculate warp amount using horizonDist
                
                // multiplying by the w value does some magic to set the UV coords between 0 and 1
                i.grabPassUV /= i.grabPassUV.w;
                i.originScreen /= i.originScreen.w;
                
                // offset the texture so the texture origin is at the blackhole origin
                i.grabPassUV.xy -= 0.5;
                i.grabPassUV.xy -= i.originScreen.xy - 0.5;
                // warp the texture around the black hole
                i.grabPassUV.xy *= warpAmount;
                // undo the offset to return the texture to its original position
                i.grabPassUV.xy += 0.5;
                i.grabPassUV.xy += i.originScreen.xy - 0.5;
                
                // get the warped pixel from the grab pass and tint it
                fixed4 col = tex2Dproj(_GrabTexture, i.grabPassUV) * min(_Tint + (1-_Tint) * warpAmount, 1);
                
                if(angle < _AngleWarp) return 0; // return 0 if the pixel is in the black hole
                if(angle < _AngleWarp + 0.01) return col * (angle - _AngleWarp) / 0.01; // antialias the edges with a slight fade
                return col; // return the warped color
            }
            ENDCG
        }
    }
}
