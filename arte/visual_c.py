"""Fonte gráfica da direção C. Primitivas inteiras e composição por peças.

A cena-alvo usa as primitivas em memória. A cena montada lê exclusivamente
as folhas PNG exportadas, aplicando só efeitos de céu, reflexo e luz.
"""
from pathlib import Path
import math
import random
from PIL import Image, ImageDraw
from gerador import C, ROOT

def new(w,h):return Image.new('RGBA',(w,h))
def draw(im):return ImageDraw.Draw(im)
def rect(d,box,c):d.rectangle(box,fill=C[c])
def line(d,pts,c,width=1):d.line(pts,fill=C[c],width=width)
def dot(d,xy,c):d.point(xy,fill=C[c])
def poly(d,pts,c):d.polygon(pts,fill=C[c])
def export(im,folder,name):
    p=ROOT/folder/(name+'.png');p.parent.mkdir(parents=True,exist_ok=True);im.save(p,optimize=False);return im

TILE_NAMES=['grama_a','grama_b','terra_a','terra_b','pedra','areia','agua_funda','grama_seca','terra_raizes','rocha','borda_grama_a','borda_grama_b','pedra_aflorada']
def tile(k):
    im=new(8,8);d=draw(im)
    if k in (10,11):
        for x in range(8):
            h=[5,4,5,3,5,4,5,5][(x+(3 if k==11 else 0))%8]
            line(d,(x,h,x,7),13);dot(d,(x,h),15);dot(d,(x,h+1),14)
        return im
    if k==12:
        poly(d,[(0,7),(1,4),(3,2),(5,2),(7,5),(7,7)],11)
        line(d,(1,4,3,2,5,2),12);line(d,(2,5,5,4,6,5),13);line(d,(1,7,7,7),8)
        return im
    base={0:9,1:9,2:9,3:9,4:11,5:12,6:17,7:9,8:8,9:13}[k]
    rect(d,(0,0,7,7),base)
    if k in (0,1,7):
        rect(d,(0,0,7,1),16 if k==7 else 14);line(d,(0,0,7,0),16 if k==7 else 15)
        for x,y in [(1,2),(2,2),(5,2),(5,3),(6,2)]:dot(d,(x,y),16 if k==7 else 13)
        dot(d,(2+(k%2),5),10);dot(d,(5,6),8)
    elif k in (2,3):
        for x,y in ([(2,1),(5,4),(3,6),(6,6)] if k==2 else [(4,2),(2,4),(5,6)]):dot(d,(x,y),10)
        dot(d,(1,5),8)
    elif k==4:
        line(d,(1,2,4,1,6,3),12);line(d,(1,3,2,6,6,6),8);line(d,(3,4,6,4),13)
    elif k==5:
        for xy in [(1,2),(5,5),(3,6)]:dot(d,xy,10)
    elif k==6:
        line(d,(1,3,4,3),18);dot(d,(6,6),18)
    elif k==8:
        line(d,(2,0,2,2,4,4,3,6),9);line(d,(2,2,0,4),10);line(d,(4,4,6,5),9)
        dot(d,(6,2),11)
    elif k==9:
        line(d,(0,1,3,1,4,3,7,3),11);line(d,(1,7,1,5,4,4),8);dot(d,(5,6),12)
    return im

def surface(frame=0):
    q=new(8,8);d=draw(q);rect(d,(0,2,7,7),18)
    for x in range(8):
        y=1 if (x+frame*2)%8<4 else 2
        dot(d,(x,y),19)
        if (x+frame*2)%8<3:dot(d,(x,6),17)
    return q

def sheet(frames):
    im=new(frames[0].width*len(frames),frames[0].height)
    for i,q in enumerate(frames):im.alpha_composite(q,(i*q.width,0))
    return im

def terrain_height(col):
    # Central surface at y120 (75%); hill rises only 16 pixels.
    if col<12:return 136
    if col<16:return 128
    if col<39:return 120
    if col<44:return 112
    if col<55:return 104
    return 112

