# Gera o ícone do app em android/app/src/main/res/ a partir do pino de assets/img/logo.png,
# sem o nome, que ficaria ilegível nesse tamanho:
#
# - mipmap-*/ic_launcher.png: o ícone inteiro, para Android até a versão 7;
# - mipmap-*/ic_launcher_foreground.png: só o pino, para o ícone adaptativo do Android 8 em
#   diante. O fundo é a cor ic_launcher_background de values/colors.xml, o papel do app, e
#   o formato (círculo, quadrado arredondado) quem escolhe é o aparelho.
#
# Como refazer:
#
#   pip install pillow
#   python tool/icone/gerar.py

from pathlib import Path

from PIL import Image, ImageDraw

RAIZ = Path(__file__).resolve().parents[2]
RECURSOS = RAIZ / "android" / "app" / "src" / "main" / "res"

PAPEL = (246, 243, 236, 255)
TRANSPARENTE = (0, 0, 0, 0)

# Multiplicador de cada densidade sobre os 48 dp do ícone e os 108 dp do adaptativo.
DENSIDADES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}

# No adaptativo, só o círculo central de 66 dp é garantido; o resto o aparelho pode cortar.
FRACAO_ADAPTATIVO = 62 / 108
FRACAO_INTEIRO = 0.78
ARREDONDAMENTO = 0.2


def pino():
    logo = Image.open(RAIZ / "assets" / "img" / "logo.png").convert("RGBA")
    # O nome começa depois da primeira linha sem nada visível abaixo do pino. A sombra da
    # logo deixa pixels quase transparentes entre os dois, que não contam como visíveis.
    alfa = logo.getchannel("A").point(lambda a: 255 if a > 16 else 0)
    corte = next(y for y in range(1, logo.height) if alfa.crop((0, y, logo.width, y + 1)).getbbox() is None)
    recorte = logo.crop((0, 0, logo.width, corte))
    return recorte.crop(alfa.crop((0, 0, logo.width, corte)).getbbox())


def centralizado(figura, lado, fracao):
    altura = round(lado * fracao)
    largura = round(figura.width * altura / figura.height)
    menor = figura.resize((largura, altura), Image.LANCZOS)
    quadro = Image.new("RGBA", (lado, lado), TRANSPARENTE)
    quadro.alpha_composite(menor, ((lado - largura) // 2, (lado - altura) // 2))
    return quadro


def inteiro(figura, lado):
    # Desenha o fundo arredondado em tamanho maior para a borda sair suave.
    fundo = Image.new("RGBA", (lado * 4, lado * 4), TRANSPARENTE)
    ImageDraw.Draw(fundo).rounded_rectangle((0, 0, lado * 4 - 1, lado * 4 - 1), radius=round(lado * 4 * ARREDONDAMENTO), fill=PAPEL)
    fundo = fundo.resize((lado, lado), Image.LANCZOS)
    fundo.alpha_composite(centralizado(figura, lado, FRACAO_INTEIRO))
    return fundo


def main():
    marca = pino()
    for nome, escala in DENSIDADES.items():
        pasta = RECURSOS / f"mipmap-{nome}"
        inteiro(marca, round(48 * escala)).save(pasta / "ic_launcher.png", optimize=True)
        centralizado(marca, round(108 * escala), FRACAO_ADAPTATIVO).save(pasta / "ic_launcher_foreground.png", optimize=True)
    print("ok: ic_launcher e ic_launcher_foreground em", len(DENSIDADES), "densidades")


if __name__ == "__main__":
    main()
