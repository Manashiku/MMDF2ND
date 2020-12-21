//--------------------------------------------------------------------------------
// glow On f2nd shader
//--------------------------------------------------------------------------------
float4x4 mmd_wvp : WORLDVIEWPROJECTION;
float4x4 mmd_w   : WORLD;

float3 lightDirection : DIRECTION < string Object = "Light"; >;
float3 cameraPosition : POSITION < string Object = "Camera"; >;

float4 EgColor; // this is the mmd light color control
// its separate to the material colors

bool use_texture; // if no texture, i will make the color default to all white with alpha = 1.0
bool use_spheremap; // flag for if the sphere map is used

//float specularR : CONTROLOBJECT < string name = "Controller.PMX"; string item = "Glow-"; >;
//float specularG : CONTROLOBJECT < string name = "Controller.PMX"; string item = "Glow-"; >;
//float specularB : CONTROLOBJECT < string name = "Controller.PMX"; string item = "Glow-"; >;
//float glowDown : CONTROLOBJECT < string name = "Controller.PMX"; string item = "Glow-"; >;
//float glowDown : CONTROLOBJECT < string name = "Controller.PMX"; string item = "Glow-"; >;
//float glowDown : CONTROLOBJECT < string name = "Controller.PMX"; string item = "Glow-"; >;
//float glowDown : CONTROLOBJECT < string name = "Controller.PMX"; string item = "Glow-"; >;


// get correct color in MMD
float4 materialDiffuse : DIFFUSE < string Object = "Geometry"; >;
float4 materialAmbient : AMBIENT < string Object = "Geometry"; >;
float4 materialEmissive : EMISSIVE < string Object = "Geometry"; >;
float3 lightDiffuse : DIFFUSE < string Object = "Light"; >;
float3 lightAmbient : AMBIENT < string Object = "Light"; >;
static float4 modelDiffuse = materialDiffuse * float4(lightDiffuse, 1.0);
static float4 modelAmbient = saturate(materialAmbient * float4(lightAmbient, 1.0) + materialEmissive);
static float4 modelColor = saturate(modelAmbient + modelDiffuse); // this final model color will be multiplied by the diffuse texture


//--------------------------------------------------------------------------------
// textures : 

texture diffuseTexture  : MATERIALTEXTURE;
texture specularTexture : MATERIALSPHEREMAP;
texture rampTexture     : MATERIALTOONTEXTURE; 

//--------------------------------------------------------------------------------
// samplers : 
sampler diffuseSampler = sampler_state
{
    texture = <diffuseTexture>;
    FILTER = ANISOTROPIC;
    ADDRESSU = WRAP; // id love to set this as clamp but people are too dumb to remember to edit the uvs so theyre [0-1]
    ADDRESSV = WRAP;
};

sampler specularSampler = sampler_state
{
    texture = <specularTexture>;
    ADDRESSU = WRAP;
    ADDRESSV = WRAP;
    FILTER = ANISOTROPIC;
};

sampler rampSampler = sampler_state
{
    texture = <rampTexture>;
    FILTER = NONE;
    ADDRESSV = CLAMP; // its important to clamp the uvs and to set the filter to non because it gets... bad
    ADDRESSU = CLAMP;
};

//--------------------------------------------------------------------------------
// structures : 

struct vs_out
{
    float4 pos : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : TEXCOORD1;
    float3 eye : TEXCOORD2;
};

//--------------------------------------------------------------------------------
// vertex shaders : 

vs_out vs_0(float4 pos : POSITION, float2 uv : TEXCOORD0, float3 normal : NORMAL)
{
    vs_out o;
    
    o.pos = mul(pos, mmd_wvp);
    o.uv = uv;
    o.normal = mul(normal, (float3x3) mmd_w); // im pretty sure that mmds normals are already in world space
    // im not sure of that much anymore like i used to be because ive been encountering stupid issues that my dumb
    // stupid proud self didnt notice before
    // something something i was young and proud 
    // something something older and wiser
    // meh
    o.eye = cameraPosition - mul(pos.xyz, (float3x3) mmd_w);
    
    // i think thats all i need for this, we'll see
    return o;
}

//--------------------------------------------------------------------------------
// pixel shaders : 

float4 ps_0(vs_out i) : COLOR0 // my dumbass will never EVER write these things like Out OUT in In IN, o and i are faster to type
{
    // generate useful aliases
    float2 uv = i.uv; 
    float3 normal = normalize(i.normal);
    float3 eye = normalize(i.eye); // i dont think it matters where you normalize the eye vector, i just do it in the pixel shader out of habit
    // anyway normalizing these two things is really important because otherwise it leads to a bunch of messed up things...
    
    // initalize color
    float4 color = modelColor;
    // this will serve as the base color forthe character models since i dont think any of them use anything like a material color. . \
    // i know some of the stages use things like vertex color but honestly, adding support for stages in a /character/ shader is really fucking weird 
    // thats your que to stop fucking doing that you weirdos
    
    // calculate the halfvector 
    float3 h = normalize(eye + -lightDirection);
    // calculate ndotl, ndotv, and ndoth now
    // these will be used as the uv mapping for the ramps
    float ndotl = dot(normal, -lightDirection) * 0.5 + 0.5; // its important to not do the normal saturate or clamping because it will seriously mess up the ramps
    // the * 0.5 + 0.5  is really important too, because it brings it into the [0-1] space
    float ndotv = 1.0 - dot(normal, eye); // nothing special or new, just keep it simple
    float ndoth = dot(h, normal);
    
    // sample the textures
    float4 diffuse = use_texture ? tex2D(diffuseSampler, uv) : 1.0; // start with the diffuse texture first
    float4 specular = use_spheremap ? tex2D(specularSampler, uv) : 0.0;
    float3x3 ramp =
    {
                     tex2D(rampSampler, float2(ndotl, 0.8)).rgb, // shadow
                     tex2D(rampSampler, float2(ndoth, 0.6)).rgb * specular.rgb, // specular
                     tex2D(rampSampler, float2(ndotv, 0.4)).rgb * specular.a * specular.rgb // rim
    };
    
    // now we can finally start processing the color
    // start with the diffuse color because its the most important
    color = diffuse;
    
    // now onto everything else
    color.rgb = color.rgb * ramp[0];
    color.rgb = color.rgb + ramp[1];
    color.rgb = color.rgb + ramp[2];
    
    // debug 
    
    // output the final color
    return color;
}

//--------------------------------------------------------------------------------
// techniques

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
technique tech_edge < string MMDPass = "edge"; >
{
}
technique tech_groundShadow < string MMDPass = "shadow"; >
{
}