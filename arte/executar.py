"""Executa as entregas pendentes, valida e registra o protocolo local."""
from pathlib import Path
from datetime import datetime
from zoneinfo import ZoneInfo
import hashlib
import re
import subprocess
import sys
from PIL import Image
from gerador import C, HEX, generate

ROOT=Path(__file__).resolve().parent
PROJECT=ROOT.parent
TASKS=[
 ('T001','paleta',{'paleta':(64,32),'paleta_teste':(480,160)}),
 ('T002','terreno',{'terreno':(64,8),'agua_superficie_4q':(32,8),'terreno_teste':(480,160)}),
 ('T003','habitantes',{'adulto_a_parado_2q':(16,12),'adulto_a_andar_4q':(32,12),'adulto_b_parado_2q':(16,12),'adulto_b_andar_4q':(32,12),'crianca_andar_4q':(24,8),'habitantes_variacoes':(96,32)}),
 ('T004','estagio1',{'cabana_galhos':(16,16),'fogueira_apagada':(8,8),'fogueira_4q':(32,8),'arvore_a':(16,24),'arvore_b':(16,24),'arbusto':(8,8)}),
 ('T005','cenas',{'cena_dia':(480,160),'cena_noite':(480,160),'cena_dia_3x':(1440,480),'cena_noite_3x':(1440,480)}),
]

def timestamp():
    # Explicit Sao Paulo offset avoids depending on Windows tzdata installation.
    from datetime import timezone,timedelta
    return datetime.now(timezone(timedelta(hours=-3))).strftime('%Y-%m-%d %H:%M')

def append_status(text):
    with (PROJECT/'codex/status.md').open('a',encoding='utf-8') as f:f.write('\n'+text+'\n')

def check_control():
    if re.search(r'Desligar_Codex\s*=\s*True',(PROJECT/'codex/controle.md').read_text(encoding='utf-8')):
        append_status('## '+timestamp()+'\nCodex desligado')
        sys.exit(0)

def change_state(task,state):
    p=PROJECT/'codex/tarefas.md';s=p.read_text(encoding='utf-8')
    pattern=r'(## '+task+r'\b.*?\*\*Estado:\*\* )\w+'
    s,n=re.subn(pattern,lambda m:m[1]+state,s,count=1,flags=re.S)
    assert n==1
    p.write_text(s,encoding='utf-8')

def validate(p,size):
    im=Image.open(p).convert('RGBA');assert im.size==size,(p,im.size,size)
    pixels=set(im.getdata());assert all(a in (0,255) for r,g,b,a in pixels),p
    assert {v for v in pixels if v[3]}<=set(C),p
    first=hashlib.sha256(p.read_bytes()).digest()
    subprocess.run([sys.executable,str(p.with_suffix('.py'))],check=True)
    assert first==hashlib.sha256(p.read_bytes()).digest(),p

def run():
    assert len(HEX)==len(set(HEX))==32
    for task,folder,outputs in TASKS:
        check_control()
        s=(PROJECT/'codex/tarefas.md').read_text(encoding='utf-8')
        state=re.search(r'## '+task+r'\b.*?\*\*Estado:\*\* (\w+)',s,re.S)[1]
        if state not in ('PENDENTE','REFAZER','EM_ANDAMENTO'):continue
        change_state(task,'EM_ANDAMENTO')
        files=[]
        for name,size in outputs.items():
            check_control()
            p=ROOT/folder/(name+'.py');p.parent.mkdir(parents=True,exist_ok=True)
            p.write_text('"""Recria '+name+'.png; requer Pillow e ../gerador.py."""\nfrom pathlib import Path\nimport sys\nsys.path.insert(0, str(Path(__file__).resolve().parents[1]))\nfrom gerador import generate\n\nif __name__ == "__main__":\n    generate('+repr(name)+')\n',encoding='utf-8')
            generate(name);validate(p.with_suffix('.png'),size)
            files.extend(['arte/'+folder+'/'+name+'.png','arte/'+folder+'/'+name+'.py'])
        if task=='T001':files.extend(['arte/paleta/paleta.hex','arte/paleta/paleta.gpl'])
        note='Scripts homônimos dependem de arte/gerador.py e Pillow. Geração repetida com SHA-256 idêntico; dimensões, paleta e alpha binário verificados.'
        if task=='T001':note+=' Paleta proposta aguarda revisão do Claude; grupos na ordem do guia, quatro peles e três tecidos distintos.'
        else:note+=' Paleta T001 usada provisoriamente para cumprir a sequência autorizada pelo usuário, antes da aprovação formal.'
        if task=='T003':note+=' Variações: duas linhas (A/B), quatro grupos de pele com três tecidos cada; roupa inteiramente restrita aos tecidos. Cabeça fixa nos ciclos de andar.'
        if task=='T005':note+=' Sete pessoas: cinco adultos e duas crianças; luz noturna por substituição de cores da paleta e área quente junto à fogueira. Cenas 3x por vizinho mais próximo.'
        append_status('## '+task+' — ENTREGUE — '+timestamp()+'\nArquivos:\n'+'\n'.join('- '+f for f in files)+'\n- arte/gerador.py (gerador compartilhado)\nCritérios de aceite: verificações técnicas atendidas; leitura visual sujeita à revisão do Claude.\nObservações: '+note)
        change_state(task,'ENTREGUE')
        print(task+' ENTREGUE',flush=True)
    check_control()

if __name__=='__main__':run()
