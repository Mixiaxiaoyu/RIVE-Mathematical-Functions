--Derived from the p5.js mathematical functions created by Twitter user @yuruyurau.
--Adapted by author @Mixiaxiaoyu
type JellySwirlParticles = {
  t: number,

  path: Path,
  paint: Paint,
  bgPath: Path,
  bgPaint: Paint,

  colorMode: Input<number>,
  shapeMode: Input<number>,
  speed: Input<number>,
  seed: Input<number>,
  particleCount: Input<number>,
  shapeScale: Input<number>,
  alpha: Input<number>,
  particleSize: Input<number>,
}

local W = 800
local H = 800
local PI = math.pi

local function mag(x: number, y: number): number
  return math.sqrt(x * x + y * y)
end

local function clamp(v: number, minValue: number, maxValue: number): number
  if v < minValue then
    return minValue
  end

  if v > maxValue then
    return maxValue
  end

  return v
end

local function round(v: number): number
  return math.floor(v + 0.5)
end

local function fract(x: number): number
  return x - math.floor(x)
end

local function rand(i: number, seed: number): number
  return fract(math.sin(i * 12.9898 + seed * 78.233) * 43758.5453)
end

local function randRange(
  seed: number,
  offset: number,
  minValue: number,
  maxValue: number
): number
  local r = rand(offset, seed)
  return minValue + r * (maxValue - minValue)
end

local function hslToRgb(h: number, s: number, l: number)
  h = h % 360
  s = clamp(s, 0, 100) / 100
  l = clamp(l, 0, 100) / 100

  local c = (1 - math.abs(2 * l - 1)) * s
  local x = c * (1 - math.abs((h / 60) % 2 - 1))
  local m = l - c / 2

  local r = 0
  local g = 0
  local b = 0

  if h < 60 then
    r = c
    g = x
    b = 0
  elseif h < 120 then
    r = x
    g = c
    b = 0
  elseif h < 180 then
    r = 0
    g = c
    b = x
  elseif h < 240 then
    r = 0
    g = x
    b = c
  elseif h < 300 then
    r = x
    g = 0
    b = c
  else
    r = c
    g = 0
    b = x
  end

  return (r + m) * 255, (g + m) * 255, (b + m) * 255
end

local function buildRect(path: Path, x: number, y: number, w: number, h: number)
  path:reset()
  path:moveTo(Vector.xy(x, y))
  path:lineTo(Vector.xy(x + w, y))
  path:lineTo(Vector.xy(x + w, y + h))
  path:lineTo(Vector.xy(x, y + h))
  path:close()
end

local function buildSquare(path: Path, x: number, y: number, r: number)
  path:reset()
  path:moveTo(Vector.xy(x - r, y - r))
  path:lineTo(Vector.xy(x + r, y - r))
  path:lineTo(Vector.xy(x + r, y + r))
  path:lineTo(Vector.xy(x - r, y + r))
  path:close()
end

local function buildDiamond(path: Path, x: number, y: number, r: number)
  path:reset()
  path:moveTo(Vector.xy(x, y - r * 1.4))
  path:lineTo(Vector.xy(x + r * 1.4, y))
  path:lineTo(Vector.xy(x, y + r * 1.4))
  path:lineTo(Vector.xy(x - r * 1.4, y))
  path:close()
end

local function buildCross(path: Path, x: number, y: number, r: number)
  path:reset()

  local a = r * 0.42
  local b = r * 1.5

  path:moveTo(Vector.xy(x - a, y - b))
  path:lineTo(Vector.xy(x + a, y - b))
  path:lineTo(Vector.xy(x + a, y - a))
  path:lineTo(Vector.xy(x + b, y - a))
  path:lineTo(Vector.xy(x + b, y + a))
  path:lineTo(Vector.xy(x + a, y + a))
  path:lineTo(Vector.xy(x + a, y + b))
  path:lineTo(Vector.xy(x - a, y + b))
  path:lineTo(Vector.xy(x - a, y + a))
  path:lineTo(Vector.xy(x - b, y + a))
  path:lineTo(Vector.xy(x - b, y - a))
  path:lineTo(Vector.xy(x - a, y - a))
  path:close()
end

local function buildLineDot(
  path: Path,
  x: number,
  y: number,
  r: number,
  angle: number
)
  path:reset()

  local len = r * 2.2
  local thick = r * 0.42

  local ca = math.cos(angle)
  local sa = math.sin(angle)

  local function rot(px: number, py: number)
    return x + px * ca - py * sa, y + px * sa + py * ca
  end

  local ax, ay = rot(-len, -thick)
  local bx, by = rot(len, -thick)
  local cx, cy = rot(len, thick)
  local dx, dy = rot(-len, thick)

  path:moveTo(Vector.xy(ax, ay))
  path:lineTo(Vector.xy(bx, by))
  path:lineTo(Vector.xy(cx, cy))
  path:lineTo(Vector.xy(dx, dy))
  path:close()
