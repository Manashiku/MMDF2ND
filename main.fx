//----------------------------------------------------------------------------------------------------------------//
//                                            Project diva f shader v3.0                                          //
//                                                  by manashiku                                                  //
//----------------------------------------------------------------------------------------------------------------//
// ive written this damn thing too many times
// you'd think i was done after the first time but apparently i just cant stand my own code after a few months
// for how to use, see the readme
#define GLOBAL_RIM_INT 1.0

// matrices :
float4x4 mmd_wvp        : WORLDVIEWPROJECTION;
float4x4 mmd_w          : WORLD;
float4x4 mmd_v          : VIEW;
float3 mmd_cam          : POSITION < string Object = "Camera"; >;
float3 lightDirection   : DIRECTION < string Object = "Light"; >;

// globals : 
float4 materialDiffuse : DIFFUSE < string Object = "Geometry"; >; // diffuse color, i dont think f uses this
bool use_spheremap; // spa flag
float4 EgColor; // light calculation color 

// textures : 
texture2D diffuseTexture  : MATERIALTEXTURE;
texture2D specularTexture : MATERIALSPHEREMAP; // rgb specular color, a rim mask
// least i think thats what thats for... 
texture2D rampTexture     : MATERIALTOONTEXTURE;  // 1 - shadow, 2 - specular, 3 - rim, 4 - unused

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
// important to set the ramp filter to none, if it isnt set to that then there will be visual errors
// have to clamp the uvs too, thats important.. it will also cause visual errors LOL


//----------------------------------------------------------------------------------------------------------------//
// vertex output
//----------------------------------------------------------------------------------------------------------------//

struct vs_out
{
    float4 pos       : POSITION; 
    float2 uv        : TEXCOORD0;
    float3 normal    : TEXCOORD1;
    float3 eye       : TEXCOORD2;
};

//----------------------------------------------------------------------------------------------------------------//
// vertex shader 
//----------------------------------------------------------------------------------------------------------------//

vs_out vs_0(float4 pos : POSITION, float2 uv : TEXCOORD0, float3 normal : NORMAL)
{
    vs_out o;
    o.pos    = mul(pos, mmd_wvp);
    o.eye    = mmd_cam - mul(pos.xyz, (float3x3) mmd_w);
    o.normal = normal; 
    o.uv     = uv;
    return o;
}

// this is all run of the mill stuff so i dont feel like commenting anything here

//----------------------------------------------------------------------------------------------------------------//
// pixel shader
//----------------------------------------------------------------------------------------------------------------//

float4 ps_0(vs_out i, float vface : VFACE)  : COLOR
{
    // generate useful aliases 
    float3 eye    = normalize(i.eye);
    float3 normal = i.normal;
    float2 uv     = i.uv;
    float3 h = normalize(eye + -lightDirection);
    float ndotl = saturate(min(dot(normal, -lightDirection), 1)); // shadow
    float ndotv = 1.0 - dot(normal, eye); // rim light
    float ndoth   = max(0, pow(dot(normal, h), 1));; // specular
    
    // use ndotl, ndotv, and ndoth as the uv mapping for their respective ramp textures
    // ramps are in an atlas texture and v gets a special value so it reads acrossed the center of where it needs to be
    // this makes it so you dont need to split the texture up into separate ramps.. 
    // saves space and time since that makes it so you dont have to make material specific control files 
    // laziness wins again!
    
    // sample textures
    float4 diffuse   = tex2D(diffuseSampler, uv);
    float4 specularT = tex2D(specularSampler, uv);
    float3 shadow    = tex2D(rampSampler, float2(ndotl , 0.8));
    float3 rim       = saturate(tex2D(rampSampler, float2(ndotv, 0.4)))*0.5 ;
    float3 specular  = saturate(tex2D(rampSampler, float2(ndoth, 0.6)).rgb * specularT.rgb);
    
    // color stuff
    diffuse.rgb = lerp(diffuse.rgb.rgb * shadow, diffuse.rgb, ndotl);
    diffuse.rgb = lerp(diffuse.rgb, specular + diffuse.rgb, ndoth); // this actually looks different than just specular + diffuse
    diffuse.rgb = lerp(diffuse.rgb, saturate(diffuse.rgb + rim), specularT.a);
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

technique tech_1 < string MMDPass = "object"; >
{

    pass modelDraw
    {
        VertexShader = compile vs_3_0 vs_0();
        PixelShader = compile ps_3_0 ps_0();
    }

}