import cv2
import torch
import matplotlib.pyplot as plt
from transformers import DPTImageProcessor, DPTForDepthEstimation
import numpy as np

# 1. Load Model MiDaS (Menggunakan versi hybrid yang cukup ringan dan akurat)
print("Loading model...")
processor = DPTImageProcessor.from_pretrained("Intel/dpt-hybrid-midas")
model = DPTForDepthEstimation.from_pretrained("Intel/dpt-hybrid-midas")

# 2. Load Gambar Input (Pastikan kamu punya gambar pemandangan/tanah di folder yang sama)
image_path = "input/Pemandangan_1.jpg" # Ganti dengan nama file fotomu
img = cv2.imread(image_path)
if img is None:
    print("Gambar tidak ditemukan!")
else:
    # Convert BGR (OpenCV default) ke RGB
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

    # 3. Pre-processing gambar untuk model
    print("Memproses gambar...")
    inputs = processor(images=img_rgb, return_tensors="pt")

    # 4. Prediksi Depth Map
    with torch.no_grad():
        outputs = model(**inputs)
        predicted_depth = outputs.predicted_depth

    # 5. Interpolasi (Resize) depth map agar ukurannya sama dengan gambar asli
    prediction = torch.nn.functional.interpolate(
        predicted_depth.unsqueeze(1),
        size=img_rgb.shape[:2],
        mode="bicubic",
        align_corners=False,
    )
    
    # Ubah tensor PyTorch menjadi array NumPy
    depth_map = prediction.squeeze().cpu().numpy()

    # Normalisasi array ke rentang 0-255 agar bisa divisualisasikan sebagai gambar
    depth_map_normalized = cv2.normalize(depth_map, None, 0, 255, norm_type=cv2.NORM_MINMAX, dtype=cv2.CV_8U)

    # 6. Tampilkan Hasil
    plt.figure(figsize=(10, 5))
    
    plt.subplot(1, 2, 1)
    plt.title("Gambar Asli")
    plt.imshow(img_rgb)
    plt.axis('off')

    plt.subplot(1, 2, 2)
    plt.title("Depth Map (MiDaS)")
    plt.imshow(depth_map_normalized, cmap='gray') # Grayscale: Terang = dekat, Gelap = jauh
    plt.axis('off')

    plt.tight_layout()
    plt.show()