end

local function buildParticle(
  path: Path,
  shapeMode: number,
  x: number,
  y: number,
  r: number,
  angle: number
)
  local mode = round(shapeMode)

  if mode == 1 then
    buildDiamond(path, x, y, r)
  elseif mode == 2 then
    buildCross(path, x, y, r)
  elseif mode == 3 then
    buildLineDot(path, x, y, r, angle)
  else
    buildSquare(path, x, y, r)
  end
end

local function setParticleColor(
  paint: Paint,
  colorMode: number,
  i: number,
  t: number,
  alpha: number
)
  local mode = round(clamp(colorMode, 0, 362))
  local a = clamp(alpha, 0, 255)

  if mode == 361 then
    paint.color = Color.rgba(255, 255, 255, a)
    return
  end

  if mode == 362 then
    paint.color = Color.rgba(0, 0, 0, a)
    return
  end

  local hue = mode % 360

  local localHue = hue + math.sin(i * 0.008 + t * 1.2) * 6
  local r, g, b = hslToRgb(localHue, 92, 66)

  paint.color = Color.rgba(r, g, b, a)
end

local function getFlowerParams(seed: number)
  if seed <= 0 then
    return 4, 21, 19, 2, 14, 50, 3
  end

  local A = randRange(seed, 11, 1.4, 7.0)
  local B = randRange(seed, 22, 14, 58)
  local C = randRange(seed, 33, 18, 96)
  local D = randRange(seed, 44, 0.35, 3.6)
  local E = randRange(seed, 55, 6, 36)
  local F = randRange(seed, 66, 24, 140) * 0.6
  local G = randRange(seed, 77, 1.1, 4.8)

  G = clamp(G, 1.2, 4.4)

  return A, B, C, D, E, F, G
end

local function getParticle(
  i: number,
  t: number,
  seed: number,
  shapeScale: number,
  particleSize: number
)
  local A, B, C, D, E, F, G = getFlowerParams(seed)

  local x = i
  local y = i / 235

  local k = A * math.cos(x / B)
  local e = y / 8 - 20
  local d = mag(k, e)

  if math.abs(k) < 0.001 then
    k = 0.001
  end

  local q = G * math.sin(k * 2)
    + math.sin(y / C) * k * (9 + D * math.sin(e * E - d * 3 + t * 2))

  local s = d - t

  local baseX = q + F * math.cos(s) + 360
  local baseY = q * math.sin(s) + d * 52 - 590

  local px = W / 2 + (baseX - 360) * shapeScale
  local py = H / 2 + (baseY - 360) * shapeScale

  local size = 0.82
  if k * k > 15 then
    size = 1.75
  end

  local angle = s

  return px, py, size * shapeScale * particleSize, angle
end

function init(self: JellySwirlParticles): boolean
  self.t = 0

  self.path = Path.new()
  self.bgPath = Path.new()

  self.paint = Paint.new()
  self.paint.style = 'fill'

  self.bgPaint = Paint.new()
  self.bgPaint.style = 'fill'
  self.bgPaint.color = Color.rgb(9, 9, 9)

  return true
end

function advance(self: JellySwirlParticles, seconds: number): boolean
  local speedValue = clamp(self.speed, 0, 5)

  self.t += seconds * PI / 4 * speedValue

  return true
end

function draw(self: JellySwirlParticles, renderer: Renderer)
  buildRect(self.bgPath, 0, 0, W, H)
  renderer:drawPath(self.bgPath, self.bgPaint)

  local colorMode = clamp(self.colorMode, 0, 362)
  local shapeMode = clamp(self.shapeMode, 0, 3)
  local seedValue = math.max(0, self.seed)
  local count = math.floor(clamp(self.particleCount, 500, 12000))
  local scale = clamp(self.shapeScale, 0.2, 3.0)
  local alpha = clamp(self.alpha, 0, 255)
  local pSize = clamp(self.particleSize, 0.15, 1.4)

  for i = 1, count do
    local px, py, size, angle = getParticle(i, self.t, seedValue, scale, pSize)

    if px > -160 and px < W + 160 and py > -160 and py < H + 160 then
      setParticleColor(self.paint, colorMode, i, self.t, alpha)
      buildParticle(self.path, shapeMode, px, py, size, angle)
      renderer:drawPath(self.path, self.paint)
    end
  end
end

return function(): Node<JellySwirlParticles>
  return {
    init = init,
    advance = advance,
    draw = draw,

    t = 0,

    path = late(),
    paint = late(),
    bgPath = late(),
    bgPaint = late(),

    -- 默认值
    colorMode = 361,
    shapeMode = 0,
    speed = 1,
    seed = 98,
    particleCount = 6000,
    shapeScale = 1.25,
    alpha = 85,
    particleSize = 0.35,
  }
end
