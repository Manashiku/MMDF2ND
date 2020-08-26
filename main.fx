//----------------------------------------------------------------------------------------------------------------//
//                                            Project diva f shader v3.2                                          //
//                                                  by manashiku                                                  //
//----------------------------------------------------------------------------------------------------------------//
// ive written this damn thing too many times
// you'd think i was done after the first time but apparently i just cant stand my own code after a few months
// for how to use, see the readme
// update v3.2 :
// added f2nd like ground shadows to replace the mmd ground shadow
// added support for control.pmx file for global control of specular, rim, and shadow color
// fixed other minor issues

#define SPECULAR_ADD_LIGHT_DIRECTION float3( 0.0, 1.0, 0.0 ) // adds to the light direction


// matrices :
float4x4 mmd_wvp        : WORLDVIEWPROJECTION;
float4x4 mmd_vp 		: VIEWPROJECTION;
float4x4 mmd_w          : WORLD;
float4x4 mmd_v          : VIEW;
float4x4 centerBone     : CONTROLOBJECT < string name = "(self)"; string item = "下半身"; >;
float4x4 leftFootBone   : CONTROLOBJECT < string name = "(self)"; string item = "左足首"; >;
float4x4 rightFootBone  : CONTROLOBJECT < string name = "(self)"; string item = "右足首"; >;
float3 mmd_cam          : POSITION < string Object = "Camera"; >;
float3 lightDirection   : POSITION < string Object = "Light"; >;

// globals : 
float4 materialDiffuse : DIFFUSE < string Object = "Geometry"; >; // diffuse color, i dont think f uses this
bool use_spheremap; // spa flag
float4 EgColor; // light calculation color 

// control.pmx globals :
float shadowSub : CONTROLOBJECT < string name = "control.pmx"; string item = "shadow-"; >;
float shadowPlus : CONTROLOBJECT < string name = "control.pmx"; string item = "shadow+"; >;
float shadowR : CONTROLOBJECT < string name = "control.pmx"; string item = "shadowR+"; >;
float shadowG : CONTROLOBJECT < string name = "control.pmx"; string item = "shadowG+"; >;
float shadowB : CONTROLOBJECT < string name = "control.pmx"; string item = "shadowB+"; >;
float specularSub : CONTROLOBJECT < string name = "control.pmx"; string item = "specular-"; >;
float specularPlus : CONTROLOBJECT < string name = "control.pmx"; string item = "specular+"; >;
float specularR : CONTROLOBJECT < string name = "control.pmx"; string item = "specularR+"; >;
float specularG : CONTROLOBJECT < string name = "control.pmx"; string item = "specularG+"; >;
float specularB : CONTROLOBJECT < string name = "control.pmx"; string item = "specularB+"; >;
float rimSub : CONTROLOBJECT < string name = "control.pmx"; string item = "rim-"; >;
float rimPlus : CONTROLOBJECT < string name = "control.pmx"; string item = "rim+"; >;
float rimR : CONTROLOBJECT < string name = "control.pmx"; string item = "rimR+"; >;
float rimG : CONTROLOBJECT < string name = "control.pmx"; string item = "rimG+"; >;
float rimB : CONTROLOBJECT < string name = "control.pmx"; string item = "rimB+"; >;


// bone positions :
static float3 centerPos = centerBone._41_42_43;
static float3 leftPos = leftFootBone._41_42_43;
static float3 rightPos = rightFootBone._41_42_43;

// textures : 
texture2D diffuseTexture  : MATERIALTEXTURE;
texture2D specularTexture : MATERIALSPHEREMAP; // rgb specular color, a rim mask
// least i think thats what thats for... 
texture2D rampTexture     : MATERIALTOONTEXTURE;  // 1 - shadow, 2 - specular, 3 - rim, 4 - unused

texture2D shadowTexture : TEXTURE < string ResourceName = "shadow.PNG"; >;

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

sampler shadowSampler = sampler_state
{
    Texture = <shadowTexture>;
    FILTER = ANISOTROPIC; 
    ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;
};

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

