//include "teapot.t"
include "include/transform.t"
include "include/utils.t"

// LightData
class LightData {
  var position : float<4>;
  var color    : float<3>;
  var radius   : float;
}

// Config
class Config {
  var numLights : uint;
}

// LightExtent
class LightExtent {
  var min : float<3>;
  var max : float<3>;
}

// LightUpdateBindings
class LightUpdateBindings {
  var lights : *storage Buffer<[]LightData>;
  var config : *uniform Buffer<Config>;
  var lightExtent : *uniform Buffer<LightExtent>;
}

class LightUpdate {
  compute(64, 1, 1) main(cb : &ComputeBuiltins) {
    var lights = bindings.Get().lights.Map();
    var config = bindings.Get().config.Map();
    var lightExtent = bindings.Get().lightExtent.Map();
    var i = cb.globalInvocationId.x;
    if (i >= config.numLights) {
      return;
    }

    var pos = lights[i].position;

    lights[i].position = {
      pos.x,
      pos.y - 0.5 - 0.003 * ((float)(i) - 64.0 * Math.floor((float)(i) / 64.0)),
      pos.z,
      pos.w
    };
  }

  var bindings : *BindGroup<LightUpdateBindings>;
}

// Uniforms
class Uniforms {
  var modelMatrix : float<4,4>;
  var normalModelMatrix : float<4,4>;
}

// Camera
class Camera {
  var viewProjectionMatrix : float<4,4>;
  var invViewProjectionMatrix : float<4,4>;
}

// VertexOutput
class VertexOutput {
  var fragNormal : float<3>;
  var fragUV : float<2>;
}

// WriteGBuffersBindings
class WriteGBuffersBindings {
  var uniforms : *uniform Buffer<Uniforms>;
  var camera : *uniform Buffer<Camera>;
}

// Vertex
class Vertex {
  var position : float<3>;
  var normal : float<3>;
  var uv : float<2>;
}

class WriteGBuffers {
  // WriteGBuffers vertex shader
  vertex main(vb : &VertexBuiltins) : VertexOutput {
    var uniforms = bindings.Get().uniforms.Map();
    var camera = bindings.Get().camera.Map();
    var v = vertexes.Get();

    // Transform the vertex position by the model and viewProjection matrices.
    // Transform the vertex normal by the normalModelMatrix (inverse transpose of the model).
    var output : VertexOutput;
    var worldPosition = Utils.makeFloat3(uniforms.modelMatrix * Utils.makeFloat4(v.position));
    vb.position = camera.viewProjectionMatrix * Utils.makeFloat4(worldPosition);
    output.fragNormal = Utils.makeFloat3(uniforms.normalModelMatrix * Utils.makeFloat4(v.normal));
    output.fragUV = v.uv;
    return output;
  }

  fragment main(fb : &FragmentBuiltins, varyings : VertexOutput) {
    // WriteGBuffers fragment shader

    var uv = Math.floor(30.0 * varyings.fragUV);
    var c = 0.2 + 0.5 * ((uv.x + uv.y) - 2.0 * Math.floor((uv.x + uv.y) / 2.0));

    normals.Set(Utils.makeFloat4(Math.normalize(varyings.fragNormal)));
    albedo.Set(float<4>(c, c, c, 1.0));
  }

  var normals : *ColorAttachment<RGBA16float>;
  var albedo : *ColorAttachment<BGRA8unorm>;
  var depth : *DepthStencilAttachment<Depth24Plus>;
  var bindings : *BindGroup<WriteGBuffersBindings>;
  var vertexes : *VertexInput<Vertex>;
  var indexes : *index Buffer<[]ushort>;
}

class TextureQuadPass {
  vertex main(vb : &VertexBuiltins) {
    // TextureQuadPass vertex shader
    var pos : [6]float<2> = {
      { -1.0, -1.0 }, { 1.0, -1.0 }, { -1.0,  1.0 },
      { -1.0,  1.0 }, { 1.0, -1.0 }, {  1.0,  1.0 } };
    vb.position = Utils.makeFloat4(pos[vb.vertexIndex]);
  }

  var fragColor : *ColorAttachment<PreferredSwapChainFormat>;
}

// GBufferTextureBindings
class GBufferTextureBindings {
  var gBufferNormal : *SampleableTexture2D<float>;
  var gBufferAlbedo : *SampleableTexture2D<float>;
  var gBufferDepth : *SampleableTexture2D<unfilterable float>;
}

// WindowSizeBindings
class WindowSizeBindings {
  var size : *uniform Buffer<uint<2>>;
}