def terrain(from_files=False):
    im=new(480,160)
    if from_files:
        atlas=Image.open(ROOT/'terreno_c/terreno.png').convert('RGBA')
        tiles=[atlas.crop((i*8,0,i*8+8,8)) for i in range(13)]
        surf=Image.open(ROOT/'terreno_c/agua_superficie_4q.png').convert('RGBA').crop((0,0,8,8))
    else:tiles=[tile(i) for i in range(13)];surf=surface()
    for col in range(60):
        top=terrain_height(col);sand=col<16
        if col<12:
            im.alpha_composite(tiles[5],(col*8,144));im.alpha_composite(tiles[9],(col*8,152))
            for y in (128,136):im.alpha_composite(tiles[6],(col*8,y))
            im.alpha_composite(surf,(col*8,120));continue
        for y in range(top,160,8):
            depth=y-top
            kind=5 if sand and depth<16 else (col%2 if depth==0 else 2+col%2 if depth<16 else 8 if depth<24 else 9)
            im.alpha_composite(tiles[kind],(col*8,y))
        if not sand:im.alpha_composite(tiles[10+col%2],(col*8,top-5))
    # Overlapping only exported tile variants rounds the corners of tile steps.
    for col in (16,39,44,55):
        im.alpha_composite(tiles[12],(col*8-4,terrain_height(col)-3))
    return im

def terrain_demo():
    """Teste adicional de encaixe com praia, lago central e morro."""
    im=new(480,160)
    for col in range(60):
        top=136 if col<9 or 29<=col<38 else 128 if col<15 else 112 if col<44 else 104 if col<48 or col>55 else 96
        water=col<9 or 29<=col<38
        for y in range(top,160,8):
            depth=y-top
            k=5 if (water or col<15) and depth<8 else col%2 if depth==0 else 2+col%2 if depth<16 else 8 if depth<24 else 9
            im.alpha_composite(tile(k),(col*8,y))
        if water:
            im.alpha_composite(surface(),(col*8,112))
            for y in range(120,top,8):im.alpha_composite(tile(6),(col*8,y))
        elif col>=15:im.alpha_composite(tile(10+col%2),(col*8,top-5))
    return im

def human(body='a',frame=0,action='parado',skin=25,cloth=27):
    child=body=='crianca';im=new(6 if child else 8,8 if child else 12);d=draw(im)
    shadow=skin-1 if skin>23 else 8
    shade=29 if cloth==28 else 27 if cloth==29 else 29
    if child:
        rect(d,(2,0,3,2),skin);dot(d,(2,0),8);dot(d,(4,1),skin);dot(d,(3,1),shadow)
        rect(d,(1,3,3,5),cloth);line(d,(1,4,1,5),shade);dot(d,(4,4),skin)
        feet=[(1,4),(2,3),(0,4),(2,3)][frame]
        line(d,(2,6,feet[0],7),shadow);line(d,(3,6,feet[1],7),skin)
        return im
    bent=action=='colher' and frame in (1,2)
    elder=body=='idoso'
    kneel=action=='rezar'
    hx,hy=(4,2) if bent else (4,1) if elder else (3,3) if kneel else (3,0)
    rect(d,(hx,hy,hx+2,hy+3),skin);line(d,(hx,hy,hx+2,hy),12 if elder else 8)
    dot(d,(hx,hy+1),12 if elder else 9);dot(d,(min(7,hx+3),hy+2),skin);dot(d,(hx+2,hy+1),shadow)
    top=6 if kneel else 5 if bent else 4
    left,right=(1,5) if body=='b' else (2,4)
    if bent:left,right=1,4
    rect(d,(left,top,right,8),cloth);line(d,(left,top+1,left,8),shade)
    if body=='b':rect(d,(1,8,6,8),cloth);dot(d,(1,8),shade)
    if kneel:
        line(d,(2,7,1,5,1,2+frame),skin);line(d,(5,7,6,5,6,1+frame),skin)
        line(d,(3,9,2,11,5,11),shadow);line(d,(4,9,5,10,6,10),skin)
    elif bent:
        line(d,(4,6,6,8,6,10 if frame==2 else 9),skin)
        line(d,(2,9,1,11),shadow);line(d,(4,9,5,11),skin)
    else:
        line(d,(left-1,top+1,left-1,7),shadow)
        line(d,(right+1,top,right+2 if right<5 else 7,6),skin)
        if elder:line(d,(7,7,7,11),10)
        feet=[(1,6),(3,4),(0,6),(3,4)][frame] if action=='andar' else (2,5)
        line(d,(3,9,feet[0],11),shadow);line(d,(4,9,feet[1],11),skin)
        if action=='parado' and frame==1:dot(d,(right+1,7),skin)
    return im

