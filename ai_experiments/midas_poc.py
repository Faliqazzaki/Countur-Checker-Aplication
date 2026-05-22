import cv2
import torch
import matplotlib.pyplot as plt
from transformers import DPTImageProcessor, DPTForDepthEstimation
import numpy as np

# 1. Load Model MiDaS (Menggunakan versi hybrid yang cukup ringan dan akurat)
print("Loading model...")
processor = DPTImageProcessor.from_pretrained("Intel/dpt-hybrid-midas")
model = DPTForDepthEstimation.from_pretrained("Intel/dpt-hybrid-midas")

# 2. Load Gambar Input
image_path = "input/Pemandangan_3.jpg" # Pastikan file ini ada
img = cv2.imread(image_path)
if img is None:
    print("Gambar tidak ditemukan! Pastikan path gambar sudah benar.")
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

    # 6. Memproses Ekstraksi Kontur Berwarna (Sesuai Referensi Diagram)
    print("Memproses efek garis kontur berwarna...")

    # --- TAHAP 1: Smoothing ---
    # Menghaluskan depth map agar garis kontur nantinya melengkung rapi (tidak bergerigi)
    smoothed_depth = cv2.GaussianBlur(depth_map_normalized, (21, 21), 0)

    # --- TAHAP 2: Menyiapkan Palet Warna (Colormap) ---
    # Membuat palet array dari 0-255 dan mengubahnya menjadi warna JET (Merah ke Biru)
    palette = np.arange(0, 256, dtype=np.uint8).reshape(1, 256, 1)
    colormap_jet = cv2.applyColorMap(palette, cv2.COLORMAP_JET)
    colormap_rgb = cv2.cvtColor(colormap_jet, cv2.COLOR_BGR2RGB).squeeze()

    # --- TAHAP 3: Ekstraksi dan Pewarnaan Garis Kontur ---
    # Menggunakan gambar asli secara utuh sebagai kanvas
    final_output = img_rgb.copy()

    # Membuat garis kontur berlapis
    num_levels = 15  # Jumlah tingkatan/kerapatan garis kontur
    step = 255 // num_levels

    for i in range(step, 255, step):
        # 1. Buat batas threshold untuk setiap level kedalaman
        _, thresh = cv2.threshold(smoothed_depth, i, 255, cv2.THRESH_BINARY)
        
        # 2. Cari garis tepi (kontur)
        contours, _ = cv2.findContours(thresh, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
        
        # 3. Ambil warna spesifik untuk level 'i' dari palet JET
        color = tuple(int(c) for c in colormap_rgb[i])
        
        # 4. Gambar garis kontur dengan warna tersebut (Ketebalan diset 2 agar jelas)
        cv2.drawContours(final_output, contours, -1, color, 2)

    # --- TAHAP 4: Tampilkan Hasil Akhir ---
    plt.figure(figsize=(15, 5))

    plt.subplot(1, 3, 1)
    plt.title("1. Gambar Asli")
    plt.imshow(img_rgb)
    plt.axis('off')

    plt.subplot(1, 3, 2)
    plt.title("2. Depth Map (Smoothed)")
    plt.imshow(smoothed_depth, cmap='gray')
    plt.axis('off')

    plt.subplot(1, 3, 3)
    plt.title("3. Output Akhir (Garis Berwarna)")
    plt.imshow(final_output)
    plt.axis('off')

    plt.tight_layout()
    plt.show()
    
    # Simpan hasil akhir menjadi file gambar baru di folder output
    output_bgr = cv2.cvtColor(final_output, cv2.COLOR_RGB2BGR)
    cv2.imwrite("output/output_kontur_garis.jpg", output_bgr)
    print("Gambar hasil kontur berhasil disimpan sebagai output/output_kontur_garis.jpg!")