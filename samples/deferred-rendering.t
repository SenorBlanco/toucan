//include "teapot.t"
include "include/transform.t"
include "include/utils.t"

class VertexBuffers {
  var position : float<3>;
  var normal : float<3>;
  var uv : float<2>;
}

class LightData {
  var position : float<4>;
  var color    : float<3>;
  var radius   : float;
}

class Config {
  var numLights : uint;
}

class Uniforms {
  var modelMatrix : float<4,4>;
  var normalModelMatrix : float<4,4>;
}

class Camera {
  var viewProjectionMatrix : float<4,4>;
  var invViewProjectionMatrix : float<4,4>;
}

class GBufferTextureBindings {
  var gBufferNormal : *SampleableTexture2D<float>;
  var gBufferAlbedo : *SampleableTexture2D<float>;
  var gBufferDepth : *SampleableTexture2D<float>;
}

class LightsBufferBindings {
  var lights : *readonly storage Buffer<[]LightData>;
  var config : *uniform Buffer<Config>;
  var camera : *uniform Buffer<Camera>;
}

class TextureQuadPass {
  var fragColor : *ColorAttachment<PreferredSwapChainFormat>;
}

class DeferredRender : TextureQuadPass {
  deviceonly static worldFromScreenCoord(camera : Camera, coord : float<2>, depthSample : float) : float<3> {
    // reconstruct world-space position from the screen coordinate.
    var posClip = float<4>(coord.x * 2.0 - 1.0, (1.0 - coord.y) * 2.0 - 1.0, depthSample, 1.0);
    var posWorldW = camera.invViewProjectionMatrix * posClip;
    var posWorld = float<3>(posWorldW.x, posWorldW.y, posWorldW.z) / posWorldW.w;
    return posWorld;
  }

  vertex main(vb : &VertexBuiltins) {
    var pos : [6]float<2> = { { -1.0, -1.0 }, { 1.0, -1.0 }, { -1.0,  1.0 },
                              { -1.0,  1.0 }, { 1.0, -1.0 }, {  1.0,  1.0 } };
    var pos2 = pos[vb.vertexIndex];
    vb.position = float<4>(pos2.x, pos2.y, 0.0, 1.0);
  }

  fragment main(fb : &FragmentBuiltins) {
    var result : float<3>;
    var gBufferDepth = b0.Get().gBufferDepth;
    var gBufferNormal = b0.Get().gBufferNormal;
    var gBufferAlbedo = b0.Get().gBufferAlbedo;
    var fragCoord = fb.fragCoord;
    var fragCoord2ui = uint<2>((uint) Math.floor(fragCoord.x), (uint) Math.floor(fragCoord.y));

    var depthPixel = gBufferDepth.Load(fragCoord2ui, 0);
    var depth = depthPixel.x;

    // Don't light the sky.
    if (depth >= 1.0) {
      return;
    }

    var bufferSize = gBufferDepth.GetSize();
    var coordUV = float<2>((float) fragCoord.x / (float) bufferSize.x,
                           (float) fragCoord.y / (float) bufferSize.y);
    var camera = b1.Get().camera.Map():;
    var position = this.worldFromScreenCoord(camera, coordUV, depth);
    var normal4 = gBufferNormal.Load(fragCoord2ui, 0);
    var normal = float<3>(normal4.x, normal4.y, normal4.z);
    var albedo4 = gBufferAlbedo.Load(fragCoord2ui, 0);
    var albedo = float<3>(albedo4.x, albedo4.y, albedo4.z);

    var config = b1.Get().config.Map();
    var lights = b1.Get().lights.Map();
    for (var i = 0; i < config.numLights; i++) {
      var lightPos = lights[i].position;
      var L = float<3>(lightPos.x, lightPos.y, lightPos.z) - position;
      var distance = Math.length(L);
      if (distance <= lights[i].radius) {
        var lambert = Math.max(Math.dot(normal, Math.normalize(L)), 0.0);
        result += lambert * Math.pow(1.0 - distance / lights[i].radius, 2.0) * lights[i].color * albedo;
      }
    }

    // some manual ambient
    result += float<3>(0.2);

    fragColor.Set(float<4>(result.x, result.y, result.z, 1.0));
  }

  var b0 : *BindGroup<GBufferTextureBindings>;
  var b1 : *BindGroup<LightsBufferBindings>;
}

class WriteGBuffersVaryings {
  var fragNormal : float<3>;
  var fragUV : float<2>;
}

class WriteGBuffersBindings {
  var uniforms : *uniform Buffer<Uniforms>;
  var camera : *uniform Buffer<Camera>;
}

