import os
from PIL import Image

def inspect(path):
    if os.path.exists(path):
        img = Image.open(path)
        print(f"--- {os.path.basename(path)} ---")
        print(f"Size: {img.size}")
        print(f"Mode: {img.mode}")
        pixels = img.load()
        print(f"Top-left pixel: {pixels[0, 0]}")
    else:
        print(f"{path} does not exist")

inspect(r"C:\Users\HP\Downloads\emerge_app\assets\icons\splash_logo.png")
inspect(r"C:\Users\HP\Downloads\emerge_app\assets\icons\app_icon.png")
inspect(r"C:\Users\HP\Downloads\emerge_app\assets\icons\splash_logo_nobg.png")