class GBuffersDebugView : TextureQuadPass {
  fragment main(fb : &FragmentBuiltins) {
    var gBufferDepth = textureBindings.Get().gBufferDepth;
    var gBufferNormal = textureBindings.Get().gBufferNormal;
    var gBufferAlbedo = textureBindings.Get().gBufferAlbedo;
    var result : float<4>;
    var windowSize = windowSizeBindings.Get().size.Map():;
    var c = Utils.makeFloat2(fb.fragCoord) / (float<2>) windowSize;
    if (c.x < 0.33333) {
      var rawDepth2 = gBufferDepth.Load((uint<2>) Math.floor(Utils.makeFloat2(fb.fragCoord)), 0);
      var rawDepth = rawDepth2.x;
      // remap depth into something a bit more visible
      var depth = (1.0 - rawDepth) * 50.0;
      result = float<4>(depth);
    } else if (c.x < 0.66667) {
      result = gBufferNormal.Load((uint<2>) Math.floor(Utils.makeFloat2(fb.fragCoord)), 0);
      result = (result + float<4>(1.0, 1.0, 1.0, 0.0)) * float<4>(0.5, 0.5, 0.5, 1.0);
    } else {
      result = gBufferAlbedo.Load((uint<2>) Math.floor(Utils.makeFloat2(fb.fragCoord)), 0);
    }
    fragColor.Set(result);
  }

  var textureBindings : *BindGroup<GBufferTextureBindings>;
  var windowSizeBindings : *BindGroup<WindowSizeBindings>;
  var fragColor : *ColorAttachment<PreferredSwapChainFormat>;
}

// DeferredRenderBufferBindings
class DeferredRenderBufferBindings {
  var lights : *readonly storage Buffer<[]LightData>;
  var config : *uniform Buffer<Config>;
  var camera : *uniform Buffer<Camera>;
}

class DeferredRender : TextureQuadPass {
  // worldFromScreenCoord
  deviceonly static worldFromScreenCoord(camera : Camera, coord : float<2>, depthSample : float) : float<3> {
    // reconstruct world-space position from the screen coordinate.
    var posClip = float<4>(coord.x * 2.0 - 1.0, (1.0 - coord.y) * 2.0 - 1.0, depthSample, 1.0);
    var posWorldW = camera.invViewProjectionMatrix * posClip;
    var posWorld = Utils.makeFloat3(posWorldW) / posWorldW.w;
    return posWorld;
  }

  // DeferredRender fragment shader
  fragment main(fb : &FragmentBuiltins) {
    var buffers = bufferBindings.Get();
    var config = buffers.config.Map();
    var lights = buffers.lights.Map();
    var camera = buffers.camera.Map():;
    var textures = textureBindings.Get();
    var result : float<3>;
    var coord2 = (uint<2>) Math.floor(Utils.makeFloat2(fb.fragCoord));
    var depthPixel = textures.gBufferDepth.Load(coord2, 0);
    var depth = depthPixel.x;

    // Don't light the sky.
    if (depth >= 1.0) {
      return;
    }

    var bufferSize = textures.gBufferDepth.GetSize();
    var coordUV = Utils.makeFloat2(fb.fragCoord) / (float<2>) bufferSize;
    var position = this.worldFromScreenCoord(camera, coordUV, depth);
    var normal = Utils.makeFloat3(textures.gBufferNormal.Load(coord2, 0));
    var albedo = Utils.makeFloat3(textures.gBufferAlbedo.Load(coord2, 0));

    for (var i = 0; i < config.numLights; i++) {
      var L = Utils.makeFloat3(lights[i].position) - position;
      var distance = Math.length(L);
      if (distance <= lights[i].radius) {
        var lambert = Math.max(Math.dot(normal, Math.normalize(L)), 0.0);
        result += lambert * Math.pow(1.0 - distance / lights[i].radius, 2.0) * lights[i].color * albedo;
      }
    }

    // some manual ambient
    result += float<3>(0.2);

    fragColor.Set(Utils.makeFloat4(result));
  }

  var textureBindings : *BindGroup<GBufferTextureBindings>;
  var bufferBindings : *BindGroup<DeferredRenderBufferBindings>;
}

// Host code

var kMaxNumLights = 1024;
var lightExtentMin = float<3>{-50.0, -30.0, -50.0};
var lightExtentMax = float<3>{ 50.0, 50.0, 50.0};

var device = new Device();
var window = new Window({0, 0}, {640, 480});

var swapChain = new SwapChain<PreferredSwapChainFormat>(device, window);
var windowSize = window.GetSize();
var aspect = (float) windowSize.x / (float) windowSize.y;

