from rembg import remove
from PIL import Image
import os

input_path = r"C:\Users\HP\Downloads\emerge_app\assets\icons\splash_logo.png"
output_path = r"C:\Users\HP\Downloads\emerge_app\assets\icons\splash_logo_nobg.png"

if os.path.exists(input_path):
    print("Removing background...")
    try:
        with open(input_path, 'rb') as i:
            input_data = i.read()
            output_data = remove(input_data)
            with open(output_path, 'wb') as o:
                o.write(output_data)
        print("Success! Saved to:", output_path)
    except Exception as e:
        print(f"Error removing background: {e}")
else:
    print(f"Input file {input_path} does not exist.")
