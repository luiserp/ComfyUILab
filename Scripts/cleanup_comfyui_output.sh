#!/bin/bash
# Script para eliminar archivos en la carpeta Output
find /app/ComfyUI/output -type f -delete
echo "Archivos eliminados en $(date)" >> /app/ComfyUI/output/cleanup.log