def humans(name):
    if name=='habitantes_variacoes':
        im=new(96,32)
        for row,b in enumerate(('a','b')):
            for s in range(4):
                for t in range(3):im.alpha_composite(human(b,skin=23+s,cloth=27+t),((s*3+t)*8,row*16))
        return im
    words=name.split('_');body=words[1] if words[0]=='adulto' else words[0];action=words[-2];n=int(words[-1][0])
    return sheet([human(body,f,action,25,27 if body=='a' else 28) for f in range(n)])

def prop(name):
    dims={'cabana_galhos':(16,16),'fogueira_apagada':(8,8),'arvore_a':(16,24),'arvore_b':(16,24),'arbusto':(8,8),'pinheiro_a':(16,32),'pinheiro_b':(16,32),'capim':(8,8),'pedra_grande':(16,16)}
    if name=='fogueira_4q':
        frames=[]
        for f in range(4):
            q=prop('fogueira_apagada');d=draw(q)
            poly(d,[(1,5),(2,2),(3,3),(3+f%2,0),(5,3),(6,5),(4,6)],20)
            poly(d,[(2,5),(3,2+f%2),(5,4),(4,6)],21);line(d,(3,4,3,5),22);dot(d,(4,5),31);frames.append(q)
        return sheet(frames)
    im=new(*dims[name]);d=draw(im)
    if name=='cabana_galhos':
        poly(d,[(0,15),(7,1),(9,1),(15,15)],9)
        poly(d,[(0,12),(7,0),(9,1),(15,12),(13,12),(11,10),(9,9),(5,10),(2,13)],13)
        for pts in [(2,9,6,3),(5,7,8,2),(9,3,11,6),(11,7,13,10)]:line(d,pts,14)
        line(d,(4,6,6,3),15);line(d,(7,3,8,1),15)
        poly(d,[(5,15),(8,7),(11,15)],8)
        line(d,(1,15,8,1),10);line(d,(8,1,15,15),9);line(d,(0,15,15,15),8)
        dot(d,(3,11),12);dot(d,(13,13),10)
    elif name=='fogueira_apagada':
        for xy in [(0,6),(2,7),(6,7),(7,5),(1,4)]:dot(d,xy,11)
        line(d,(1,6,6,4),9,2);line(d,(1,4,6,6),10);dot(d,(2,5),8)
    elif name.startswith('pinheiro'):
        b=name.endswith('b');rect(d,(7,17,8,30),9);line(d,(7,19,7,29),10)
        for n in range(4):
            y=1+n*5+(1 if b else 0);span=min(7,3+n)
            poly(d,[(7,y),(7+span,y+10),(7+span-2,y+11),(7-span,y+10)],13)
            line(d,(7,y+1,8-span,y+9),14);dot(d,(7,y+1),15);line(d,(8,y+5,6+span,y+9),14)
        line(d,(5,31,10,31),8)
    elif name.startswith('arvore'):
        b=name.endswith('b');rect(d,(7,10,9,22),9);line(d,(7,13,7,21),10);line(d,(7,15,4,11),9);line(d,(9,13,12,10),9)
        poly(d,[(0,8),(2,4),(5,3),(5,1),(10,0),(13,3),(13,5),(15,7),(14,12),(10,14),(3,13)],13)
        poly(d,[(1,7),(3,4),(6,4),(6,2),(10,1),(12,4),(11,8),(7,9),(3,9)],14)
        for pts in [(3,4,5,4),(7,2,10,2),(1,7,3,7),(7,10,10,10),(12,6,13,7)]:line(d,pts,15 if not b else 16)
        if b:line(d,(3,10,5,11),14);dot(d,(11,8),20)
        line(d,(5,23,11,23),8)
    elif name=='arbusto':
        poly(d,[(0,6),(0,3),(2,2),(3,0),(5,1),(7,3),(7,6)],13)
        line(d,(1,3,3,1,5,2),15);line(d,(2,3,5,3,6,4),14);dot(d,(3,5),20);dot(d,(6,3),20)
    elif name=='capim':
        for pts in [(3,7,1,3),(3,7,3,1),(4,7,6,2),(5,7,7,5)]:line(d,pts,13)
        for xy in [(1,3),(3,1),(6,2)]:dot(d,xy,15)
        line(d,(4,6,5,4),14)
    elif name=='pedra_grande':
        poly(d,[(1,13),(2,7),(6,3),(11,4),(14,8),(15,13),(11,15),(4,15)],8)
        poly(d,[(2,12),(3,7),(6,4),(11,5),(13,9),(13,13),(5,14)],11)
        line(d,(3,7,6,4,11,5),12);line(d,(7,7,8,10,12,10),13);dot(d,(4,10),12)
    return im