// Create the model vertex buffer.
var length = 100; // FIXME: mesh.positions.length
var vertexBuffer = new vertex Buffer<[]Vertex>(device, length);
var verts = [length] new Vertex;
{
  for (var i = 0; i < verts.length; ++i) {
    var v = verts[i];
//    v.position = mesh.positions[i];
//    v.normal = mesh.normals[i];
//    v.uvs = mesh.uvs[i];
  }
}
vertexBuffer.SetData(verts);

// Create the model index buffer.
var meshTriangleCount = 100; // FIXME: mesh.triangles.length
var indexCount = meshTriangleCount * 3;
var indexBuffer = new index Buffer<[]ushort>(device, indexCount);
var indices = [indexCount] new ushort;
{
  for (var i = 0; i < 100; ++i) {
//    indices[i] = mesh.triangles[i];
  }
}
indexBuffer.SetData(indices);

// Create normals texture
var gBufferTexture2DFloat16 = new renderable sampleable Texture2D<RGBA16float>(device, windowSize);

// Create albedo texture
var gBufferTextureAlbedo = new renderable sampleable Texture2D<BGRA8unorm>(device, windowSize);

// Create depth texture
var depthTexture = new renderable sampleable Texture2D<Depth24Plus>(device, windowSize);

// FIXME: add depth/stencil stuff here
//  depthStencil: {
//    depthWriteEnabled: true,
//    depthCompare: 'less',
//    format: 'depth24plus',
//  },

// Create WriteGBuffers RenderPipeline
var writeGBuffersPipeline = new RenderPipeline<WriteGBuffers>(device = device, cullMode = CullMode.Back);

// Create GBuffersDebugView RenderPipeline
var gBuffersDebugViewPipeline = new RenderPipeline<GBuffersDebugView>(device);

// Create DeferredRender RenderPipeline
var deferredRenderPipeline = new RenderPipeline<DeferredRender>(device);

// Create ColorAttachments for GBuffer textures
var writeGBufferPassDescriptor : WriteGBuffers;
writeGBufferPassDescriptor.normals = gBufferTexture2DFloat16.CreateColorAttachment(clearValue = {0.0, 0.0, 0.0, 1.0}, loadOp = LoadOp.Clear);
writeGBufferPassDescriptor.albedo = gBufferTextureAlbedo.CreateColorAttachment(clearValue = {0.0, 0.0, 0.0, 1.0}, loadOp = LoadOp.Clear);
writeGBufferPassDescriptor.depth = depthTexture.CreateDepthStencilAttachment(depthLoadOp = LoadOp.Clear, depthClearValue = 1.0);

enum Mode {
  Rendering,
  GBuffersView
}

// Settings
class Settings {
  var mode = Mode.Rendering;
  var numLights = 128;
}

var settings : Settings;

// Create Config uniform buffer
var configUniformBuffer = new uniform Buffer<Config>(device, {settings.numLights});

// Create Uniforms uniform buffer
var modelUniformBuffer = new uniform Buffer<Uniforms>(device);

// Create Camera uniform buffer
var cameraUniformBuffer = new uniform Buffer<Camera>(device);

// Create WriteGBuffersBindings BindGroup
var sceneUniformBindGroup = new BindGroup<WriteGBuffersBindings>(device, {
  uniforms = modelUniformBuffer,
  camera = cameraUniformBuffer
});

// Create GBufferTextureBindings BindGroup
var gBufferTexturesBindGroup = new BindGroup<GBufferTextureBindings>(device, {
  gBufferNormal = gBufferTexture2DFloat16.CreateSampleableView(),
  gBufferAlbedo = gBufferTextureAlbedo.CreateSampleableView(),
  gBufferDepth = depthTexture.CreateSampleableView()
});

// Lights data are uploaded in a storage buffer
// which could be updated/culled/etc. with a compute shader
var extent = lightExtentMax - lightExtentMin;

// Create storage buffer for lights
var lightsBuffer = new storage Buffer<[]LightData>(device, kMaxNumLights);

// We randomaly populate lights randomly in a box range
// And simply move them along y-axis per frame to show they are
// dynamic lightings
var lightData = [kMaxNumLights] new LightData;
for (var j = 0; j < kMaxNumLights; j++) {
  var light = lightData[j];  // FIXME: do we need &LightData here?
  // position
  for (var i = 0; i < 3; i++) {
    light.position[i] = Math.rand() * extent[i] + lightExtentMin[i];
  }
  light.position[4] = 1.0;
  // color
  light.color = {
    Math.rand() * 2.0,
    Math.rand() * 2.0,
    Math.rand() * 2.0
  };
  // radius
  light.radius = 20.0;
}
lightsBuffer.SetData(lightData);

// Create LightExtent uniform buffer
var lightExtentBuffer = new uniform Buffer<LightExtent>(device, {lightExtentMin, lightExtentMax});

