/**
 * @file RippleShader.h
 *
 * @brief A Metal shader for ripple effects
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */
#include <metal_stdlib>
using namespace metal;

struct RasterizerData {
    float4 position [[position]];
    float2 texCoord;
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex RasterizerData vertex_main(const device float4 *vertexArray [[buffer(0)]],
                                  uint vertexID [[vertex_id]]) {
    RasterizerData out;
    out.position = vertexArray[vertexID];
    
    // Convert clip-space to texture-space coordinates (0-1)
    out.texCoord = float2((vertexArray[vertexID].x + 1.0) * 0.5,
                          1.0 - (vertexArray[vertexID].y + 1.0) * 0.5);
    return out;
}

fragment float4 ripple_fragment(VertexOut in [[stage_in]],
                                texture2d<float> texture [[texture(0)]],
                                constant float &time [[buffer(0)]],
                                sampler s [[sampler(0)]]) {
    float2 uv = in.texCoord;

    float2 center = float2(0.5, 0.5);
    float dist = distance(uv, center);

    // Ripple effect: sine wave based on distance and time
    float ripple = 0.02 * sin(30.0 * dist - time * 6.0);

    // Offset UV by ripple amount radially from center
    float2 rippleUV = uv + normalize(uv - center) * ripple;

    // Clamp UVs to avoid sampling outside texture
    rippleUV = clamp(rippleUV, float2(0.0), float2(1.0));

    float4 color = texture.sample(s, rippleUV);
    return color;
}

fragment float4 original_fragment(RasterizerData in [[stage_in]],
                                  texture2d<float> tex [[ texture(0) ]],
                                  sampler s [[ sampler(0) ]]) {
    return tex.sample(s, in.texCoord);
}