OBJECTS=[('arvore_a',132),('arvore_b',310),('pinheiro_a',333),('pinheiro_b',351),('arvore_a',371),('pinheiro_a',395),('pinheiro_b',413),('arvore_b',434),('pinheiro_a',456),('pinheiro_b',470),('cabana_galhos',176),('cabana_galhos',272),('arbusto',148),('arbusto',299),('arbusto',447),('capim',159),('capim',324),('capim',365),('capim',427),('pedra_grande',464)]
PEOPLE=[('a',197,24,27),('b',210,25,28),('crianca',222,26,29),('a',246,23,29),('crianca',258,25,27),('b',289,26,27),('a',161,25,28)]

def backdrop(mode):
    im=new(480,160);d=draw(im);night=mode=='noite';rng=random.Random(912)
    stops=[3,4,5] if night else [2,1,0] if mode=='dia' else [5,7,6]
    bayer=((0,8,2,10),(12,4,14,6),(3,11,1,9),(15,7,13,5))
    for y in range(160):
        z=min(2,y/55);k=int(z);fraction=z-k
        for x in range(480):im.putpixel((x,y),C[stops[min(2,k+int(fraction*16>bayer[y%4][x%4]))]])
    if night:
        for _ in range(45):dot(d,(rng.randrange(480),rng.randrange(5,75)),31)
        d.ellipse((82,35,93,46),fill=C[31]);d.ellipse((87,32,96,43),fill=C[4])
    else:d.ellipse((84,72 if mode=='entardecer' else 24,102,90 if mode=='entardecer' else 42),fill=C[22 if mode=='entardecer' else 31])
    for x,y,w in [(12,36,69),(145,21,59),(255,42,67),(373,29,84)]:
        rect(d,(x,y,x+w,y+3),4 if night else 7 if mode=='entardecer' else 1)
        rect(d,(x+9,y-3,x+w-10,y),5 if night else 6 if mode=='entardecer' else 0)
        line(d,(x+21,y-5,x+w-25,y-5),5 if night else 6 if mode=='entardecer' else 0)
    for offset,col in [(0,4 if night else 1 if mode=='dia' else 5),(16,5 if night else 0 if mode=='dia' else 7)]:
        poly(d,[(0,130),(0,108+offset),(44,97+offset),(87,106+offset),(139,68+offset),(188,99+offset),(238,84+offset),(289,107+offset),(349,69+offset),(397,91+offset),(451,66+offset),(479,91+offset),(479,160),(0,160)],col)
    return im

