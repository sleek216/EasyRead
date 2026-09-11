import os
from PIL import Image

input_path = r"C:\Users\hm862\.gemini\antigravity-ide\brain\d8094561-1fb7-491b-b55d-c2dd29682ac1\.user_uploaded\media_1789109149610.png"
output_dir = r"h:\AibitSoft\book-reading\app\assets\icon"
output_path = os.path.join(output_dir, "app_icon.png")

if not os.path.exists(output_dir):
    os.makedirs(output_dir)

try:
    img = Image.open(input_path)
    img = img.resize((1024, 1024), Image.Resampling.LANCZOS)
    img.save(output_path)
    print("Resized successfully to", output_path)
except Exception as e:
    print("Error:", e)
