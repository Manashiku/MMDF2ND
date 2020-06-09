//----------------------------------------------------------------------------------------------------------------//
//                                            Project diva f shader v3.0                                          //
//                                                  by manashiku                                                  //
//----------------------------------------------------------------------------------------------------------------//
// gonna use the character shader as a base to make the stage shader
// even tho the stages dont use the same kind of maps
// lol 

//#define IS_ANIMATED
    #define FRAME_NUMBER 0 // start frame 
    #define TOTAL_FRAMES 8 // total number of frames
    #define ANIM_SPEED -1.0 // play back speed
    //#define IS_SCROLL 



// matrices :
float4x4 mmd_wvp        : WORLDVIEWPROJECTION;
float4x4 mmd_w          : WORLD;
float4x4 mmd_v          : VIEW;
float3 mmd_cam          : POSITION < string Object = "Camera"; >;
float3 lightDirection   : POSITION < string Object = "Light"; >;

// globals : 
float4 materialDiffuse : DIFFUSE < string Object = "Geometry"; >; // diffuse color, i dont think f uses this
float time : TIME;
bool use_spheremap; // spa flag
float4 EgColor; // light calculation color 

// animation globals : 
static float frameNumber = FRAME_NUMBER;
static float totalFrames = TOTAL_FRAMES;
static float animationSpeed = ANIM_SPEED;


// textures : 
texture2D diffuseTexture  : MATERIALTEXTURE;
texture2D specularTexture : MATERIALSPHEREMAP; // specular map
texture2D lightTexture : MATERIALTOONTEXTURE; // light map

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

sampler lightSampler = sampler_state
{
    Texture = <lightTexture>;
    FILTER = ANISOTROPIC;
    ADDRESSU = WRAP;
    ADDRESSV = WRAP;
};

// important to set the ramp filter to none, if it isnt set to that then there will be visual errors
// have to clamp the uvs too, thats important.. it will also cause visual errors LOL


//----------------------------------------------------------------------------------------------------------------//
// vertex output
//----------------------------------------------------------------------------------------------------------------//

struct vs_out
{
    float4 pos         : POSITION; 
    float2 uv          : TEXCOORD0;
    float3 normal      : TEXCOORD1;
    float3 eye         : TEXCOORD2;
    float2 uv1         : TEXCOORD3;
    float4 vc : TEXCOORD4;
};

//----------------------------------------------------------------------------------------------------------------//
// vertex shader 
//----------------------------------------------------------------------------------------------------------------//

vs_out vs_0(float4 pos : POSITION, float2 uv : TEXCOORD0, float3 normal : NORMAL, float2 uv1 : TEXCOORD1, float4 vertexColor : TEXCOORD2)
{
    vs_out o;
    o.pos    = mul(pos, mmd_wvp);
    o.eye    = mmd_cam - mul(pos.xyz, (float3x3) mmd_w);
    o.normal = normal; 
    o.uv     = uv;
    o.uv1    = uv1;
    o.vc     = vertexColor;
    return o;
}

// this is all run of the mill stuff so i dont feel like commenting anything here

//----------------------------------------------------------------------------------------------------------------//
// pixel shader
//----------------------------------------------------------------------------------------------------------------//

float4 ps_0(vs_out i, float vface : VFACE, uniform bool UseToon)  : COLOR
{
    // generate useful aliases 
    float2 uv     = i.uv;
    float2 uv1    = i.uv1;
    float3 normal = i.normal;
    float3 eye = normalize(i.eye);
    float3 h = normalize(i.eye + lightDirection);
    float ndoth = max(0, pow(dot(normal, h), 1));
    
    #if defined(IS_ANIMATED)
    frameNumber += frac(time * animationSpeed) * totalFrames;
    float frame = clamp(frameNumber, 0, totalFrames);
    float frameUpdate;
    float mod = modf(frame / 1, frameUpdate);
    #ifndef IS_SCROLL
    uv.x += frameUpdate / totalFrames;
    #else 
    uv.x += time * animationSpeed;
    #endif
    #endif

    
    // sample textures
        float4 diffuse = tex2D(diffuseSampler, uv);
    float4 light   = tex2D(lightSampler  , uv1);
    if (use_spheremap)
    {
        diffuse.rgb = lerp(diffuse.rgb, diffuse.rgb + ndoth, tex2D(specularSampler, uv).a);
    }
    
    
    
    diffuse *= i.vc;
	if(UseToon)
	{
		diffuse *= light;
	}
   // diffuse.a = diffuse.r;

    

    //diffuse.rgb *= EgColor;
    
    return diffuse;
}

//----------------------------------------------------------------------------------------------------------------//
// techniques 
//----------------------------------------------------------------------------------------------------------------//

technique tech_0 < string MMDPass = "object_ss"; >
{

    pass modelDraw
    {
       
        AlphaBlendEnable = TRUE;
        VertexShader = compile vs_3_0 vs_0();
        PixelShader = compile ps_3_0 ps_0();
    }

}

technique tech_1 < string MMDPass = "object"; >
{

    pass modelDraw
    {
	    AlphaBlendEnable = TRUE;
        VertexShader = compile vs_3_0 vs_0();
        PixelShader = compile ps_3_0 ps_0();
    }

}