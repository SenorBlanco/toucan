class LightData {
  var position : float<4>;
  var color    : float<3>;
  var radius   : float;
}

class Config {
  var numLights : uint;
}

class Camera {
  var viewProjectionMatrix : float<4,4>;
  var invViewProjectionMatrix : float<4,4>;
}

class Bindings0 {
  var gBufferNormal : *SampleableTexture2D<float>;
  var gBufferAlbedo : *SampleableTexture2D<float>;
  var gBufferDepth : *SampleableTexture2D<float>;
}

class Bindings1 {
  var lights : *readonly storage Buffer<[]LightData>;
  var config : *readonly uniform Buffer<Config>;
  var camera : *readonly uniform Buffer<Camera>;
}

class Pipeline {
  worldFromScreenCoord(coord : float<2>, depthSample : float) : float<3> {
    var camera = b1.Get().camera.Map();
    // reconstruct world-space position from the screen coordinate.
    var posClip = float<4>(coord.x * 2.0 - 1.0, (1.0 - coord.y) * 2.0 - 1.0, depthSample, 1.0);
    var posWorldW = camera.invViewProjectionMatrix * posClip;
    var posWorld = float<3>(posWorldW.x, posWorldW.y, posWorldW.z) / posWorldW.w;
    return posWorld;
  }

  vertex main(vb : &VertexBuiltins) { }

  fragment main(fb : &FragmentBuiltins) {
    var result : float<3>;
    var gBufferDepth = b0.Get().gBufferDepth;
    var gBufferNormal = b0.Get().gBufferNormal;
    var gBufferAlbedo = b0.Get().gBufferAlbedo;
    var fragCoord = fb.fragCoord;

    var depthPixel = gBufferDepth.Load(uint<2>( (uint) fragCoord.x, (uint) fragCoord.y), 0);
    var depth = depthPixel.x;

    // Don't light the sky.
    if (depth >= 1.0) {
      return;
    }

    var fragCoord2 = float<2>(fragCoord.x, fragCoord.y);
    var bufferSize = gBufferDepth.Dimensions();
    var coordUV = fragCoord2 / float<2>(bufferSize);
    var position = this.worldFromScreenCoord(coordUV, depth);
    var normal4 = gBufferNormal.Load(uint<2>(Math.floor(fragCoord2)), 0);
    var normal = float<3>(normal4.x, normal4.y, normal4.z);
    var albedo = gBufferAlbedo.Load(uint<2>(Math.floor(fragCoord2)), 0);

    var config = b1.Get().config.Map();
    var lights = b1.Get().lights.Map();
    for (var i = 0u; i < config.numLights; i++) {
      var lightPos = lights[i].position;
      var L = float<3>(lightPos.x, lightPos.y, lightPos.z) - position;
      var distance = Math.length(L);
      if (distance <= lights[i].radius) {
        var lambert = Math.max(Math.dot(normal, Math.normalize(L)), 0.0);
        result += float<3>(
          lambert * Math.pow(1.0 - distance / lights[i].radius, 2.0) * lights[i].color * albedo
        );
      }
    }

    // some manual ambient
    result += float<3>(0.2);

    fragColor.Set(float<4>(result.x, result.y, result.z, 1.0));
  }

  var fragColor : *ColorAttachment<PreferredSwapChainFormat>;
  var b0 : *BindGroup<Bindings0>;
  var b1 : *BindGroup<Bindings1>;
}
