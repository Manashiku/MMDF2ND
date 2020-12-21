//----------------------------------------------------------------------------------------------------------------//
//                                               Project Diva F2nd                                                //
//                                                  by manashiku                                                  //
//----------------------------------------------------------------------------------------------------------------//

float2 viewportSize : VIEWPORTPIXELSIZE; 
static float2 viewportOffset = (float2(0.5, 0.5) / viewportSize);
static float2 sampleStep     = (float2(1.0, 1.0) / viewportSize);
static float2 blurOffset = (float2(2.0, 2.0) / (viewportSize)) * 2;

float4 clearColor = { 0.5, 0.5, 0.5, 1.0 };
float clearDepth  = 1.0;

float script : STANDARDSGLOBAL < 
    string ScriptOutput = "color"; 
    string ScriptClass = "scene"; 
    string ScriptOrder = "postprocess"; 
> = 0.8;

#include <material/controllerSliders.fxh>

//----------------------------------------------------------------------------------------------------------------//
// textures : 
texture2D baseView     : RENDERCOLORTARGET;
texture depthBuffer    : RENDERDEPTHSTENCILTARGET;
texture2D blurDownView : RENDERCOLORTARGET;
texture2D blurXView : RENDERCOLORTARGET /*<float2 ViewportRatio = {1.0/4.0, 1.0/4.0};>*/;
texture2D blurYView : RENDERCOLORTARGET /*<float2 ViewportRatio = {1.0/4.0, 1.0/4.0};>*/;

//texture2D blurX2View : RENDERCOLORTARGET /*<float2 ViewportRatio = {1.0/4.0, 1.0/4.0};>*/;
//texture2D blurY2View : RENDERCOLORTARGET /*<float2 ViewportRatio = {1.0/4.0, 1.0/4.0};>*/;

texture2D mixView      : RENDERCOLORTARGET;
texture2D finalView    : RENDERCOLORTARGET;

texture mainShader : OFFSCREENRENDERTARGET < 
    string Description   = "Main shader for the pdf2nd shader. Think of it like a material tab, change between the main shader and the nose shader etc";
    float4 ClearColor    = { 0.5, 0.5, 0.5, 1.0 }; 
    float  ClearDepth    = 1.0;
    bool   AntiAlias     = true;
    string DefaultEffect = 
                    "self=hide;" 
                    "Controller.pmx=hide;"  // hide the controller mesh from being displayed in this render
                    "*=material/main.fx;";
>;

texture glowShader : OFFSCREENRENDERTARGET < 
    string Description   = "Glow tab, default effect is off and to turn on the glowing you'll need to change to the other sub effect";
    float4 ClearColor    = { 0.0, 0.0, 0.0, 1.0 }; 
    float  ClearDepth    = 1.0;
    bool   AntiAlias     = true;
    float2 ViewportRatio = {1.0/4.0, 1.0/4.0};
    string DefaultEffect = 
                    "self=hide;" 
                    "Controller.pmx=hide;"  // hide the controller mesh from being displayed in this render
                    "*=material/glowOFF.fx;";
>;

//----------------------------------------------------------------------------------------------------------------//
// samplers :

sampler mainSampler = sampler_state
{
    texture = <mainShader>;
    FILTER = NONE;
    ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;
};

sampler glowSampler = sampler_state
{
    texture = <glowShader>;
    FILTER = LINEAR;
    ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;
};

sampler blurDownSampler = sampler_state
{
    texture = <blurDownView>;
    FILTER = LINEAR;
    ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;
};

sampler blurXSampler = sampler_state
{
    texture = <blurXView>;
    FILTER = LINEAR;
    ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;
};

sampler blurYSampler = sampler_state
{
    texture = <blurYView>;
    FILTER = LINEAR;
    ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;
};

//sampler blurX2Sampler = sampler_state
//{
//    texture = <blurXView>;
//    FILTER = LINEAR;
//    ADDRESSU = CLAMP;
//    ADDRESSV = CLAMP;
//};