class WriteGBuffers {
  vertex main(vb : &VertexBuiltins) : WriteGBuffersVaryings {
    var uniforms = bindings.Get().uniforms.Map();
    var camera = bindings.Get().camera.Map();
    var v = vertexes.Get();
    var worldPosition = uniforms.modelMatrix * Utils.makeFloat4(v.position, 1.0);
    vb.position = camera.viewProjectionMatrix * worldPosition;
    var normal4 = float<4>(v.normal.x, v.normal.y, v.normal.z, 1.0);
    var fn4 = uniforms.normalModelMatrix * normal4;
    var fn3 = float<3>(fn4.x, fn4.y, fn4.z);
    var output : WriteGBuffersVaryings;
    output.fragNormal = float<3>{fn4.x, fn4.y, fn4.z};
    output.fragUV = v.uv;
    return output;
  }
  fragment main(fb : &FragmentBuiltins, varyings : WriteGBuffersVaryings) {
    // faking some kind of checkerboard texture
    var uv = Math.floor(30.0 * varyings.fragUV);
    var c = 0.2 + 0.5 * ((uv.x + uv.y) - 2.0 * Math.floor((uv.x + uv.y) / 2.0));

    var n = Math.normalize(varyings.fragNormal);
    normals.Set(float<4>{n.x, n.y, n.z, 1.0});
    albedo.Set(float<4>{c, c, c, 1.0});
  }

  var normals : *ColorAttachment<RGBA16float>;
  var albedo : *ColorAttachment<BGRA8unorm>;
  var bindings : *BindGroup<WriteGBuffersBindings>;
  var vertexes : *VertexInput<VertexBuffers>;
  var indexes : *index Buffer<[]ushort>;
}

class CanvasSizeBindings {
  var size : *uniform Buffer<uint<2>>;
}

class GBuffersDebugView : TextureQuadPass {
  vertex main(vb : &VertexBuiltins) {
   // call vertexTextureQuad
  }
  fragment main(fb : &FragmentBuiltins) {
   // do fragmentGBuffersDebugView
  }
  var bindings : *BindGroup<GBufferTextureBindings>;
  var canvasSizeBindings : *BindGroup<CanvasSizeBindings>;
}

class LightExtent {
  var min : float<3>;
  var max : float<3>;
}

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

    lights[i].position.y = lights[i].position.y - 0.5 - 0.003 * (float(i) - 64.0 * Math.floor(float(i) / 64.0));

    if (lights[i].position.y < lightExtent.min.y) {
      lights[i].position.y = lightExtent.max.y;
    }
  }

  var bindings : *BindGroup<LightUpdateBindings>;
}

var device = new Device();
var window = new Window({0, 0}, {640, 480});


// import { mesh } from '../../meshes/stanfordDragon';

// import lightUpdate from './lightUpdate.wgsl';
// import vertexWriteGBuffers from './vertexWriteGBuffers.wgsl';
// import fragmentWriteGBuffers from './fragmentWriteGBuffers.wgsl';
// import vertexTextureQuad from './vertexTextureQuad.wgsl';
// import fragmentGBuffersDebugView from './fragmentGBuffersDebugView.wgsl';
// import fragmentDeferredRendering from './fragmentDeferredRendering.wgsl';

var kMaxNumLights = 1024;
var lightExtentMin = float<3>{-50.0, -30.0, -50.0};
var lightExtentMax = float<3>{ 50.0, 50.0, 50.0};

var swapChain = new SwapChain<PreferredSwapChainFormat>(device, window);
//const devicePixelRatio = window.devicePixelRatio;
//canvas.width = canvas.clientWidth * devicePixelRatio;
//canvas.height = canvas.clientHeight * devicePixelRatio;
var canvasSize = window.GetSize();
var aspect = (float) canvasSize.x / (float) canvasSize.y;
//const presentationFormat = navigator.gpu.getPreferredCanvasFormat();
//context.configure({
//  device,
//  format: presentationFormat,
//});

// Create the model vertex buffer.
var length = 100; // FIXME: mesh.positions.length
var vertexBuffer = new vertex Buffer<[]VertexBuffers>(device, length);
var verts = [length] new VertexBuffers;
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

// GBuffer texture render targets
var gBufferTexture2DFloat16 = new renderable sampleable Texture2D<RGBA16float>(device, canvasSize);
var gBufferTextureAlbedo = new renderable sampleable Texture2D<BGRA8unorm>(device, canvasSize);
var depthTexture = new renderable sampleable Texture2D<Depth24Plus>(device, canvasSize);

// FIXME: add depth/stencil stuff here
//  depthStencil: {
//    depthWriteEnabled: true,
//    depthCompare: 'less',
//    format: 'depth24plus',
//  },
var writeGBuffersPipeline = new RenderPipeline<WriteGBuffers>(device = device, cullMode = CullMode.Back);

var gBuffersDebugViewPipeline = new RenderPipeline<GBuffersDebugView>(device);

var deferredRenderPipeline = new RenderPipeline<DeferredRender>(device);

var writeGBufferPassDescriptor : WriteGBuffers = {
  normals = gBufferTexture2DFloat16.CreateColorAttachment(clearValue = {0.0, 0.0, 0.0, 1.0}, loadOp = LoadOp.Clear),
  albedo = gBufferTextureAlbedo.CreateColorAttachment(clearValue = {0.0, 0.0, 0.0, 1.0}, loadOp = LoadOp.Clear)
//  depth = depthTexture.CreateColorAttachment(loadOp = LoadOp.Clear),
};

var textureQuadPassDescriptor : TextureQuadPass;

var numLights = 128u;

