"""Arte determinística do Simulador de vida. Requer Python e Pillow.

Cada PNG possui um ponto de entrada homônimo na mesma pasta.
Coordenadas e cores são inteiras; nenhuma suavização ou alpha parcial.
"""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
GROUPS = [
    ('Ceu de dia', ['B9DDDC', '82B8CC', '528CAD']),
    ('Ceu de noite', ['19283F', '283B59', '514968']),
    ('Entardecer', ['EBA56F', 'C77989']),
    ('Terra e pedra', ['473A35', '735342', 'A47D55', '8C8B80', 'C5BBA1']),
    ('Vegetacao', ['294B42', '477052', '7F9D61', 'B2AA68']),
    ('Agua', ['244D69', '3D8298', '9BC9C6']),
    ('Fogo', ['C34E46', 'EF8A45', 'F4CF79']),
    ('Pele', ['633B35', 'A15D46', 'CE9567', 'F0C69A']),
    ('Tecidos', ['DF6974', '65C2BF', 'A995DB']),
    ('Neutros', ['20252D', 'F5E9CB']),
]
HEX = [h for _, values in GROUPS for h in values]
C = [tuple(bytes.fromhex(h)) + (255,) for h in HEX]

def canvas(w, h):
    return Image.new('RGBA', (w, h))

def save(im, folder, name):
    path = ROOT / folder / (name + '.png')
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path, optimize=False)
    return im

