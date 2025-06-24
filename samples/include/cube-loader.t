class CubeLoader<Format> {
  Load(data : *[]ubyte, face : uint) {
    var image = new Image<Format>(data);
    var size = image.GetSize();
    var buffer = new hostwriteable Buffer<[]Format:HostType>(device, texture.MinBufferWidth() * size.y);
    image.Decode(buffer.MapWrite(), texture.MinBufferWidth());
    var encoder = new CommandEncoder(device);
    texture.CopyFromBuffer(encoder, buffer, {@size, 1}, {0, 0, face});
    device.GetQueue().Submit(encoder.Finish());
  }
  var device : *Device;
  var texture : *TextureCube<Format>;
}