enum Mode {
  Rendering,
  GBuffersView
};

var configUniformBuffer = new uniform Buffer<Config>(device, {numLights});

var mode = Mode.Rendering;

//const gui = new GUI();
//gui.add(settings, 'mode', ['rendering', 'gBuffers view']);
//gui
//  .add(settings, 'numLights', 1, kMaxNumLights)
//  .step(1)
//  .onChange(() => {
//    device.queue.writeBuffer(
//      configUniformBuffer,
//      0,
//      new Uint32Array([settings.numLights])
//    );
//  });

var modelUniformBuffer = new uniform Buffer<Uniforms>(device);
var cameraUniformBuffer = new uniform Buffer<Camera>(device);

var sceneUniformBindGroup = new BindGroup<WriteGBuffersBindings>(device, {
  modelUniformBuffer,
  cameraUniformBuffer
});

var gBufferTexturesBindGroup = new BindGroup<GBufferTextureBindings>(device, {
  gBufferNormal = gBufferTexture2DFloat16.CreateSampleableView(),
  gBufferAlbedo = gBufferTextureAlbedo.CreateSampleableView(),
  gBufferDepth = depthTexture.CreateSampleableView()
});

// FIXME: put these color attachments elsewhere
//  gBufferNormal = gBufferTexture2DFloat16.CreateColorAttachment(LoadOp.Clear, StoreOp.Store, {0.0, 0.0, 1.0, 1.0}),
//  gBufferAlbedo = gBufferTextureAlbedo.CreateColorAttachment(LoadOp.Clear, StoreOp.Store, { 0.0, 0.0, 0.0, 1.0}),
//  // FIXME: have to cast this to a SampleableTexture2D somehow.
//  gBufferDepth = depthTexture.CreateDepthStencilAttachment(LoadOp.Clear),

// Lights data are uploaded in a storage buffer
// which could be updated/culled/etc. with a compute shader
var extent = lightExtentMax - lightExtentMin;
var lightDataStride = 8;

// We randomaly populate lights randomly in a box range
// And simply move them along y-axis per frame to show they are
// dynamic lightings
var lightsBuffer = new storage Buffer<[]LightData>(device, kMaxNumLights);
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

var lightExtentBuffer = new uniform Buffer<LightExtent>(device, {lightExtentMin, lightExtentMax});

var lightUpdateComputePipeline = new ComputePipeline<LightUpdate>(device);

var lightsBufferBindGroup = new BindGroup<LightsBufferBindings>(device, {
  lightsBuffer,
  configUniformBuffer,
  cameraUniformBuffer
});
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

// Rotates the camera around the origin based on time.
class CameraUtil {
  static getCameraViewProjMatrix(origin : float<3>) : float<4,4> {
    var rad = pi * (float) (System.GetCurrentTime() / 5000.0d);
    var rotation = Transform.translate(origin.x, origin.y, origin.z) * Transform.rotate(float<3>{0.0, 1.0, 0.0}, rad);
    var rotatedEyePosition = rotation * Utils.makeFloat4(eyePosition, 1.0);

    var viewMatrix = Transform.lookAt(Utils.makeFloat3(rotatedEyePosition), origin, upVector);

    return projectionMatrix * viewMatrix;
  }
};

while (System.IsRunning()) {
  var cameraViewProj = CameraUtil.getCameraViewProjMatrix(origin);
  var cameraInvViewProj = Transform.invert(cameraViewProj);
  cameraUniformBuffer.SetData({cameraViewProj, cameraInvViewProj});

  var commandEncoder = new CommandEncoder(device);
  {
  // Write position, normal, albedo etc. data to gBuffers
    var gBufferPass = new RenderPass<WriteGBuffers>(commandEncoder,
      &writeGBufferPassDescriptor
    );
    gBufferPass.SetPipeline(writeGBuffersPipeline);
    gBufferPass.Set({bindings = sceneUniformBindGroup});
    gBufferPass.Set({vertexes = new VertexInput<VertexBuffers>(vertexBuffer)});
    gBufferPass.Set({indexes = indexBuffer});
    gBufferPass.DrawIndexed(indexCount, 1, 0, 0, 0);
    gBufferPass.End();
  }
  {
    // Update lights position
    var lightPass = new ComputePass<LightUpdate>(commandEncoder, {});
    lightPass.SetPipeline(lightUpdateComputePipeline);
    lightPass.Set({bindings = lightsBufferComputeBindGroup});
    // FIXME: Math.ceil
    lightPass.Dispatch(kMaxNumLights / 64, 1, 1);
    lightPass.End();
  }
  if (mode == Mode.GBuffersView) {
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
    debugViewPass.Set({bindings = gBufferTexturesBindGroup});
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
    deferredRenderingPass.Set({b0 = gBufferTexturesBindGroup});
    deferredRenderingPass.Set({b1 = lightsBufferBindGroup});
    deferredRenderingPass.Draw(6, 1, 0, 0);
    deferredRenderingPass.End();
  }
  device.GetQueue().Submit(commandEncoder.Finish());
  while (System.HasPendingEvents()) {
    System.GetNextEvent();
  }
}