def sky(night=False):
    im = canvas(480, 160)
    d = ImageDraw.Draw(im)
    colors = [3, 4, 5] if night else [2, 1, 0]
    for y in range(160):
        d.line((0, y, 479, y), fill=C[colors[min(2, y//36)]])
    if night:
        for x,y in [(22,16),(62,39),(102,12),(141,29),(191,19),(234,47),(280,12),(320,33),(375,18),(419,42),(461,16)]:
            d.point((x,y), fill=C[31])
        d.ellipse((345,13,355,23), fill=C[31])
        d.ellipse((349,11,357,20), fill=C[3])
    else:
        for x,y in [(38,29),(207,19),(388,35)]:
            d.rectangle((x,y,x+31,y+3),fill=C[0])
            d.rectangle((x+8,y-3,x+23,y+4),fill=C[0])
    return im

def paleta():
    p=ROOT/'paleta'; p.mkdir(parents=True,exist_ok=True)
    (p/'paleta.hex').write_text('\n'.join(HEX)+'\n',encoding='ascii')
    rows=['GIMP Palette','Name: Simulador de vida — 32 cores','Columns: 8','#']
    for group, vals in GROUPS:
        for i,h in enumerate(vals):
            r,g,b=bytes.fromhex(h); rows.append(f'{r:3} {g:3} {b:3}\t{group} {i+1}')
    (p/'paleta.gpl').write_text('\n'.join(rows)+'\n',encoding='utf-8')
    im=canvas(64,32); d=ImageDraw.Draw(im)
    for i,c in enumerate(C): d.rectangle((i%8*8,i//8*8,i%8*8+7,i//8*8+7),fill=c)
    return save(im,'paleta','paleta')

def paleta_teste():
    im=canvas(480,160); d=ImageDraw.Draw(im)
    # Ordered dithering only at color boundaries, avoiding intermediate colors.
    bands=[[2,1,0],[2,7,6],[5,7,6],[3,4,5]]
    matrix=((0,8,2,10),(12,4,14,6),(3,11,1,9),(15,7,13,5))
    for y in range(120):
        for x in range(480):
            section=min(3,x//120); idx=bands[section][min(2,y//40)]
            for boundary in (120,240,360):
                if boundary-16<=x<boundary+16:
                    left=boundary//120-1
                    use_right=(x-boundary+16)*16//32 > matrix[y%4][x%4]
                    idx=bands[left+int(use_right)][min(2,y//40)]
            im.putpixel((x,y),C[idx])
    d.rectangle((0,120,479,123),fill=C[14]); d.rectangle((0,124,479,159),fill=C[9])
    d.rectangle((0,138,479,159),fill=C[17]); d.line((0,138,479,138),fill=C[19])
    for x in range(4,480,19): d.line((x,145+(x%3),x+6,145+(x%3)),fill=C[18])
    return save(im,'paleta','paleta_teste')

def tile(kind):
    im=canvas(8,8); d=ImageDraw.Draw(im)
    base=[9,9,9,9,13,12,17,9][kind]; d.rectangle((0,0,7,7),fill=C[base])
    if kind in (0,1,7):
        d.rectangle((0,0,7,1),fill=C[16 if kind==7 else 15])
        for x in range(8):
            d.point((x,0),fill=C[16 if kind==7 else 14])
            if (x+kind)%3==1:d.point((x,2),fill=C[16 if kind==7 else 14])
        for x,y in [(2,4),(5,6)]:d.point((x,y),fill=C[10])
    elif kind in (2,3):
        for x,y in ([(2,2),(5,5),(3,6)] if kind==2 else [(4,2),(1,5),(5,6)]):d.point((x,y),fill=C[10])
    elif kind==4:
        d.line((1,2,5,2),fill=C[12]);d.line((2,3,2,5),fill=C[11]);d.line((3,6,6,6),fill=C[8])
    elif kind==5:
        for x,y in [(1,2),(5,4),(3,6)]:d.point((x,y),fill=C[10])
    elif kind==6:
        d.line((2,3,5,3),fill=C[18])
    return im

def terreno():
    im=canvas(64,8)
    for k in range(8):im.paste(tile(k),(k*8,0))
    return save(im,'terreno','terreno')

def agua_superficie_4q():
    im=canvas(32,8)
    for f in range(4):
        q=canvas(8,8); d=ImageDraw.Draw(q);d.rectangle((0,1,7,7),fill=C[18])
        for x in range(8):
            y=0 if (x+f*2)%8<4 else 1
            d.point((x,y),fill=C[19]);d.point((x,5),fill=C[17] if (x+f*2)%8<3 else C[18])
        im.paste(q,(f*8,0))
    return save(im,'terreno','agua_superficie_4q')

def ground_height(col):
    if col<7:return 136 # sea
    if col<13:return 128 # beach
    if col<30:return 112
    if col<39:return 136 # lake bed
    if col<43:return 112
    if col<46:return 104
    if col<49:return 96
    if col<55:return 88
    if col<58:return 96
    return 104

def terreno_teste():
    im=canvas(480,160)
    for col in range(60):
        top=ground_height(col)
        for y in range(top,160,8):
            kind=(5 if col<13 or 30<=col<39 else col%2) if y==top else (4 if y>=152 else 2+col%2)
            im.paste(tile(kind),(col*8,y))
        if col<7 or 30<=col<39:
            for y in range(120 if col<7 else 120,top,8):im.paste(tile(6),(col*8,y))
            im.paste(agua_frame(),(col*8,112))
    return save(im,'terreno','terreno_teste')

def agua_frame():
    p=ROOT/'terreno/agua_superficie_4q.png'
    if not p.exists():agua_superficie_4q()
    return Image.open(p).convert('RGBA').crop((0,0,8,8))

def person(body='a', frame=0, walking=False, skin=25, cloth=27):
    child=body=='c'; w,h=(6,8) if child else (8,12)
    im=canvas(w,h);d=ImageDraw.Draw(im)
    if child:
        d.rectangle((2,0,3,2),fill=C[skin]);d.point((4,1),fill=C[skin]);d.point((3,1),fill=C[30])
        d.rectangle((1,3,3,5),fill=C[cloth]);d.point((4,4),fill=C[skin])
        legs=[(1,4),(2,3),(0,4),(2,3)][frame] if walking else (2,3)
        for x in legs:d.line((x,6,x,7),fill=C[skin])
    else:
        d.rectangle((3,0,5,3),fill=C[skin]);d.point((6,2),fill=C[skin]);d.point((5,1),fill=C[30])
        d.line((3,0,5,0),fill=C[8]);d.point((3,1),fill=C[8])
        if body=='a':
            d.rectangle((2,4,4,8),fill=C[cloth]);d.line((2,4,1,7),fill=C[skin]);d.line((5,4,6,6),fill=C[skin])
        else:
            d.rectangle((1,4,5,6),fill=C[cloth]);d.rectangle((2,7,5,7),fill=C[cloth]);d.rectangle((1,8,6,8),fill=C[cloth])
            d.line((0,5,0,7),fill=C[skin]);d.line((6,4,7,6),fill=C[skin])
        # Head and torso stay anchored; alternate feet around a stable baseline.
        legs=[(1,6),(3,4),(0,6),(3,4)][frame] if walking else (2,5)
        d.line((3,9,legs[0],11),fill=C[skin]);d.line((4,9,legs[1],11),fill=C[skin])
        if not walking and frame==1:d.point((6 if body=='a' else 7,7),fill=C[skin])
    return im

def people_sheet(name):
    body='c' if name.startswith('crianca') else name.split('_')[1]
    n=4 if '4q' in name else 2;w,h=(6,8) if body=='c' else (8,12)
    im=canvas(w*n,h)
    for f in range(n):im.paste(person(body,f,'andar' in name,25,27 if body=='a' else 28),(f*w,0))
    return save(im,'habitantes',name)

def habitantes_variacoes():
    im=canvas(96,32)
    for row,body in enumerate(('a','b')):
        for s in range(4):
            for t in range(3):im.paste(person(body,skin=23+s,cloth=27+t),((s*3+t)*8,row*16))
    return save(im,'habitantes','habitantes_variacoes')

def prop(name):
    dims={'cabana_galhos':(16,16),'arvore_a':(16,24),'arvore_b':(16,24),'arbusto':(8,8),'fogueira_apagada':(8,8)}
    im=canvas(*dims[name]);d=ImageDraw.Draw(im)
    if name=='cabana_galhos':
        d.polygon([(1,14),(7,2),(9,2),(15,14)],fill=C[9])
        d.polygon([(0,12),(7,1),(9,1),(15,12),(12,11),(10,9),(5,10),(2,13)],fill=C[14])
        d.line((2,9,7,2),fill=C[15]);d.line((6,6,9,3),fill=C[15]);d.line((10,6,13,10),fill=C[13])
        d.polygon([(5,14),(8,7),(11,14)],fill=C[8])
        d.line((1,15,8,2),fill=C[10]);d.line((8,2,15,15),fill=C[10]);d.line((0,15,15,15),fill=C[9])
    elif name.startswith('arvore'):
        d.rectangle((7,10,9,22),fill=C[9]);d.line((7,13,7,21),fill=C[10]);d.line((5,23,11,23),fill=C[9])
        if name=='arvore_a':
            d.polygon([(1,12),(0,8),(3,7),(2,4),(6,2),(10,2),(14,5),(13,7),(15,10),(13,14),(4,15)],fill=C[13])
            d.polygon([(1,8),(4,4),(10,3),(13,6),(10,10),(5,11)],fill=C[14])
            d.line((4,4,9,4),fill=C[15]);d.line((2,7,5,7),fill=C[15]);d.line((9,10,12,10),fill=C[14])
        else:
            d.polygon([(7,0),(12,7),(10,7),(14,12),(11,12),(15,17),(1,17),(5,12),(2,12),(6,7),(4,7)],fill=C[13])
            d.line((7,2,5,6),fill=C[15]);d.line((7,8,4,11),fill=C[14]);d.line((7,13,3,16),fill=C[14])
    elif name=='arbusto':
        d.polygon([(0,6),(0,3),(2,2),(3,0),(5,1),(7,3),(7,6)],fill=C[13]);d.rectangle((2,2,5,4),fill=C[14]);d.point((3,1),fill=C[15]);d.point((6,4),fill=C[20])
    else:
        d.line((1,7,6,4),fill=C[9],width=2);d.line((1,4,6,7),fill=C[10]);d.point((2,4),fill=C[12]);d.point((5,7),fill=C[8])
    return save(im,'estagio1',name)

def fogueira_4q():
    base=prop_read('fogueira_apagada');im=canvas(32,8)
    for f in range(4):
        q=base.copy();d=ImageDraw.Draw(q)
        tips=[(3,0),(4,1),(2,0),(4,0)]
        d.polygon([tips[f],(5,3),(6,5),(4,6),(1,5),(2,2)],fill=C[20])
        d.polygon([(3,2),(5,4),(4,6),(2,5)],fill=C[21]);d.line((3,4,3,5),fill=C[22]);im.paste(q,(f*8,0))
    return save(im,'estagio1','fogueira_4q')

def prop_read(name):
    return Image.open(ROOT/'estagio1'/f'{name}.png').convert('RGBA')

def scene(night=False):
    im=sky(night); terrain=Image.open(ROOT/'terreno/terreno_teste.png').convert('RGBA')
    if night:
        # Night palette substitution, retaining opaque integer pixels.
        mapping={0:4,1:4,2:3,12:11,15:14,14:13,10:9,19:18,18:17,16:14}
        terrain.putdata([C[mapping.get(C.index(p),C.index(p))] if p[3] else p for p in terrain.getdata()])
    im.alpha_composite(terrain)
    objects=[('arvore_a',110,88),('arvore_b',142,88),('arvore_a',430,64),('arvore_b',454,72),('arbusto',103,120),('arbusto',225,104),('arbusto',328,104),('cabana_galhos',163,96),('cabana_galhos',207,96)]
    for name,x,y in objects:im.alpha_composite(prop_read(name),(x,y))
    fire=Image.open(ROOT/'estagio1/fogueira_4q.png').convert('RGBA').crop((0,0,8,8))
    if night:
        d=ImageDraw.Draw(im)
        # Warm ground pool uses existing earth/fire colors, no translucent glow.
        d.line((184,112,207,112),fill=C[10]);d.line((188,113,203,113),fill=C[10]);d.line((192,114,200,114),fill=C[9])
    im.alpha_composite(fire,(191,104))
    for body,x,skin,cloth in [('a',155,24,27),('b',180,25,28),('c',188,26,29),('a',203,23,29),('c',216,25,27),('b',229,26,27),('a',135,25,28)]:
        im.alpha_composite(person(body,skin=skin,cloth=cloth),(x,104 if body=='c' else 100))
    return im

def generate(name):
    if name in globals() and callable(globals()[name]):return globals()[name]()
    if name.startswith(('adulto_','crianca_')):return people_sheet(name)
    if name.startswith('cena_'):
        im=scene('noite' in name)
        if '3x' in name:im=im.resize((1440,480),Image.Resampling.NEAREST)
        return save(im,'cenas',name)
    return prop(name)
