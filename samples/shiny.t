include "cube.t"
include "cubic.t"
include "event-handler.t"
include "quaternion.t"
include "transform.t"
include "teapot.t"
include "utils.t"

class Vertex {
  float<3> position;
  float<3> normal;
}

using Format = RGBA8unorm;

class CubeLoader {
  static void Load(Device* device, ubyte[]^ data, TextureCube<Format>^ texture, uint face) {
    auto image = new ImageDecoder<Format>(data);
    auto size = image.GetSize();
    auto buffer = new Buffer<Format::MemoryType[]>(device, texture.MinBufferWidth() * size.y);
    writeonly Format::MemoryType[]^ b = buffer.MapWrite();
    image.Decode(b, texture.MinBufferWidth());
    buffer.Unmap();
    auto encoder = new CommandEncoder(device);
    texture.CopyFromBuffer(encoder, buffer, {size.x, size.y, 1}, uint<3>(0, 0, face));
    device.GetQueue().Submit(encoder.Finish());
  }
}

Device* device = new Device();

auto texture = new sampleable TextureCube<RGBA8unorm>(device, {2176, 2176});
CubeLoader.Load(device, inline("third_party/home-cube/right.jpg"), texture, 0);
CubeLoader.Load(device, inline("third_party/home-cube/left.jpg"), texture, 1);
CubeLoader.Load(device, inline("third_party/home-cube/top.jpg"), texture, 2);
CubeLoader.Load(device, inline("third_party/home-cube/bottom.jpg"), texture, 3);
CubeLoader.Load(device, inline("third_party/home-cube/front.jpg"), texture, 4);
CubeLoader.Load(device, inline("third_party/home-cube/back.jpg"), texture, 5);

Window* window = new Window({0, 0}, System.GetScreenSize());
auto swapChain = new SwapChain<PreferredSwapChainFormat>(device, window);

class BicubicPatch {
  Vertex Evaluate(float u, float v) {
    float<3>[4] pu, pv;
    for (int i = 0; i < 4; ++i) {
      pu[i] = vCubics[i].Evaluate(v);
      pv[i] = uCubics[i].Evaluate(u);
    }
    Cubic<float<3>> uCubic, vCubic;
    uCubic.FromBezier(pu);
    vCubic.FromBezier(pv);
    Vertex result;
    result.position = uCubic.Evaluate(u);
    auto uTangent = uCubic.EvaluateTangent(u);
    auto vTangent = vCubic.EvaluateTangent(v);
    if (vTangent.x == 0.0 && vTangent.y == 0.0 && vTangent.z == 0.0) {
      if (result.position.z <= 0.0) {
        result.normal = { 0.0, 0.0, -1.0 };
      } else {
        result.normal = { 0.0, 0.0, 1.0 };
      }
    } else {
      result.normal = Utils.normalize(Utils.cross(vTangent, uTangent));
    }
    return result;
  }
  Cubic<float<3>>[4] uCubics, vCubics;
}

uint level = 32;
uint patchWidth = level + 1;
uint numPatches = teapotControlIndices.length / 16;
auto teapotIndices = new uint[numPatches * level * level * 6];

int vi = 0, ii = 0;
for (int k = 0; k < numPatches; ++k) {
  for (int i = 0; i < level; ++i) {
    for (int j = 0; j < level; ++j) {
      teapotIndices[ii++] = vi;
      teapotIndices[ii++] = vi + 1;
      teapotIndices[ii++] = vi + patchWidth + 1;
      teapotIndices[ii++] = vi;
      teapotIndices[ii++] = vi + patchWidth + 1;
      teapotIndices[ii++] = vi + patchWidth;
      ++vi;
    }
    ++vi;           // skip the last column
  }
  vi += patchWidth; // skip the last row
}

class Uniforms {
  float<4,4>  model, view, projection;
//  float<4,4>  viewInverse;
}

class Bindings {
  Sampler* sampler;
  SampleableTextureCube<float>* textureView;
  uniform Buffer<Uniforms>* uniforms;
}

class DrawPipeline {
  index Buffer<uint[]>* indexBuffer;
  ColorAttachment<PreferredSwapChainFormat>* fragColor;
  DepthStencilAttachment<Depth24Plus>* depth;
  BindGroup<Bindings>* bindings;
}

class ComputeUniforms {
  uint  patchWidth;
  float scale;
}

class ComputeBindings {
  storage Buffer<float<3>[]>* controlPoints;
  storage Buffer<uint[]>* controlIndices;
  storage Buffer<Vertex[]>* vertices;
  uniform Buffer<ComputeUniforms>* uniforms;
}

