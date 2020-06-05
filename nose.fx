//----------------------------------------------------------------------------------------------------------------//
//                                            Project diva f shader v3.0                                          //
//                                                  by manashiku                                                  //
//----------------------------------------------------------------------------------------------------------------//
// ive written this damn thing too many times
// you'd think i was done after the first time but apparently i just cant stand my own code after a few months
// for how to use, see the readme
#define GLOBAL_RIM_INT 0.3
#define GLOBAL_SPEC_INT 1.0


// matrices :
float4x4 mmd_wvp : WORLDVIEWPROJECTION;
float4x4 mmd_w : WORLD;
float4x4 mmd_v : VIEW;
float3 mmd_cam : POSITION < string Object = "Camera"; >;
float3 lightDirection : POSITION < string Object = "Light"; >;



// globals : 
float4 materialDiffuse : DIFFUSE < string Object = "Geometry"; >; // diffuse color, i dont think f uses this
bool use_spheremap; // spa flag
float4 EgColor; // light calculation color 

// textures : 
texture2D diffuseTexture : MATERIALTEXTURE;
texture2D specularTexture : MATERIALSPHEREMAP; // rgb specular color, a rim mask
texture2D rampTexture : MATERIALTOONTEXTURE;  // 1 - shadow, 2 - specular, 3 - rim, 4 - unused

//----------------------------------------------------------------------------------------------------------------//
// samplers : 
//----------------------------------------------------------------------------------------------------------------//

sampler diffuseSampler = sampler_state
{
    Texture = <diffuseTexture>;
    FILTER = ANISOTROPIC;
    ADDRESSU = WRAP;
    ADDRESSV = WRAP;
};

sampler specularSampler = sampler_state
{
    Texture = <specularTexture>;
    FILTER = ANISOTROPIC;
    ADDRESSU = WRAP;
    ADDRESSV = WRAP;
};

sampler rampSampler = sampler_state
{
    Texture = <rampTexture>;
    FILTER = NONE;
    ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;
};

//----------------------------------------------------------------------------------------------------------------//
// vertex output
//----------------------------------------------------------------------------------------------------------------//

struct vs_out
{
    float4 pos : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : TEXCOORD1;
    float3 eye : TEXCOORD2;
};

//----------------------------------------------------------------------------------------------------------------//
// vertex shader 
//----------------------------------------------------------------------------------------------------------------//

vs_out vs_0(float4 pos : POSITION, float2 uv : TEXCOORD0, float3 normal : NORMAL)
{
    vs_out o;
    o.pos = mul(pos, mmd_wvp);
    o.eye = mmd_cam - mul(pos.xyz, (float3x3) mmd_w);
    o.normal = mul(normal, (float3x3) mmd_w);
    o.uv = uv;
    return o;
}

//----------------------------------------------------------------------------------------------------------------//
// pixel shader
//----------------------------------------------------------------------------------------------------------------//

float4 ps_0(vs_out i, float vface : VFACE)  : COLOR
{
    if (lightDirection.x >= 0)
    {
        lightDirection.x = 1;
    }
    else if (lightDirection.x < 0)
    {
        lightDirection.x = -1;
    }
    // generate useful aliases 
    float3 eye = normalize(i.eye);
    float3 normal = i.normal;
    float2 uv = i.uv;
    float3 h = normalize(eye + lightDirection);
    float comp = 1.0;
    float ndotl = dot(normal, lightDirection); // shadow
    float ndotv = 1.0 - dot(normal, eye); // rim light
    float ndoth = saturate(max(0, pow(dot(normal, h), 1)));; // specular
    
    // sample textures
    float4 diffuse = tex2D(diffuseSampler, uv);
    float4 specularT = tex2D(specularSampler, uv);
    float3 shadow = tex2D(rampSampler, float2(ndotl * 0.5 + 0.5, 1));
    float3 rim = saturate(tex2D(rampSampler, float2(ndotv * 0.5 + 0.5, 0.4))) * GLOBAL_RIM_INT;
    float3 specular = saturate(tex2D(rampSampler, float2(ndoth, 0.6)).rgb * specularT.rgb * GLOBAL_SPEC_INT);
    
    // color stuff
    diffuse.rgb = specular + diffuse.rgb ;
    diffuse.rgb = diffuse.rgb * shadow;
    diffuse.rgb = lerp(diffuse.rgb, diffuse.rgb+rim, specularT.a);
    //diffuse.rgb = specular;
    
    diffuse.rgb *= EgColor;
    
    return diffuse;
}

//----------------------------------------------------------------------------------------------------------------//
// techniques 
//----------------------------------------------------------------------------------------------------------------//

technique tech_0 < string MMDPass = "object_ss"; >
{

    pass modelDraw
    {
        VertexShader = compile vs_3_0 vs_0();
        PixelShader = compile ps_3_0 ps_0();
    }

}