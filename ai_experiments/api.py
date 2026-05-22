import cv2
import torch
import numpy as np
from fastapi import FastAPI, File, UploadFile
from fastapi.responses import Response
from transformers import DPTImageProcessor, DPTForDepthEstimation

# Inisialisasi Aplikasi FastAPI
app = FastAPI(title="Contour Checker API")

# Load model di awal agar tidak perlu loading berulang kali saat ada request
print("Loading model MiDaS...")
processor = DPTImageProcessor.from_pretrained("Intel/dpt-hybrid-midas")
model = DPTForDepthEstimation.from_pretrained("Intel/dpt-hybrid-midas")
print("Model berhasil dimuat dan siap menerima gambar!")

@app.post("/process-image/")
async def process_image(file: UploadFile = File(...)):
    # 1. Membaca gambar yang dikirim dari Flutter
    contents = await file.read()
    nparr = np.frombuffer(contents, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    
    if img is None:
        return {"error": "Gambar tidak valid"}

    # 2. Proses AI (MiDaS)
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    inputs = processor(images=img_rgb, return_tensors="pt")
    
    with torch.no_grad():
        outputs = model(**inputs)
        predicted_depth = outputs.predicted_depth
        
    prediction = torch.nn.functional.interpolate(
        predicted_depth.unsqueeze(1),
        size=img_rgb.shape[:2],
        mode="bicubic",
        align_corners=False,
    )
    
    depth_map = prediction.squeeze().cpu().numpy()
    depth_map_normalized = cv2.normalize(depth_map, None, 0, 255, norm_type=cv2.NORM_MINMAX, dtype=cv2.CV_8U)
    
    # 3. Smoothing & Ekstraksi Garis Kontur Berwarna (Sama persis dengan kodemu)
    smoothed_depth = cv2.GaussianBlur(depth_map_normalized, (21, 21), 0)
    
    palette = np.arange(0, 256, dtype=np.uint8).reshape(1, 256, 1)
    colormap_jet = cv2.applyColorMap(palette, cv2.COLORMAP_JET)
    colormap_rgb = cv2.cvtColor(colormap_jet, cv2.COLOR_BGR2RGB).squeeze()
    
    final_output = img_rgb.copy()
    num_levels = 15
    step = 255 // num_levels
    
    for i in range(step, 255, step):
        _, thresh = cv2.threshold(smoothed_depth, i, 255, cv2.THRESH_BINARY)
        contours, _ = cv2.findContours(thresh, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
        color = tuple(int(c) for c in colormap_rgb[i])
        cv2.drawContours(final_output, contours, -1, color, 2)
        
    # 4. Ubah gambar hasil akhir menjadi format Bytes untuk dikirim balik ke Flutter
    final_bgr = cv2.cvtColor(final_output, cv2.COLOR_RGB2BGR)
    _, encoded_img = cv2.imencode('.jpg', final_bgr)
    
    # Mengembalikan gambar langsung sebagai response HTTP
    return Response(content=encoded_img.tobytes(), media_type="image/jpeg")