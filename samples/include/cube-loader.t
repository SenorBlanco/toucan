class CubeLoader<PF> {
  Load(data : *[]ubyte, face : uint) {
    var image = new Image<PF>(data);
    var size = image.GetSize();
    var buffer = new hostwriteable Buffer<[]<4>ubyte>(device, texture.MinBufferWidth() * size.y);
    image.Decode(buffer.MapWrite(), texture.MinBufferWidth());
    var encoder = new CommandEncoder(device);
    texture.CopyFromBuffer(encoder, buffer, size, face);
    device.GetQueue().Submit(encoder.Finish());
  }
  var device: *Device;
  var texture: *TextureCube<PF>;
}
