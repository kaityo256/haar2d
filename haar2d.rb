require 'rubygems'
require 'cairo'

def data2rgb(data)
  buf = data.unpack("C*")
  r = []
  g = []
  b = []
  (buf.size/4).times do |i|
    b.push buf[i*4+0]
    g.push buf[i*4+1]
    r.push buf[i*4+2]
  end
  return r,g,b
end

def rgb2data(r,g,b)
  s = r.size
  buf = []
  s.times do |i|
    buf.push b[i]
    buf.push g[i]
    buf.push r[i]
    buf.push 0
  end
  buf.pack("C*")
end

def png2rgb(filename)
  surface = Cairo::ImageSurface.from_png(filename)
  abort("Image must be square.") if surface.height != surface.width
  s = surface.height
  abort("Image size must a power of two.") if s != 2**(s.bit_length-1)
  r,g,b = data2rgb(surface.data)
  return r,g,b,s
end

def rpg2png(r,g,b,s,filename)
  buf2 = rgb2data(r,g,b)
  format = Cairo::FORMAT_RGB24
  surface = Cairo::ImageSurface.new(buf2,format, s, s, 4*s)
  surface.write_to_png(filename)
end

def transform(a_out, size, level)
  a_in = Marshal.load(Marshal.dump(a_out))
  s2 = size/(2**level)
  s2.times do |y|
    s2.times do |x|
      d00 = a_in[x*2 + y*2 *size]
      d10 = a_in[x*2 + 1 + y*2 *size]
      d01 = a_in[x*2 + (y*2+1) *size]
      d11 = a_in[x*2 + 1 + (y*2+1) *size]

      n00 = (+ d00 + d10 + d01 + d11)/4.0
      n10 = (+ d00 - d10 + d01 - d11)/4.0
      n01 = (+ d00 + d10 - d01 - d11)/4.0
      n11 = (+ d00 - d10 - d01 + d11)/4.0

      a_out[x + y * size] = n00
      a_out[x + s2 + y * size] = n10
      a_out[x + (y+s2) * size] = n01
      a_out[x+s2 + (y+s2) * size] = n11
    end
  end
end

def inv_transform(a_out, size,level)
  a_in = Marshal.load(Marshal.dump(a_out))
  s2 = size/(2**level)
  s2.times do |y|
    s2.times do |x|
      n00 = a_in[x + y * size] 
      n10 = a_in[x + s2 + y * size] 
      n01 = a_in[x + (y+s2) * size]
      n11 = a_in[x+s2 + (y+s2) * size]

      d00 = (+ n00 + n10 + n01 + n11)
      d10 = (+ n00 - n10 + n01 - n11)
      d01 = (+ n00 + n10 - n01 - n11)
      d11 = (+ n00 - n10 - n01 + n11)

      a_out[x*2 + y*2 *size] = d00
      a_out[x*2 + 1 + y*2 *size] = d10
      a_out[x*2 + (y*2+1) *size] = d01
      a_out[x*2 + 1 + (y*2+1) *size] = d11
    end
  end
end

r,g,b,s = png2rgb("itanium2.png")

l = s.bit_length-1

l.times do |i|
  transform(r,s,i+1)
  transform(g,s,i+1)
  transform(b,s,i+1)
end

rpg2png(r,g,b,s,"transformed.png")

l.times do |i|
  inv_transform(r,s,9-i)
  inv_transform(g,s,9-i)
  inv_transform(b,s,9-i)
end

rpg2png(r,g,b,s,"restored.png")

