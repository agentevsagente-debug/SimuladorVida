"""Três direções originais: mesma geografia, sete pessoas e duas cabanas.
Rasterização inteira em 480x160, sem filtros; somente paleta T001.
"""
from pathlib import Path
import sys
import random
from PIL import Image,ImageDraw
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from gerador import C,person,prop_read
OUT=Path(__file__).resolve().parent
BAYER=((0,8,2,10),(12,4,14,6),(3,11,1,9),(15,7,13,5))

def height(x):
    if x<113:return 126
    if x<149:return 126-(x-113)//3
    if x<308:return 114
    if x<384:return 114-(x-308)//3
    if x<434:return 89
    return 89+(x-434)//4

def make(style,night=False):
    rng=random.Random(187)
    im=Image.new('RGBA',(480,160));d=ImageDraw.Draw(im)
    stops=([3,4,5] if night else ([5,7,6] if style=='a' else [2,7,6] if style=='b' else [2,5,7,6]))
    for y in range(160):
        at=y/115*(len(stops)-1);k=min(len(stops)-1,int(at));frac=at-k
        for x in range(480):
            color=stops[min(k+1,len(stops)-1)] if frac*16>BAYER[y%4][x%4] else stops[k]
            im.putpixel((x,y),C[color])
    if night:
        for _ in range(54):
            x=rng.randrange(480);y=rng.randrange(5,78)
            d.point((x,y),fill=C[12 if style=='a' else 31])
        d.ellipse((91,29,104,42),fill=C[31]);d.ellipse((96,27,107,39),fill=C[4])
    else:d.ellipse((86,69,107,90),fill=C[22])
    for x,y,w in [(12,34,65),(143,20,68),(258,41,59),(367,27,87)]:
        color=4 if night else 7 if style=='a' else 6
        if style=='b':
            d.rounded_rectangle((x,y,x+w,y+7),radius=3,fill=C[color]);d.ellipse((x+11,y-4,x+35,y+8),fill=C[color])
        else:
            d.rectangle((x,y,x+w,y+2),fill=C[color]);d.rectangle((x+14,y-3,x+w-12,y+3),fill=C[color])
            d.line((x+25,y+6,x+w+11,y+6),fill=C[color])
    # Distant silhouettes, then a second line of hills, both behind the playable land.
    for offset,color in [(0,4 if night else 5),(18,5 if night else 7)]:
        points=[(0,160),(0,99+offset),(39,86+offset),(73,94+offset),(132,60+offset),(178,88+offset),(226,75+offset),(274,94+offset),(327,64+offset),(372,81+offset),(414,55+offset),(479,87+offset),(479,160)]
        d.polygon(points,fill=C[color])
    # Water and horizontal bands reflected beneath the low sun.
    d.rectangle((0,110,132,159),fill=C[17 if night or style=='a' else 18])
    for y in range(112,160):
        half=3+(y-110)//3
        if y%3==0:
            center=97+(y%7)-3;d.line((center-half,y,center+half,y),fill=C[19 if night else 6 if style=='a' else 22])
    for _ in range(105 if style=='c' else 50):
        x=rng.randrange(125);y=rng.randrange(111,160)
        d.line((x,y,min(128,x+rng.randrange(2,9)),y),fill=C[18 if night or style=='a' else 19])
    # Contiguous land with a stepped shoreline and a gentle right-hand hill.
    for x in range(113,480):
        h=height(x);sand=x<155
        d.line((x,h,x,159),fill=C[(11 if night else 12) if sand else 8 if style=='a' else 9])
        d.point((x,h),fill=C[12 if sand else 14 if night else 15])
        d.line((x,h+1,x,h+3),fill=C[10 if sand else 13 if night else 14])
        if style=='c':
            d.point((x,h+4),fill=C[8])
            for y in range(h+6,160):
                if rng.randrange(24)==0:d.point((x,y),fill=C[8 if y>143 else 10])
        elif style=='b':
            for y in range(h+5,160):
                if rng.randrange(80)==0:d.point((x,y),fill=C[10])
        elif x%11<3:d.point((x,h+6),fill=C[9])
    d.line((112,127,123,127),fill=C[19]);d.line((113,128,127,128),fill=C[18])
    # Atmospheric mist sits in the background rather than hiding the people.
    if style=='a':
        for y in (96,100,104):
            for x in range(145,340):
                if x%4<2 and y<height(x)-3:d.point((x,y),fill=C[5 if night else 7])

    def tree(x,base,scale=1):
        nonlocal d
        h=int(37*scale);w=int(14*scale);trunk=9 if not night else 8
        d.rectangle((x-1,base-h//2,x+1,base),fill=C[trunk])
        if style=='a':
            for n in range(3):
                top=base-h+n*7;span=w*(n+2)//4
                d.polygon([(x,top),(x+span,top+h//2),(x-span,top+h//2)],fill=C[13 if n==2 else 4 if night else 13])
        elif style=='b':
            d.ellipse((x-w,base-h,x+w,base-9),fill=C[13])
            d.ellipse((x-w+1,base-h,x+w-3,base-15),fill=C[14])
            d.ellipse((x-w+3,base-h+2,x+3,base-h+10),fill=C[14 if night else 15])
        else:
            for n in range(4):
                top=base-h+n*6;span=4+n*3
                d.polygon([(x,top),(x+span,top+13),(x+span-3,top+14),(x-span,top+13)],fill=C[13])
                d.line((x,top+1,x-span+2,top+11),fill=C[14])
                d.line((x+1,top+5,x+span-3,top+11),fill=C[15 if not night else 14])
    for x in (323,339,356,373,391,413,435,456,476):tree(x,height(x),0.75 if x in (323,356,435) else 1.15)
    # A pair of primitive shelters, equal positions and dimensions in all variants.
    for x in (180,272):
        y=height(x)
        roof=14 if style=='b' else 13;wood=10 if style=='b' else 9
        d.polygon([(x-11,y),(x-1,y-20),(x+2,y-20),(x+13,y)],fill=C[roof])
        d.polygon([(x-3,y),(x+1,y-12),(x+7,y)],fill=C[8])
        d.line((x-11,y,x,y-20),fill=C[wood]);d.line((x,y-20,x+13,y),fill=C[wood])
        if style!='a':
            for z in range(4):d.line((x-8+z*3,y-3,x-1+z*2,y-14+z),fill=C[15 if style=='b' else 14])
        if style=='c':d.line((x-12,y,x+14,y),fill=C[8])
    # Discrete warm pool and seven inhabitants around the central fire.
    for y in range(114,120):
        span=24-(y-114)*3
        d.line((230-span,y,230+span,y),fill=C[9 if y>116 else 10])
    folks=[('a',197,24,27),('b',210,25,28),('c',221,26,29),('a',245,23,29),('c',258,25,27),('b',286,26,27),('a',158,25,28)]
    for body,x,skin,cloth in folks:
        q=person(body,skin=skin,cloth=cloth)
        if style=='a':
            q.putdata([C[9] if p==C[8] else C[7] if p==C[27] else p for p in q.getdata()])
        im.alpha_composite(q,(x,114-q.height))
    d=ImageDraw.Draw(im)
    d.line((225,113,235,110),fill=C[9],width=2);d.line((225,110,235,113),fill=C[10])
    d.polygon([(225,110),(226,106),(228,108),(230,100),(231,105),(234,107),(235,111),(231,113)],fill=C[20])
    d.polygon([(228,110),(230,104),(233,110),(231,112)],fill=C[21]);d.line((230,108,230,111),fill=C[22]);d.point((230,111),fill=C[31])
    for x,y in [(228,96),(233,91),(231,86)]:d.point((x,y),fill=C[22 if night else 10])
    # Foreground plants and exposed soil: third plane frames the miniature world.
    for x in (136,150,310,333,362,445,464):
        y=height(x)+rng.randrange(8,17)
        for dx,dy in [(-4,-3),(-2,-5),(0,-7),(2,-4),(4,-3)]:
            d.line((x,y,x+dx,y+dy),fill=C[13 if night or style=='a' else 14])
        if style=='b':d.point((x+2,y-4),fill=C[22])
        if style=='c':d.point((x-2,y-5),fill=C[15])
    for x in range(145,480):
        y=155+(x//19)%3
        d.line((x,y,x,159),fill=C[8])
    return im

def generate(name):
    style=name.split('_')[1];im=make(style,'noite' in name)
    if name.endswith('_4x'):im=im.resize((1920,640),Image.Resampling.NEAREST)
    im.save(OUT/(name+'.png'),optimize=False)

if __name__=='__main__':
    for style in 'abc':
        for suffix in ('','_4x','_noite'):generate('direcao_'+style+suffix)