struct shadow_out 
{ 
	float4 pos : POSITION; 
	float2 uv  : TEXCOORD0;
	float sa   : TEXCOORD1;
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

shadow_out svs_0(float4 pos : POSITION, float2 uv : TEXCOORD0, uniform float3 bone)
{
	shadow_out o;
	pos.z  = pos.y;
	pos.y  = 0.0;
	pos.w  = 1.0;
	float boneLength = length(pos.y - bone.y);
	pos.xyz *= lerp(4, 4*boneLength, 0.1);
	o.sa = distance(pos.y, bone.y);
	pos.x += bone.x;
	pos.z += bone.z;
	o.pos  = mul(pos, mmd_vp);
	o.uv   = uv;
	
	return o;
}


//----------------------------------------------------------------------------------------------------------------//
// pixel shader
//----------------------------------------------------------------------------------------------------------------//

float4 ps_0(vs_out i, float vface : VFACE)  : COLOR
{
    // generate useful aliases 
    float3 eye    = normalize(i.eye);
    float3 normal = normalize(i.normal); //normalizing this here in the pixel shader helps with preventing the weird blocky specular highlights
    float2 uv     = i.uv;
    float3 add_lightDir = SPECULAR_ADD_LIGHT_DIRECTION;
    float3 h = normalize(eye + (lightDirection + add_lightDir));
    float ndotl = saturate(min(dot(normal, lightDirection), 1)); // shadow
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
    float3 rim       = saturate(tex2D(rampSampler, float2(ndotv, 0.4)).rgb) * 0.5 * specularT.a;
    float3 specular  = saturate(tex2D(rampSampler, float2(ndoth, 0.6)).rgb - (specularSub * 0.25) + (specularPlus * 0.25) + float3(specularR * 0.5, specularG * 0.5, specularB * 0.5)) * specularT.rgb;
    
    // color stuff
    diffuse.rgb = lerp(diffuse.rgb.rgb * shadow - (shadowSub * 0.25) + (shadowPlus * 0.25) + float3(shadowR * 0.5, shadowG * 0.5, shadowB * 0.5), diffuse.rgb, ndotl);
    diffuse.rgb = lerp(diffuse.rgb, specular + diffuse.rgb , ndoth);
    rim         = lerp(rim, float3((rimR * 0.5) + rim.r, (rimG * 0.5) + rim.g, (rimB * 0.5) + rim.b), float3(rimR, rimG, rimB));
    diffuse.rgb = lerp(diffuse.rgb, saturate(diffuse.rgb + rim), ndotv);
    //diffuse.rgb = specular;
    
    diffuse.rgb *= EgColor;
    
    return diffuse;
}

// shadow pixel shader
float4 sps_0(shadow_out i, float vface : VFACE)  : COLOR
{
	float4 shadow = tex2D(shadowSampler, i.uv);
	shadow.a = lerp(shadow.a*0.5,0, i.sa*0.05);
	return shadow;
}


//----------------------------------------------------------------------------------------------------------------//
// techniques 
//----------------------------------------------------------------------------------------------------------------//

// shadow techniques 
technique shadow_0 < string MMDPass = "object_ss"; string Subset = "0"; >
{
	pass modelDraw // keep this in here so it doesn't render only the shadow instead of the material at subset 0
    {
        VertexShader = compile vs_3_0 vs_0();
        PixelShader = compile ps_3_0 ps_0();
    }
	
	pass centerDraw < string Script = " Draw = Buffer; "; >
	{
		//ZENABLE = FALSE;
		ALPHABLENDENABLE = TRUE;
		VertexShader = compile vs_3_0 svs_0(centerPos+float3(0,0,-0.25));
		PixelShader = compile ps_3_0 sps_0();
	}
	pass centerDraw < string Script = " Draw = Buffer; "; >
	{
		//ZENABLE = FALSE;
		ALPHABLENDENABLE = TRUE;
		VertexShader = compile vs_3_0 svs_0(leftPos+float3(0,0,-1));
		PixelShader = compile ps_3_0 sps_0();
	}
	pass centerDraw < string Script = " Draw = Buffer; "; >
	{
		//ZENABLE = FALSE;
		ALPHABLENDENABLE = TRUE;
		VertexShader = compile vs_3_0 svs_0(rightPos+float3(0,0,-1));
		PixelShader = compile ps_3_0 sps_0();
	}
}

technique shadow_1 < string MMDPass = "object"; string Subset = "0"; >
{
    pass modelDraw // keep this in here so it doesn't render only the shadow instead of the material at subset 0
    {
        VertexShader = compile vs_3_0 vs_0();
        PixelShader = compile ps_3_0 ps_0();
    }
	
    pass centerDraw < string Script = " Draw = Buffer; "; >
    {
		//ZENABLE = FALSE;
        ALPHABLENDENABLE = TRUE;
        VertexShader = compile vs_3_0 svs_0(centerPos + float3(0, 0, -0.25));
        PixelShader = compile ps_3_0 sps_0();
    }
    pass centerDraw < string Script = " Draw = Buffer; "; >
    {
		//ZENABLE = FALSE;
        ALPHABLENDENABLE = TRUE;
        VertexShader = compile vs_3_0 svs_0(leftPos + float3(0, 0, -1));
        PixelShader = compile ps_3_0 sps_0();
    }
    pass centerDraw < string Script = " Draw = Buffer; "; >
    {
		//ZENABLE = FALSE;
        ALPHABLENDENABLE = TRUE;
        VertexShader = compile vs_3_0 svs_0(rightPos + float3(0, 0, -1));
        PixelShader = compile ps_3_0 sps_0();
    }
}

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



// stop the mmd ground shadow and edge line from rendering
technique tech_edge < string MMDPass = "edge"; > { }
technique tech_groundShadow < string MMDPass = "shadow"; > { }
