/**
 * @file RippleMetaView.m
 *
 * @brief Provides a view that can apply a Metal ripple effect to images
 *
 * @author Created by Geoff G. on 05/25/2025
 *
 */
#import "RippleMetalView.h"
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

@interface RippleMetalView () <MTKViewDelegate>

@property (nonatomic, strong) id<MTLDevice> metalDevice;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;

@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;
@property (nonatomic, strong) id<MTLTexture> texture;

@property (nonatomic) float time;

@end

@implementation RippleMetalView
{
    NSImage *_originalImage;
    BOOL _rippleEnabled;
    id<MTLRenderPipelineState> _originalPipelineState;
}

// Quad vertices (x, y, z, w) in clip space for a fullscreen quad
static const float quadVertices[] = {
    -1.0, -1.0, 0, 1,
     1.0, -1.0, 0, 1,
    -1.0,  1.0, 0, 1,
     1.0,  1.0, 0, 1,
};

- (instancetype)initWithFrame:(NSRect)frameRect image:(NSImage *)image {
    
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    self = [super initWithFrame:frameRect device:device];
    if (self) {

        _originalImage = image;
        _rippleEnabled = NO;
        _metalDevice = device;
        _originalPipelineState = nil;
        self.delegate = self;
        self.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
        self.paused = NO;
        self.preferredFramesPerSecond = 60;

        _commandQueue = [_metalDevice newCommandQueue];
        
        [self loadShaders];
        [self createVertexBuffer];
        [self loadTextureFromImage:image];
        
        _time = 0;
    }
    return self;
}

- (void)loadShaders {
    id<MTLLibrary> library = [_metalDevice newDefaultLibrary];
    id<MTLFunction> vertexFunction = [library newFunctionWithName:@"vertex_main"];
    id<MTLFunction> rippleFragmentFunction = [library newFunctionWithName:@"ripple_fragment"];
    id<MTLFunction> originalFragmentFunction = [library newFunctionWithName:@"original_fragment"];

    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.vertexFunction = vertexFunction;
    pipelineDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat;

    NSError *error = nil;

    // Pipeline with ripple
    pipelineDescriptor.fragmentFunction = rippleFragmentFunction;
    _pipelineState = [_metalDevice newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    if (!_pipelineState) NSLog(@"Ripple pipeline error: %@", error);

    // Pipeline without ripple
    pipelineDescriptor.fragmentFunction = originalFragmentFunction;
    _originalPipelineState = [_metalDevice newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
    if (!_originalPipelineState) NSLog(@"Original pipeline error: %@", error);
}

- (void)createVertexBuffer {
    _vertexBuffer = [_metalDevice newBufferWithBytes:quadVertices
                                              length:sizeof(quadVertices)
                                             options:MTLResourceStorageModeShared];
}

- (void)loadTextureFromImage:(NSImage *)image {
    if (!image) return;
    CGImageRef cgImage = [image CGImageForProposedRect:NULL context:nil hints:nil];
    if (!cgImage) return;
    
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    
    MTLTextureDescriptor *texDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                                        width:width
                                                                                       height:height
                                                                                    mipmapped:NO];
    _texture = [_metalDevice newTextureWithDescriptor:texDesc];
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger imageByteCount = bytesPerRow * height;
    void *imageData = malloc(imageByteCount);
    if (!imageData) {
        NSLog(@"Failed to allocate memory for image data");
        return;
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(imageData,
                                                 width,
                                                 height,
                                                 8,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    
    if (!context) {
        free(imageData);
        NSLog(@"Failed to create CGContext");
        return;
    }
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
    CGContextRelease(context);
    
    MTLRegion region = { {0, 0, 0}, {width, height, 1} };
    [_texture replaceRegion:region mipmapLevel:0 withBytes:imageData bytesPerRow:bytesPerRow];
    
    free(imageData);
}

#pragma mark - MTKViewDelegate

- (void)drawInMTKView:(MTKView *)view {
    id<CAMetalDrawable> drawable = view.currentDrawable;
    if (!drawable) return;
    
    MTLRenderPassDescriptor *renderPassDesc = view.currentRenderPassDescriptor;
    if (!renderPassDesc) return;
    
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDesc];
    
    if (_rippleEnabled) {
        [encoder setRenderPipelineState:_pipelineState];
        [encoder setFragmentBytes:&_time length:sizeof(_time) atIndex:0];
    } else {
        [encoder setRenderPipelineState:_originalPipelineState];
    }
    [encoder setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
    [encoder setFragmentTexture:_texture atIndex:0];
    
    // Pass the current time to the fragment shader for animation
    [encoder setFragmentBytes:&_time length:sizeof(_time) atIndex:0];
    
    // Create and set a sampler state
    MTLSamplerDescriptor *samplerDesc = [MTLSamplerDescriptor new];
    samplerDesc.minFilter = MTLSamplerMinMagFilterLinear;
    samplerDesc.magFilter = MTLSamplerMinMagFilterLinear;
    id<MTLSamplerState> sampler = [_metalDevice newSamplerStateWithDescriptor:samplerDesc];
    [encoder setFragmentSamplerState:sampler atIndex:0];
    
    [encoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [encoder endEncoding];
    
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
    
    // Increment time for animation
    _time += 1.0 / self.preferredFramesPerSecond;
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
    // Handle resize if needed
}

- (void)stopRipple {
    _rippleEnabled = NO;
}

- (void)startRipple {
    _rippleEnabled = YES;
}

- (void)toggleRipple:(BOOL)bEnabled {
    _rippleEnabled = bEnabled;
}

@end
