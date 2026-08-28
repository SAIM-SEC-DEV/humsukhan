from pathlib import Path
from PIL import Image

root = Path('/home/ubuntu/projects/humsukhan')
source = root / 'assets/platform/HUMSUKHAN_Android_512.png'
image = Image.open(source).convert('RGBA')
for density, size in {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}.items():
    target = root / 'android/app/src/main/res' / f'mipmap-{density}' / 'ic_launcher.png'
    target.parent.mkdir(parents=True, exist_ok=True)
    image.resize((size, size), Image.Resampling.LANCZOS).save(target, 'PNG')
print('launcher icons generated from supplied Android logo')