def light_asset(q,x,y,night):
    if not night:return q
    colors={15:14,14:13,12:11,11:13,10:9,19:18,18:17,16:14,0:4,1:4}
    indices={p:i for i,p in enumerate(C)};out=q.copy();data=[]
    for py in range(q.height):
        for px in range(q.width):
            p=q.getpixel((px,py))
            if not p[3]:data.append(p);continue
            idx=indices[p];distance=math.hypot((x+px-235)*0.9,(y+py-115)*1.5)
            if distance<24:
                warm={8:9,9:10,10:10,11:10,12:12,13:9,14:16,15:16,23:24,24:25,25:26,26:26,27:27,28:19,29:7}
                idx=warm.get(idx,idx)
            else:idx=colors.get(idx,idx)
            data.append(C[idx])
    out.putdata(data);return out

def scene(mode='dia',from_files=False):
    im=backdrop(mode);night=mode=='noite'
    ground=terrain(from_files);im.alpha_composite(light_asset(ground,0,0,night))
    # Reflection, fog and local lighting are motor effects, never asset pixels.
    d=draw(im)
    for y in range(123,144,3):
        span=2+(y-121)//3;line(d,(93-span,y,93+span,y),19 if night else 22 if mode=='entardecer' else 19)
    def get_prop(name):
        return Image.open(ROOT/'estagio1_c'/(name+'.png')).convert('RGBA') if from_files else prop(name)
    for name,x in OBJECTS:
        q=get_prop(name);y=terrain_height(min(59,(x+q.width//2)//8))-q.height
        im.alpha_composite(light_asset(q,x,y,night),(x,y))
    if night:
        # Warm light uses opaque palette colors clipped to land pixels.
        d=draw(im)
        for y in range(120,126):
            for x in range(211,260):
                if math.hypot(x-235,(y-120)*3)<23 and (x+y)%3!=0:dot(d,(x,y),10 if y<123 else 9)
    for b,x,s,t in PEOPLE:
        if from_files:
            q=Image.open(ROOT/'habitantes_c'/('crianca_andar_4q.png' if b=='crianca' else 'adulto_'+b+'_parado_2q.png')).convert('RGBA')
            q=q.crop((0,0,6 if b=='crianca' else 8,8 if b=='crianca' else 12))
            # Runtime palette swap is cultural skin/clothing selection.
            replacements={C[25]:C[s],C[24]:C[max(23,s-1)],C[27 if b=='a' else 28]:C[t],C[29]:C[29 if t==28 else 27 if t==29 else 29]}
            q.putdata([replacements.get(p,p) for p in q.getdata()])
        else:
            # Exactly the same indexed palette swap as the runtime sheet path.
            q=human(b,0,'andar' if b=='crianca' else 'parado',25,27 if b=='a' else 28)
            replacements={C[25]:C[s],C[24]:C[max(23,s-1)],C[27 if b=='a' else 28]:C[t],C[29]:C[29 if t==28 else 27 if t==29 else 29]}
            q.putdata([replacements.get(p,p) for p in q.getdata()])
        y=120-q.height;im.alpha_composite(light_asset(q,x,y,night),(x,y))
    fire=get_prop('fogueira_4q').crop((0,0,8,8));im.alpha_composite(fire,(232,112))
    d=draw(im)
    for xy in [(234,107),(239,101),(237,97)]:dot(d,xy,22 if night else 10)
    return im

def generate(folder,name):
    if folder=='alvo':im=scene(name.split('_')[1])
    elif folder=='cenas_c':im=scene(name.split('_')[1],True)
    elif folder=='terreno_c':
        if name=='terreno':im=sheet([tile(i) for i in range(13)])
        elif name=='agua_superficie_4q':im=sheet([surface(f) for f in range(4)])
        elif name=='terreno_teste':im=terrain_demo()
        elif name=='terreno_c_teste':im=terrain()
        else:im=tile(12)
    elif folder=='habitantes_c':im=humans(name)
    else:im=prop(name)
    if name.endswith('_4x'):im=im.resize((im.width*4,im.height*4),Image.Resampling.NEAREST)
    return export(im,folder,name)