//sampler blurY2Sampler = sampler_state
//{
//    texture = <blurYView>;
//    FILTER = LINEAR;
//    ADDRESSU = CLAMP;
//    ADDRESSV = CLAMP;
//};

sampler mixSampler = sampler_state
{
    texture = <mixView>;
    FILTER = NONE;
    ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;
};

//----------------------------------------------------------------------------------------------------------------//
// functions : 
static const float2 kernelX[13] =
{
    { -6, 0 },
    { -5, 0 },
    { -4, 0 },
    { -3, 0 },
    { -2, 0 },
    { -1, 0 },
    { 0, 0 },
    { 1, 0 },
    { 2, 0 },
    { 3, 0 },
    { 4, 0 },
    { 5, 0 },
    { 6, 0 },
};

static const float2 kernelY[13] =
{
    { 0, -6 },
    { 0, -5 },
    { 0, -4 },
    { 0, -3 },
    { 0, -2 },
    { 0, -1 },
    { 0, 0 },
    { 0, 1 },
    { 0, 2 },
    { 0, 3 },
    { 0, 4 },
    { 0, 5 },
    { 0, 6 },
};
static const float blurWeight[13] =
{
    0.002216,
    0.008764,
    0.026995,
    0.064759,
    0.120985,
    0.176033,
    0.199471,
    0.176033,
    0.120985,
    0.064759,
    0.026995,
    0.008764,
    0.002216,
};

//float4 blurImage(float2 uv, float2 offset, bool blurDirection, sampler2D tex)
//{
//    offset = (blurDirection) ? float2(offset.x, 0) : float2(0, offset.y);
//    float4 sum = tex2D(tex, uv) * blurWeight[0];
    
//    [unroll]
//    for (int i = 1; i < 8; i++)
//    {
//        float3 color = tex2D(tex, uv + offset * i).rgb + tex2D(tex, uv - offset * i).rgb;
//        sum.rgb = sum.rgb + color * blurWeight[i];
//    }
    
//    return sum;
//}

float4 blurImage(sampler texSampler, float2 uv, float2 offset, float2 kernel[13])
{
    float4 color = 0;
    float2 offset_new = (float2(2.0, 2.0) / offset);
    // sampler = texture
    // uv = uv
    // offset = viewportSize
    [unroll]
    for (int p = 0; p < 13; p++)
    {
        color += tex2D(texSampler, uv + (kernel[p] / offset_new)) * blurWeight[p];
    }
    return color;
}


//----------------------------------------------------------------------------------------------------------------//
// structures : 
struct vs_out
{
    float4 pos : POSITION;
    float2 uv : TEXCOORD0;
};

struct blur_out
{
    float4 pos    : POSITION;
    float2 uv     : TEXCOORD0;
    float2 offset : TEXCOORD1;
};

//----------------------------------------------------------------------------------------------------------------//
// vertex shaders : 

vs_out vs_0(float4 pos : POSITION, float2 uv : TEXCOORD0)
{
    vs_out o;
    o.pos = pos;
    o.uv = uv + viewportOffset;
    return o;
}

blur_out vs_blur(float4 pos : POSITION, float2 uv : TEXCOORD0)
{
    blur_out o;
    o.pos = pos;
    o.uv = uv + viewportOffset; // * level 
    o.offset = sampleStep; // * level
    return o; // in the pixel shaders ill do the * level
}

//----------------------------------------------------------------------------------------------------------------//
// pixel shaders :         

float4 ps_downscale(blur_out i) : COLOR
{
    return tex2D(glowSampler, i.uv );
}

float4 ps_blurX(blur_out i) : COLOR
{
    return blurImage(glowSampler, i.uv * 4, sampleStep * 4, kernelX);

}

float4 ps_blurY(blur_out i) : COLOR
{
    return blurImage(blurXSampler, i.uv , sampleStep , kernelY);
}

//float4 ps_blurX2(blur_out i) : COLOR
//{
//    return blurImage(blurYSampler, i.uv, sampleStep , kernelX);