class BicubicComputePipeline {
  void computeShader(ComputeBuiltins cb) compute(8, 8, 1) {
    auto controlPoints = bindings.Get().controlPoints.MapReadWriteStorage();
    auto controlIndices = bindings.Get().controlIndices.MapReadWriteStorage();
    auto vertices = bindings.Get().vertices.MapReadWriteStorage();
    auto uniforms = bindings.Get().uniforms.MapReadUniform();
    float u = (float) cb.globalInvocationId.x * uniforms.scale;
    float v = (float) cb.globalInvocationId.y * uniforms.scale;
    if (u > 1.0 || v > 1.0) {
      return;
    }
    uint k = cb.globalInvocationId.z * 16u;
    BicubicPatch patch;
    for (int i = 0; i < 4; ++i) {
      float<3>[4] pu, pv;
      for (int j = 0; j < 4; ++j) {
        pu[j] = controlPoints[controlIndices[k + i + j * 4]];
        pv[j] = controlPoints[controlIndices[k + i * 4 + j]];
      }
      patch.uCubics[i].FromBezier(pu);
      patch.vCubics[i].FromBezier(pv);
    }
    uint id = cb.globalInvocationId.z * uniforms.patchWidth * uniforms.patchWidth + cb.globalInvocationId.y * uniforms.patchWidth + cb.globalInvocationId.x;
    vertices[id] = patch.Evaluate(u, v);
  }
  BindGroup<ComputeBindings>* bindings;
}

class SkyboxPipeline : DrawPipeline {
    float<3> vertexShader(VertexBuiltins vb) vertex {
        auto v = position.Get();
        auto uniforms = bindings.Get().uniforms.MapReadUniform();
        auto pos = float<4>(v.x, v.y, v.z, 1.0);
        vb.position = uniforms.projection * uniforms.view * uniforms.model * pos;
        return v;
    }
    void fragmentShader(FragmentBuiltins fb, float<3> position) fragment {
      float<3> p = Math.normalize(position);
      auto b = bindings.Get();
      // TODO: figure out why the skybox is X-flipped
      fragColor.Set(b.textureView.Sample(b.sampler, float<3>(-p.x, p.y, p.z)));
    }
    vertex Buffer<float<3>[]>* position;
};

class ReflectionPipeline : DrawPipeline {
    Vertex vertexShader(VertexBuiltins vb) vertex {
        auto v = vert.Get();
        auto n = Math.normalize(v.normal);
        auto uniforms = bindings.Get().uniforms.MapReadUniform();
        auto viewModel = uniforms.view * uniforms.model;
        auto pos = viewModel * float<4>(v.position.x, v.position.y, v.position.z, 1.0);
        auto normal = viewModel * float<4>(n.x, n.y, n.z, 0.0);
        vb.position = uniforms.projection * pos;
        Vertex varyings;
        varyings.position = float<3>(pos.x, pos.y, pos.z);
        varyings.normal = float<3>(normal.x, normal.y, normal.z);
        return varyings;
    }
    void fragmentShader(FragmentBuiltins fb, Vertex varyings) fragment {
      auto b = bindings.Get();
      auto uniforms = b.uniforms.MapReadUniform();
      float<3> p = Math.normalize(varyings.position);
      float<3> n = Math.normalize(varyings.normal);
      float<3> r = Math.reflect(p, n);
      auto r4 = Math.inverse(uniforms.view) * float<4>(r.x, r.y, r.z, 0.0);
      fragColor.Set(b.textureView.Sample(b.sampler, float<3>(-r4.x, r4.y, r4.z)));
    }
    vertex Buffer<Vertex[]>* vert;
};

auto tessPipeline = new ComputePipeline<BicubicComputePipeline>(device);

auto depthState = new DepthStencilState<Depth24Plus>();

auto cubePipeline = new RenderPipeline<SkyboxPipeline>(device, depthState, TriangleList);
Bindings cubeBindings;
cubeBindings.uniforms = new uniform Buffer<Uniforms>(device);
cubeBindings.sampler = new Sampler(device, ClampToEdge, ClampToEdge, ClampToEdge, Linear, Linear, Linear);
cubeBindings.textureView = texture.CreateSampleableView();

SkyboxPipeline cubeData;
cubeData.position = new vertex Buffer<float<3>[]>(device, &cubeVerts);
cubeData.indexBuffer = new index Buffer<uint[]>(device, &cubeIndices);
cubeData.bindings = new BindGroup<Bindings>(device, &cubeBindings);

auto teapotPipeline = new RenderPipeline<ReflectionPipeline>(device, depthState, TriangleList);
Bindings teapotBindings;
teapotBindings.sampler = cubeBindings.sampler;
teapotBindings.textureView = cubeBindings.textureView;
teapotBindings.uniforms = new uniform Buffer<Uniforms>(device);
uint numVerticesPerPatch = patchWidth * patchWidth;

auto teapotVertices = new vertex storage Buffer<Vertex[]>(device, numPatches * numVerticesPerPatch);

