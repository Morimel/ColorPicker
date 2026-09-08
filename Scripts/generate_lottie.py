"""Generate original, editable vector Lottie artwork; no external artwork required."""
import json
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / 'ColorPicker' / 'Animations'
COLORS = ['2E86AB', '4CAF7D', 'A6B32A', 'E38A2B', 'A13B2E']
def prop(v): return {'a': 0, 'k': v}
def keys(points):
    return {'a': 1, 'k': [dict(t=t, s=v if isinstance(v, list) else [v], i={'x': .65, 'y': 1}, o={'x': .35, 'y': 0}) for t, v in points]}
def color(h): return [int(h[i:i+2], 16)/255 for i in (0,2,4)] + [1]
def fill(h): return {'ty':'fl', 'c':prop(color(h)), 'o':prop(100), 'r':1}
def rect(x,y,w,h,r=12): return {'ty':'rc','d':1,'p':prop([x,y]),'s':prop([w,h]),'r':prop(r)}
def ellipse(x,y,w,h): return {'ty':'el','d':1,'p':prop([x,y]),'s':prop([w,h])}
def stroke(h,w): return {'ty':'st','c':prop(color(h)),'o':prop(100),'w':prop(w),'lc':2,'lj':2,'ml':4}
def path(points): return {'ty':'sh','ks':prop({'i':[[0,0]]*len(points),'o':[[0,0]]*len(points),'v':points,'c':False})}
def layer(name,shapes,rotation=None,scale=None,position=None):
    return {'ty':4,'nm':name,'sr':1,'ks':{'o':prop(100),'r':rotation or prop(0),'p':position or prop([120,120,0]),'a':prop([0,0,0]),'s':scale or prop([100,100,100])},'ao':0,'shapes':shapes,'ip':0,'op':120,'st':0,'bm':0}
def save(name,layers,frames=120):
    for i,l in enumerate(layers): l['ind']=i+1; l['op']=frames
    data={'v':'5.7.4','fr':60,'ip':0,'op':frames,'w':240,'h':240,'nm':name,'ddd':0,'assets':[],'layers':layers,'markers':[]}
    (OUT/(name+'.json')).write_text(json.dumps(data,separators=(',',':'))+'\n')

# A fan of swatch cards, gently opening and settling back into a seamless loop.
layers=[]
for i,h in enumerate(COLORS):
    angle=(i-2)*22
    shapes=[ellipse(0,0,8,8),fill('FFFFFF'),rect(0,-60,44,146,10),fill(h)]
    layers.append(layer('Swatch '+h,shapes,rotation=keys([(0,angle*.8),(60,angle),(120,angle*.8)]),position=prop([120,188,0])))
save('palette-fan',layers)