//}

//float4 ps_blurY2(blur_out i) : COLOR
//{
//    return blurImage(blurX2Sampler, i.uv, sampleStep , kernelY);
//}


float4 ps_mix(vs_out i) : COLOR
{
    // aliases
    float2 uv = i.uv;
        
    // sample needed textures 
    float4 main = tex2D(mainSampler, uv);
    
    // process color
    // gamma control
    gammaUp = gammaUp == 0 ? 1 : 1.0 + gammaUp;
    gammaDown = gammaUp == 0 ? 0 : gammaDown;
    
    float gammaSlider = gammaUp - gammaDown;
    if (gammaSlider == 0)
    {
        gammaSlider = 0.01;
    }
    main.rgb = pow(main.rgb, (1.0 / gammaSlider));
    
    // greyscale 
    float grey = dot(main.rgb, float3(0.2126, 0.7152, 0.0722));
    main.rgb = lerp(main.rgb, grey.rrr, saturation);
    
    float3 glowColor = saturate(tex2D(blurYSampler, uv * 0.25 + sampleStep * 0.5) + (tex2D(glowSampler, uv) * 0.5));
    
    glowUp = glowUp == 0 ? 1 : 1.0 + glowUp;
    glowDown = glowDown == 0 ? 0 : glowDown;
    
    float glowSlider = glowUp - glowDown;
    glowColor *= glowSlider;
    
    main.rgb += glowColor;
    return main;
}

float4 ps_final(vs_out i) : COLOR
{
    return tex2D(mixSampler, i.uv);
}

//----------------------------------------------------------------------------------------------------------------//
technique post_test <
    string Script = 
        "RenderColorTarget0=finalView;"
		"RenderDepthStencilTarget=depthBuffer;"
		"ClearSetColor=clearColor;"
		"ClearSetDepth=clearDepth;"
		"Clear=Color;"
		"Clear=Depth;"
		"ScriptExternal=Color;"
        // blur shit
        "RenderColorTarget=blurDownView;"
		"Pass=drawDownBlur;"
        "RenderColorTarget=blurXView;"
		"Pass=drawXBlur;"
        "RenderColorTarget=blurYView;"
		"Pass=drawYBlur;"
         // not sure yet if i really want to do 4 blur passes or just the 2 

        // render mixed view
        "RenderColorTarget=mixView;"
		"Pass=drawMix;"
        
        //final pass
        "RenderColorTarget0=;"
		"RenderDepthStencilTarget=;"
		"ClearSetColor=clearColor;"
		"ClearSetDepth=clearDepth;"
		"Clear=Color;"
		"Clear=Depth;"
		"Pass=drawFinal;"

;>
{

    pass drawDownBlur <string Script = "Draw=Buffer;";>
    {
        AlphaBlendEnable = FALSE;	AlphaTestEnable = FALSE;
        VertexShader = compile vs_3_0 vs_0();
        PixelShader = compile ps_3_0 ps_downscale();
    }
    pass drawXBlur <string Script = "Draw=Buffer;";>
    {
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = FALSE;
        VertexShader = compile vs_3_0 vs_0();
        PixelShader = compile ps_3_0 ps_blurX();
    }
    pass drawYBlur <string Script = "Draw=Buffer;";>
    {
        AlphaBlendEnable = FALSE;
        AlphaTestEnable = FALSE;
        VertexShader = compile vs_3_0 vs_0();
        PixelShader = compile ps_3_0 ps_blurY();
    }

    pass drawMix <string Script = "Draw=Buffer;";>
    {
        ALPHABLENDENABLE = FALSE;
        VertexShader = compile vs_3_0 vs_0();
        PixelShader = compile ps_3_0 ps_mix();
    }

    pass drawFinal <string Script = "Draw=Buffer;";>
    {
        ALPHABLENDENABLE = FALSE;
        VertexShader = compile vs_3_0 vs_0();
        PixelShader = compile ps_3_0 ps_final();
    }
}