// Create LightUpdate ComputePipeline
var lightUpdateComputePipeline = new ComputePipeline<LightUpdate>(device);

// Create DeferredRenderBufferBindings BindGroup
var lightsBufferBindGroup = new BindGroup<DeferredRenderBufferBindings>(device, {
  lightsBuffer,
  configUniformBuffer,
  cameraUniformBuffer
});

// Create LightUpdateBindings BindGroup
var lightsBufferComputeBindGroup = new BindGroup<LightUpdateBindings>(device, {
  lightsBuffer,
  configUniformBuffer,
  lightExtentBuffer
});

// Scene matrices
var eyePosition = float<3>(0.0, 50.0, -100.0);
var upVector = float<3>(0.0, 1.0, 0.0);
var origin = float<3>(0.0, 0.0, 0.0);

var pi = 3.141592653589;
var projectionMatrix = Transform.perspective((2.0 * pi) / 5.0, aspect, 1.0, 2000.0);

// Move the model so it's centered.
var modelMatrix = Transform.translate(0.0, -45.0, 0.0);
var invertTransposeModelMatrix = Math.transpose(Transform.invert(modelMatrix));
var normalModelData = invertTransposeModelMatrix;
modelUniformBuffer.SetData({modelMatrix, invertTransposeModelMatrix});

while (System.IsRunning()) {
  // Rotates the camera around the origin based on time.
  var rad = pi * (float) (System.GetCurrentTime() / 5000.0d);
  var rotation = Transform.translate(origin.x, origin.y, origin.z) * Transform.rotate(float<3>{0.0, 1.0, 0.0}, rad);
  var rotatedEyePosition = rotation * Utils.makeFloat4(eyePosition);

  var viewMatrix = Transform.lookAt(Utils.makeFloat3(rotatedEyePosition), origin, upVector);

  // Update camera matrices
  var camera : Camera;
  camera.viewProjectionMatrix = projectionMatrix * viewMatrix;
  camera.invViewProjectionMatrix = Transform.invert(camera.viewProjectionMatrix);
  cameraUniformBuffer.SetData(&camera);

  var commandEncoder = new CommandEncoder(device);
  {
  // Write position, normal, albedo etc. data to gBuffers
    var gBufferPass = new RenderPass<WriteGBuffers>(commandEncoder,
      &writeGBufferPassDescriptor
    );
    gBufferPass.SetPipeline(writeGBuffersPipeline);
    gBufferPass.Set({bindings = sceneUniformBindGroup});
    gBufferPass.Set({vertexes = new VertexInput<Vertex>(vertexBuffer)});
    gBufferPass.Set({indexes = indexBuffer});
    gBufferPass.DrawIndexed(indexCount, 1, 0, 0, 0);
    gBufferPass.End();
  }
  {
    // Update lights position
    var lightPass = new ComputePass<LightUpdate>(commandEncoder, {});
    lightPass.SetPipeline(lightUpdateComputePipeline);
    lightPass.Set({bindings = lightsBufferComputeBindGroup});
    lightPass.Dispatch((kMaxNumLights + 63) / 64, 1, 1);
    lightPass.End();
  }
  if (settings.mode == Mode.GBuffersView) {
    // GBuffers debug view
    // Left: depth
    // Middle: normal
    // Right: albedo (use uv to mimic a checkerboard texture)
    var fb = swapChain
      .GetCurrentTexture()
      .CreateColorAttachment(LoadOp.Clear, StoreOp.Store, {0.0, 0.0, 1.0, 1.0});
    var debugViewPass = new RenderPass<GBuffersDebugView>(commandEncoder,
      { fragColor = fb }
    );
    debugViewPass.SetPipeline(gBuffersDebugViewPipeline);
    debugViewPass.Set({textureBindings = gBufferTexturesBindGroup});
    debugViewPass.Draw(6, 1, 0, 0);
    debugViewPass.End();
  } else {
    // Deferred rendering
    var fb = swapChain
      .GetCurrentTexture()
      .CreateColorAttachment(LoadOp.Clear, StoreOp.Store, {0.0, 0.0, 1.0, 1.0});
    var deferredRenderingPass = new RenderPass<DeferredRender>(commandEncoder,
      { fragColor = fb }
    );
    deferredRenderingPass.SetPipeline(deferredRenderPipeline);
    deferredRenderingPass.Set({textureBindings = gBufferTexturesBindGroup});
    deferredRenderingPass.Set({bufferBindings = lightsBufferBindGroup});
    deferredRenderingPass.Draw(6, 1, 0, 0);
    deferredRenderingPass.End();
  }
  device.GetQueue().Submit(commandEncoder.Finish());
  swapChain.Present();
  while (System.HasPendingEvents()) {
    System.GetNextEvent();
  }
}
