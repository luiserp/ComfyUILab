# FROM ubuntu:22.04
FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

# Evita la instalación de paquetes recomendados y sugeridos
RUN echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/00-docker
RUN echo 'APT::Install-Recommends "0";' >> /etc/apt/apt.conf.d/00-docker

RUN apt-get update

# Actualiza el sistema y instala dependencias
RUN apt-get install -y \
    python3.11 python3.11-venv python3-pip \
    gcc g++ git ca-certificates \
    libgl1-mesa-glx libglib2.0-0 ffmpeg wget curl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Establecer el directorio de trabajo
WORKDIR /app

# Clonar el repositorio de ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git && \
    cd ComfyUI && git checkout master

# Crear un entorno virtual de Python
RUN python3.11 -m venv /app/ComfyUI/venv

# Instalar PyTorch sin CUDA
# RUN /app/ComfyUI/venv/bin/pip install --pre torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/nightly/cpu

# Instalar PyTorch con CUDA
RUN /app/ComfyUI/venv/bin/pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu124

# Crear un entorno virtual de Python e instalar dependencias
RUN /app/ComfyUI/venv/bin/pip install --upgrade pip && \
    /app/ComfyUI/venv/bin/pip install -r /app/ComfyUI/requirements.txt

# Instalar ComfyUI-Manager
RUN cd /app/ComfyUI/custom_nodes && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager comfyui-manager

# Descargar el modelo v1.5 solo si no existe
# RUN mkdir -p /app/ComfyUI/models/checkpoints && \
#     cd /app/ComfyUI/models/checkpoints && \
#     if [ ! -f "v1-5-pruned-emaonly.safetensors" ]; then \
#         wget https://huggingface.co/stable-diffusion-v1-5/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors; \
#     fi

# Volver a la raíz del proyecto
WORKDIR /app

# Exponer el puerto por defecto de ComfyUI
EXPOSE 8188

# Limpiar outputs cada 12 horas
# Instalar cron
RUN apt-get update && apt-get install -y cron

# Copiar el script al contenedor
COPY ./Scripts/cleanup_comfyui_output.sh /usr/local/bin/cleanup_comfyui_output.sh
RUN chmod +x /usr/local/bin/cleanup_comfyui_output.sh

# Configurar cron
RUN (echo "0 */12 * * * /usr/local/bin/cleanup_comfyui_output.sh") | crontab -

# Comando para ejecutar ComfyUI
CMD service cron start && /app/ComfyUI/venv/bin/python /app/ComfyUI/main.py --listen 0.0.0.0