auto tcp = new storage Buffer<float<3>[]>(device, &teapotControlPoints);
auto computeBindings = new BindGroup<ComputeBindings>(device, {
  controlPoints = tcp,
  controlIndices = new storage Buffer<uint[]>(device, &teapotControlIndices),
  vertices = teapotVertices,
  uniforms = new uniform Buffer<ComputeUniforms>(device, { patchWidth = patchWidth, scale = 1.0 / (float) level } )
});

ReflectionPipeline teapotData;
teapotData.vert = teapotVertices;
teapotData.indexBuffer = new index Buffer<uint[]>(device, teapotIndices);
teapotData.bindings = new BindGroup<Bindings>(device, &teapotBindings);

EventHandler handler;
handler.rotation = float<2>(0.0, 0.0);
handler.distance = 10.0;
auto teapotQuat = Quaternion(float<3>(1.0, 0.0, 0.0), -3.1415926 / 2.0);
teapotQuat.normalize();
auto teapotRotation = teapotQuat.toMatrix();
auto depthBuffer = new renderable Texture2D<Depth24Plus>(device, window.GetSize());
Uniforms uniforms;
auto prevWindowSize = uint<2>{0, 0};
double startTime = System.GetCurrentTime();
Cubic<float> animCurve;
animCurve.FromBezier({0.5, 0.5, 1.5, 1.5});
float duration = 2.0;
float animScale = 2.0 / duration;
auto animTeapotControlPoints = new float<3>[teapotControlPoints.length];
while (System.IsRunning()) {
  float animTime = (float) ((System.GetCurrentTime() - startTime) % duration);
  float t;
  if (animTime < duration * 0.5) {
    t = animCurve.Evaluate(animTime * animScale);
  } else {
    t = animCurve.Evaluate((duration - animTime) * animScale);
  }

  for (int i = 0; i < teapotControlPoints.length; ++i) {
    animTeapotControlPoints[i] = teapotControlPoints[i];
  }

  int[16] pointsToAnimate = { 49, 50, 52, 53, 60, 61, 63, 64, 69, 70, 72, 73, 78, 79, 80, 81 };
  for (int i = 0; i < pointsToAnimate.length; ++i) {
    animTeapotControlPoints[pointsToAnimate[i]] *= t;
  }

  tcp.SetData(animTeapotControlPoints);
  Quaternion orientation = Quaternion(float<3>(0.0, 1.0, 0.0), handler.rotation.x);
  orientation = orientation.mul(Quaternion(float<3>(1.0, 0.0, 0.0), handler.rotation.y));
  orientation.normalize();
  auto newSize = window.GetSize();
  // FIXME: relationals should work on vectors
  if (newSize.x != prevWindowSize.x || newSize.y != prevWindowSize.y) {
    swapChain.Resize(newSize);
    depthBuffer = new renderable Texture2D<Depth24Plus>(device, newSize);
    float aspectRatio = (float) newSize.x / (float) newSize.y;
    uniforms.projection = Transform.projection(0.5, 200.0, -aspectRatio, aspectRatio, -1.0, 1.0);
    prevWindowSize = newSize;
  }
  uniforms.view = Transform.translate(0.0, 0.0, -handler.distance);
  uniforms.view *= orientation.toMatrix();
  uniforms.model = Transform.scale(100.0, 100.0, 100.0);
//  uniforms.viewInverse = Transform.invert(uniforms.view);
  cubeBindings.uniforms.SetData(&uniforms);
  uniforms.model = teapotRotation * Transform.scale(2.0, 2.0, 2.0);
  teapotBindings.uniforms.SetData(&uniforms);
  auto encoder = new CommandEncoder(device);

  auto tessPass = new ComputePass<BicubicComputePipeline>(encoder, { bindings = computeBindings });
  tessPass.SetPipeline(tessPipeline);
  tessPass.Dispatch((patchWidth + 7) / 8, (patchWidth + 7) / 8, numPatches);
  tessPass.End();

  auto fb = new ColorAttachment<PreferredSwapChainFormat>(swapChain.GetCurrentTexture(), Clear, Store);
  auto db = new DepthStencilAttachment<Depth24Plus>(depthBuffer, Clear, Store, 1.0, LoadUndefined, StoreUndefined, 0);
  auto renderPass = new RenderPass<DrawPipeline>(encoder, { fragColor = fb, depth = db });

  auto cubePass = new RenderPass<SkyboxPipeline>(renderPass);
  cubePass.SetPipeline(cubePipeline);
  cubePass.Set(&cubeData);
  cubePass.DrawIndexed(cubeIndices.length, 1, 0, 0, 0);

  auto teapotPass = new RenderPass<ReflectionPipeline>(renderPass);
  teapotPass.SetPipeline(teapotPipeline);
  teapotPass.Set(&teapotData);
  teapotPass.DrawIndexed(teapotIndices.length, 1, 0, 0, 0);

  renderPass.End();
  CommandBuffer* cb = encoder.Finish();
  device.GetQueue().Submit(cb);
  swapChain.Present();

  while (System.HasPendingEvents()) {
    handler.Handle(System.GetNextEvent());
  }
}
