"""Entrega e verifica uma tarefa da direção C, preservando a fila externa."""
from pathlib import Path
import sys
from executar import check_control,change_state,append_status,timestamp,validate
from visual_c import generate
ROOT=Path(__file__).resolve().parent
TASKS={
'T006':('alvo',{f'alvo_{time}{suffix}':((1920,640) if suffix else (480,160)) for time in ('entardecer','dia','noite') for suffix in ('','_4x')}),
'T007':('terreno_c',{'terreno':(104,8),'agua_superficie_4q':(32,8),'terreno_teste':(480,160),'terreno_c_teste':(480,160),'pedra_aflorada':(8,8)}),
'T008':('habitantes_c',{'adulto_a_parado_2q':(16,12),'adulto_a_andar_4q':(32,12),'adulto_b_parado_2q':(16,12),'adulto_b_andar_4q':(32,12),'crianca_andar_4q':(24,8),'habitantes_variacoes':(96,32),'idoso_andar_4q':(32,12),'adulto_a_rezar_2q':(16,12),'adulto_a_colher_4q':(32,12)}),
'T009':('estagio1_c',{'cabana_galhos':(16,16),'fogueira_apagada':(8,8),'fogueira_4q':(32,8),'arvore_a':(16,24),'arvore_b':(16,24),'arbusto':(8,8),'pinheiro_a':(16,32),'pinheiro_b':(16,32),'capim':(8,8),'pedra_grande':(16,16)}),
'T010':('cenas_c',{f'montada_{time}{suffix}':((1920,640) if suffix else (480,160)) for time in ('dia','noite') for suffix in ('','_4x')}),
}
NOTES={
'T006':'Cena-alvo e peças compartilham primitivas em arte/visual_c.py. Chão central y120 (75%); costa y128, morro y104–112; camadas de grama, terra, raízes e rocha. Sete pessoas, duas crianças. Pinheiros, copas largas, arbustos e capim têm a luz no topo. À noite, iluminação espacial aquece pele, roupas, solo e objetos junto ao fogo. As folhas PNG serão exportadas nas próximas tarefas sem mudar os desenhos.',
'T007':'Folha com 13 blocos em ordem: os oito originais, raízes, rocha, bordas A/B e pedra aflorada. Pedra também exportada individualmente. terreno_c_teste usa exatamente o perfil da cena-alvo, transparente acima do solo. terreno_teste demonstra praia, lago e morro como pedido na T002. Bordas irregulares são sobreposições transparentes, sem efeitos do motor.',
'T008':'Cabeça com cabelo e sombra, braço destacado, tecido sombreado somente com as três cores de tecidos, pernas em dois tons de pele. Cabeça ancorada no ciclo de andar. Corpo B tem ombros e túnica mais largos; idoso tem cabeça deslocada e bengala; rezar ajoelha com braços altos; colher alterna postura ereta e inclinada. Grade de variações A/B × quatro peles × três tecidos.',
'T009':'Peças correspondem às primitivas usadas na cena-alvo. Pinheiros têm segmentos e luz nas bordas; copas largas, arbustos e capim seguem luz superior. Cobertura da cabana usa vegetação, estrutura usa terra/madeira, entrada escura. As peças isoladas não incluem brilho, neblina ou reflexo.',
'T010':'Composição carrega exclusivamente PNGs das T007–T009 para o mundo, habitantes e objetos; céu, reflexão, partículas e luz são efeitos de código. Troca de paleta dos habitantes representa seleção cultural. Igualdade pixel a pixel com alvo_dia e alvo_noite verificada, incluindo 4x. Nenhum sprite foi retocado durante a montagem.',
}

def run(task):
    check_control();change_state(task,'EM_ANDAMENTO');folder,outputs=TASKS[task];files=[]
    for name,size in outputs.items():
        check_control();p=ROOT/folder/(name+'.py');p.parent.mkdir(parents=True,exist_ok=True)
        p.write_text('"""Recria o PNG homônimo. Requer Pillow e ../visual_c.py."""\nfrom pathlib import Path\nimport sys\nsys.path.insert(0,str(Path(__file__).resolve().parents[1]))\nfrom visual_c import generate\n\nif __name__ == "__main__":\n    generate('+repr(folder)+','+repr(name)+')\n',encoding='utf-8')
        generate(folder,name);validate(p.with_suffix('.png'),size)
        files.extend(['arte/'+folder+'/'+name+'.png','arte/'+folder+'/'+name+'.py'])
    if task=='T010':
        from PIL import Image,ImageChops
        for time in ('dia','noite'):
            for suffix in ('','_4x'):
                a=Image.open(ROOT/'alvo'/('alvo_'+time+suffix+'.png'))
                b=Image.open(ROOT/'cenas_c'/('montada_'+time+suffix+'.png'))
                assert a.tobytes()==b.tobytes(),'Cena difere do alvo: '+time+suffix
    append_status('## '+task+' — ENTREGUE — '+timestamp()+'\nArquivos:\n'+'\n'.join('- '+p for p in files)+'\n- arte/visual_c.py (fonte compartilhada da direção C)\nCritérios de aceite: dimensões, paleta T001 aprovada, alpha binário e reprodução exata por SHA-256 verificados. Avaliação estética final pelo orquestrador.\nObservações: '+NOTES[task]+' Scripts homônimos dependem de arte/visual_c.py, arte/gerador.py e Pillow.')
    change_state(task,'ENTREGUE');check_control();print(task+' ENTREGUE',flush=True)

if __name__=='__main__':run(sys.argv[1])