# A scanner passes over a four-color sample inside a rounded viewfinder.
layers=[layer('Scan line',[rect(0,0,154,4,2),fill('3E8E9E')],position=keys([(0,[120,68,0]),(60,[120,172,0]),(120,[120,68,0])]))]
for i,h in enumerate(COLORS[:4]):
    layers.append(layer('Sample '+h,[rect(-30+(i%2)*60,-30+(i//2)*60,50,50,10),fill(h)]))
layers.append(layer('Viewfinder',[rect(0,0,174,174,26),stroke('3E8E9E',5)]))
save('color-scan',layers)

# A magnifier gently explores a small strip of color samples.
layers=[layer('Magnifier',[path([[21,21],[50,50]]),stroke('3E8E9E',10),ellipse(0,0,66,66),stroke('3E8E9E',8)],position=keys([(0,[100,105,0]),(60,[136,105,0]),(120,[100,105,0])]))]
for i,h in enumerate(COLORS):
    layers.append(layer('Color '+h,[rect(-76+i*38,40,30,58,8),fill(h)]))
save('color-search',layers)

# A short, one-shot checkmark that reaches its final state before save dismissal.
trim={'ty':'tm','s':prop(0),'e':keys([(0,0),(8,0),(24,100),(36,100)]),'o':prop(0),'m':1}
save('save-success',[
    layer('Check',[path([[-39,0],[-10,28],[43,-30]]),stroke('FFFFFF',13),trim]),
    layer('Disc',[ellipse(0,0,190,190),fill('3E8E9E')],scale=keys([(0,[75,75,100]),(14,[105,105,100]),(24,[100,100,100]),(36,[100,100,100])]))
],36)

# Home camera: the body rocks, the aperture closes, and a small flash spark expands.
rock = keys([(0,0),(32,-10),(54,7),(76,0),(180,0)])
lens_scale = keys([(0,[100,100,100]),(32,[112,112,100]),(48,[42,42,100]),(66,[110,110,100]),(88,[100,100,100]),(180,[100,100,100])])
flash = layer('Flash spark',[
    path([[-15,0],[15,0]]),path([[0,-15],[0,15]]),
    path([[-10,-10],[10,10]]),path([[-10,10],[10,-10]]),stroke('FFE0AD',6)
],position=prop([190,46,0]),scale=keys([(0,[30,30,100]),(40,[30,30,100]),(54,[120,120,100]),(78,[65,65,100]),(180,[30,30,100])]))
flash['ks']['o']=keys([(0,0),(38,0),(48,100),(64,100),(82,0),(180,0)])
save('home-camera',[
    flash,
    layer('Aperture',[ellipse(0,6,48,48),stroke('FFE0AD',8)],scale=lens_scale,rotation=rock),
    layer('Lens ring',[ellipse(0,6,78,78),stroke('FFF1A8',7)],rotation=rock),
    layer('Camera body',[rect(0,8,154,108,20),stroke('FFB9CB',10)],rotation=rock),
    layer('Camera top',[path([[-40,-46],[-28,-65],[28,-65],[40,-46]]),stroke('B9F4DB',8)],rotation=rock)
],180)

# Home gallery: a polaroid lifts and tilts to reveal a second colorful photo.
photo_position=keys([(0,[111,112,0]),(48,[88,88,0]),(90,[135,99,0]),(132,[111,112,0]),(180,[111,112,0])])
photo_rotation=keys([(0,-7),(48,-19),(90,12),(132,-7),(180,-7)])
def photo_piece(name,shapes):
    return layer(name,shapes,position=photo_position,rotation=photo_rotation)
save('home-gallery',[
    photo_piece('Sun',[ellipse(28,-28,22,22),fill('F3A83C')]),
    photo_piece('Landscape',[path([[-46,24],[-16,-10],[10,17],[26,1],[46,24]]),stroke('4CAF7D',7)]),
    photo_piece('Caption',[path([[-25,49],[25,49]]),stroke('4CAF7D',6)]),
    photo_piece('Front photo',[rect(0,0,124,140,12),fill('FFE1EC')]),
    layer('Back landscape',[path([[-44,24],[-12,-12],[14,14],[38,-4]]),stroke('2E86AB',8)],position=prop([139,133,0]),rotation=prop(10)),
    layer('Back photo',[rect(0,0,128,142,12),fill('CFC5FF')],position=prop([139,133,0]),rotation=prop(10))
],180)

# Home converter: color chips trade places around a rotating exchange symbol.
import math

def orbit(phase):
    return keys([(t,[120+74*math.cos(math.radians(phase+t*2)),120+74*math.sin(math.radians(phase+t*2)),0]) for t in range(0,181,15)])
def arc(start,end):
    return path([[42*math.cos(math.radians(a)),42*math.sin(math.radians(a))] for a in range(start,end+1,10)])
exchange_rotation=keys([(0,0),(90,180),(180,360)])
blue_fill=fill('C7ECFA')
blue_fill['c']=keys([(0,color('C7ECFA')),(60,color('E1C9FF')),(120,color('FFBECD')),(180,color('C7ECFA'))])
orange_fill=fill('FFE0AD')
orange_fill['c']=keys([(0,color('FFE0AD')),(60,color('B9F4DB')),(120,color('C7ECFA')),(180,color('FFE0AD'))])
save('home-converter',[
    layer('First color',[rect(0,0,43,43,12),blue_fill],position=orbit(225),rotation=exchange_rotation),
    layer('Second color',[rect(0,0,43,43,12),orange_fill],position=orbit(45),rotation=exchange_rotation),
    layer('Exchange',[arc(200,340),path([[24,-30],[40,-14],[43,-37]]),arc(20,160),path([[-24,30],[-40,14],[-43,37]]),stroke('FFE1EC',8)],rotation=exchange_rotation)
],180)
